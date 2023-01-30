//+------------------------------------------------------------------+
//|                                                    DirectionSwitchGrid.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EA\EA.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

#include <SummitCapital\Framework\Trackers\HeikinAshiTracker.mqh>
#include <SummitCapital\Framework\Objects\PriceGridTracker.mqh>
#include <SummitCapital\Framework\Trackers\FractalTracker.mqh>
#include <SummitCapital\Framework\Objects\SuperTrend.mqh>

class DirectionSwitchGrid : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    PriceGridTracker *mPGT;
    SuperTrend *mST;
    FractalTracker *mFT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mMinWickLength;

    double mStartingEquity;
    bool mPlacedFirstTicket;
    bool mCloseAllTickets;

    int mLastPriceLevel;
    List<int> *mAchievedPriceLevels;

    double mLotSize;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

    double mMinEquityDrawDown;

public:
    DirectionSwitchGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter,
                        PriceGridTracker *&pgt, SuperTrend *&st, FractalTracker *&ft);
    ~DirectionSwitchGrid();

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManageCurrentPendingSetupTicket();
    virtual void ManageCurrentActiveSetupTicket();
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(int ticketIndex);
    virtual void CheckCurrentSetupTicket();
    virtual void CheckPreviousSetupTicket(int ticketIndex);
    virtual void RecordTicketOpenData();
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

DirectionSwitchGrid::DirectionSwitchGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter,
                                         PriceGridTracker *&pgt, SuperTrend *&st, FractalTracker *&ft)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPGT = pgt;
    mST = st;
    mFT = ft;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mMinWickLength = 0;

    mStartingEquity = 0;
    mPlacedFirstTicket = false;
    mCloseAllTickets = false;

    mLastPriceLevel = 1000;
    mAchievedPriceLevels = new List<int>();

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    mMinEquityDrawDown = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<DirectionSwitchGrid>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<DirectionSwitchGrid, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<DirectionSwitchGrid, SingleTimeFrameEntryTradeRecord>(this);
}

DirectionSwitchGrid::~DirectionSwitchGrid()
{
    Print("Magic Number: ", MagicNumber(), ", Min Equity DD: ", mMinEquityDrawDown);
}

void DirectionSwitchGrid::Run()
{
    mST.Draw();

    EAHelper::Run<DirectionSwitchGrid>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool DirectionSwitchGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<DirectionSwitchGrid>(this) && EAHelper::WithinTradingSession<DirectionSwitchGrid>(this);
}

void DirectionSwitchGrid::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (mST.Direction(1) == OP_SELL && mST.Direction(0) == OP_BUY)
        {
            mHasSetup = true;
            mPGT.SetStartingPrice(iOpen(mEntrySymbol, mEntryTimeFrame, 0));
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (mST.Direction(1) == OP_BUY && mST.Direction(0) == OP_SELL)
        {
            mHasSetup = true;
            mPGT.SetStartingPrice(iOpen(mEntrySymbol, mEntryTimeFrame, 0));
        }
    }
}

void DirectionSwitchGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // only invalide if we closed all our tickets and the direction switched. We want to keep trading if all of our tickets got closed due to
    // trailing but the trend continues
    bool noTicketsAfterFirst = mPlacedFirstTicket && mPreviousSetupTickets.Size() == 0;
    if (mSetupType != mST.Direction(0) && noTicketsAfterFirst)
    {
        InvalidateSetup(false);
    }

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        mCloseAllTickets = false;
    }
}

void DirectionSwitchGrid::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<DirectionSwitchGrid>(this, deletePendingOrder, mStopTrading, error);

    mStartingEquity = 0;
    mPlacedFirstTicket = false;
    mAchievedPriceLevels.Clear();
    mLastPriceLevel = 1000;
    mCloseAllTickets = false;
}

bool DirectionSwitchGrid::Confirmation()
{
    // // enter if we hit a new level
    // // enter if we re hit a level but only if the Supert trend direction switched (for better chance to close at profit)
    // if ((!mAchievedPriceLevels.Contains(mPGT.CurrentLevel())) ||
    //     (mAchievedPriceLevels[mAchievedPriceLevels.Size() - 1] != mPGT.CurrentLevel() && mST.Direction(0) != mSetupType))
    // {
    //     Print("Conf");
    //     mAchievedPriceLevels.Add(mPGT.CurrentLevel());
    //     return true;
    // }

    if (mSetupType == OP_BUY)
    {
        if (!mAchievedPriceLevels.Contains(mPGT.CurrentLevel()))
        {
            // going in our direction, enter on every level
            if (mPGT.CurrentLevel() > 0)
            {
                mAchievedPriceLevels.Add(mPGT.CurrentLevel());
                return true;
            }
            // going aginst us, enter on every other level
            else if (mPGT.CurrentLevel() % 2 == 0)
            {
                mAchievedPriceLevels.Add(mPGT.CurrentLevel());
                return true;
            }
        }
        // super trend switched direction, want to re enter on previous levels for better chance to close in profit
        else if (mAchievedPriceLevels[mAchievedPriceLevels.Size() - 1] != mPGT.CurrentLevel() && mST.Direction(0) != mSetupType)
        {
            mAchievedPriceLevels.Add(mPGT.CurrentLevel());
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mAchievedPriceLevels.Contains(mPGT.CurrentLevel()))
        {
            // going in our direction, enter on every level
            if (mPGT.CurrentLevel() < 0)
            {
                mAchievedPriceLevels.Add(mPGT.CurrentLevel());
                return true;
            }
            // going aginst us, enter on every other level
            else if (mPGT.CurrentLevel() % 2 == 0)
            {
                mAchievedPriceLevels.Add(mPGT.CurrentLevel());
                return true;
            }
        }
        // super trend switched direction, want to re enter on previous levels for better chance to close in profit
        else if (mAchievedPriceLevels[mAchievedPriceLevels.Size() - 1] != mPGT.CurrentLevel() && mST.Direction(0) != mSetupType)
        {
            mAchievedPriceLevels.Add(mPGT.CurrentLevel());
            return true;
        }
    }

    return false;
}

void DirectionSwitchGrid::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    double lotSize = mLotSize;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;

        if (mPGT.CurrentLevel() < 0 || mST.Direction(0) == OP_SELL)
        {
            double currentLots = 0.0;
            for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
            {
                currentLots += mPreviousSetupTickets[i].Lots();
            }

            lotSize = currentLots * 2;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;

        if (mPGT.CurrentLevel() > 0 || mST.Direction(0) == OP_BUY)
        {
            double currentLots = 0.0;
            for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
            {
                currentLots += mPreviousSetupTickets[i].Lots();
            }

            lotSize = currentLots * 2;
        }
    }

    // first ticket is being placed, track the starting equity so we know when to close
    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountEquity();
        mPlacedFirstTicket = true;
    }

    EAHelper::PlaceMarketOrder<DirectionSwitchGrid>(this, entry, stopLoss, lotSize);
}

void DirectionSwitchGrid::ManageCurrentPendingSetupTicket()
{
}

void DirectionSwitchGrid::ManageCurrentActiveSetupTicket()
{
}

bool DirectionSwitchGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void DirectionSwitchGrid::ManagePreviousSetupTicket(int ticketIndex)
{
    // close all tickets if we switched direction and we have a small profit
    if (mSetupType != mST.Direction(0))
    {
        // just use AccountBalance() here since we could have closed tickets along the way
        // double profit = 0.0;
        // for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
        // {
        //     mPreviousSetupTickets[i].SelectIfOpen("Adding profit");
        //     profit += OrderProfit();
        // }

        // double finalBalance = AccountBalance() + profit;
        // double equityPercentChange = (finalBalance - AccountBalance()) / finalBalance * 100;
        // double equityTarget = 0.01;

        // if (equityPercentChange >= equityTarget)
        // {
        //     Print("Account Balance: ", AccountBalance(), ", Profit: ", profit, ", Equity Percent Chagne: ", equityPercentChange);
        //     for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
        //     {
        //         mPreviousSetupTickets[i].SelectIfOpen("Adding profit");
        //         Print("Ticket: ", mPreviousSetupTickets[i].Number(), ", Profit: ", OrderProfit());
        //     }

        //     mCloseAllTickets = true;
        // }

        // if (mCloseAllTickets)
        // {
        //     mPreviousSetupTickets[ticketIndex].Close();
        // }

        // if (equityPercentChange < mMinEquityDrawDown)
        // {
        //     mMinEquityDrawDown = equityPercentChange;
        // }

        // return;

        mPreviousSetupTickets[ticketIndex].Close();
    }

    // Add and trail SL
    if (mSetupType == OP_BUY)
    {
        Fractal *tempFractal;
        if (!mFT.FractalIsHighestOutOfPrevious(0, 3, tempFractal))
        {
            return;
        }

        if (!mFT.GetMostRecentFractal(FractalType::Down, tempFractal))
        {
            return;
        }

        int fractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, tempFractal.CandleTime());

        mPreviousSetupTickets[ticketIndex].SelectIfOpen("Trailing SL");

        if (OrderStopLoss() < iLow(mEntrySymbol, mEntryTimeFrame, fractalIndex) &&
            iLow(mEntrySymbol, mEntryTimeFrame, fractalIndex) > OrderOpenPrice())
        {
            OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), iLow(mEntrySymbol, mEntryTimeFrame, fractalIndex), OrderTakeProfit(),
                        OrderExpiration(), clrNONE);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        Fractal *tempFractal;
        if (!mFT.FractalIsLowestOutOfPrevious(0, 3, tempFractal))
        {
            return;
        }

        if (!mFT.GetMostRecentFractal(FractalType::Up, tempFractal))
        {
            return;
        }

        int fractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, tempFractal.CandleTime());

        mPreviousSetupTickets[ticketIndex].SelectIfOpen("Trailing SL");

        if ((OrderStopLoss() == 0.0 || OrderStopLoss() > iHigh(mEntrySymbol, mEntryTimeFrame, fractalIndex)) &&
            iHigh(mEntrySymbol, mEntryTimeFrame, fractalIndex) < OrderOpenPrice())
        {
            OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), iHigh(mEntrySymbol, mEntryTimeFrame, fractalIndex), OrderTakeProfit(),
                        OrderExpiration(), clrNONE);
        }
    }
}

void DirectionSwitchGrid::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<DirectionSwitchGrid>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<DirectionSwitchGrid>(this);
}

void DirectionSwitchGrid::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<DirectionSwitchGrid>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<DirectionSwitchGrid>(this, ticketIndex);
}

void DirectionSwitchGrid::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<DirectionSwitchGrid>(this);
}

void DirectionSwitchGrid::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<DirectionSwitchGrid>(this, partialedTicket, newTicketNumber);
}

void DirectionSwitchGrid::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<DirectionSwitchGrid>(this, ticket, Period());
}

void DirectionSwitchGrid::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<DirectionSwitchGrid>(this, error, additionalInformation);
}

void DirectionSwitchGrid::Reset()
{
}