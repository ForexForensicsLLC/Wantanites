//+------------------------------------------------------------------+
//|                                                    FractalSuperTrendPullback.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

#include <Wantanites\Framework\Trackers\HeikinAshiTracker.mqh>
#include <Wantanites\Framework\Objects\PriceGridTracker.mqh>
#include <Wantanites\Framework\Trackers\FractalTracker.mqh>
#include <Wantanites\Framework\Objects\SuperTrend.mqh>

class FractalSuperTrendPullback : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    HeikinAshiTracker *mHAT;
    PriceGridTracker *mPGT;
    FractalTracker *mFT;
    SuperTrend *mST;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mMinWickLength;

    double mStartingEquity;
    bool mPlacedFirstTicket;

    datetime mLastFractalTime;
    bool mBrokeFractal;
    int mLastPriceLevel;

    double mLotSize;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

    double mMinEquityDrawDown;

public:
    FractalSuperTrendPullback(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter,
                              HeikinAshiTracker *&hat, PriceGridTracker *&pgt, FractalTracker *&ft, SuperTrend *&st);
    ~FractalSuperTrendPullback();

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

FractalSuperTrendPullback::FractalSuperTrendPullback(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter,
                                                     HeikinAshiTracker *&hat, PriceGridTracker *&pgt, FractalTracker *&ft, SuperTrend *&st)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mHAT = hat;
    mPGT = pgt;
    mFT = ft;
    mST = st;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mMinWickLength = 0;

    mStartingEquity = 0;
    mPlacedFirstTicket = false;

    mLastFractalTime = 0;
    mBrokeFractal = false;
    mLastPriceLevel = 1000;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    mMinEquityDrawDown = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<FractalSuperTrendPullback>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<FractalSuperTrendPullback, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<FractalSuperTrendPullback, SingleTimeFrameEntryTradeRecord>(this);
}

FractalSuperTrendPullback::~FractalSuperTrendPullback()
{
    Print("Magic Number: ", MagicNumber(), ", Min Equity DD: ", mMinEquityDrawDown);
}

void FractalSuperTrendPullback::Run()
{
    mST.Draw();

    EAHelper::Run<FractalSuperTrendPullback>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool FractalSuperTrendPullback::AllowedToTrade()
{
    return EAHelper::BelowSpread<FractalSuperTrendPullback>(this) && (EAHelper::WithinTradingSession<FractalSuperTrendPullback>(this) || mPreviousSetupTickets.Size() > 0);
}

void FractalSuperTrendPullback::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    int lastFractalIndex = EMPTY;
    int furthestBetweenFractal = EMPTY;

    if (mSetupType == OP_BUY)
    {
        if (!mBrokeFractal)
        {
            if (mST.Direction() != OP_SELL)
            {
                return;
            }

            Fractal *tempFractal;
            if (!mFT.LowestDownFractalOutOfPrevious(3, tempFractal))
            {
                return;
            }

            int fractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, tempFractal.CandleTime());
            if (fractalIndex <= 0)
            {
                return;
            }

            if (tempFractal.CandleTime() > mLastFractalTime &&
                iLow(mEntrySymbol, mEntryTimeFrame, 2) > iLow(mEntrySymbol, mEntryTimeFrame, fractalIndex) &&
                iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, fractalIndex))
            {
                // mHasSetup = true;
                mLastFractalTime = tempFractal.CandleTime();
                // mPGT.SetStartingPrice(iLow(mEntrySymbol, mEntryTimeFrame, fractalIndex));
                mBrokeFractal = true;
            }
        }

        if (mBrokeFractal)
        {
            lastFractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLastFractalTime);
            if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, lastFractalIndex, 0, true, furthestBetweenFractal))
            {
                return;
            }

            if (furthestBetweenFractal > 3)
            {
                // InvalidateSetup(false);
                return;
            }

            if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) - iLow(mEntrySymbol, mEntryTimeFrame, 1) >= OrderHelper::PipsToRange(mMinWickLength))
            {
                mHasSetup = true;
                mPGT.SetStartingPrice(iOpen(mEntrySymbol, mEntryTimeFrame, 0));
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mBrokeFractal)
        {
            if (mST.Direction() != OP_BUY)
            {
                return;
            }

            Fractal *tempFractal;
            if (!mFT.HighestUpFractalOutOfPrevious(3, tempFractal))
            {
                return;
            }

            int fractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, tempFractal.CandleTime());
            if (fractalIndex <= 0)
            {
                return;
            }

            if (tempFractal.CandleTime() > mLastFractalTime &&
                iHigh(mEntrySymbol, mEntryTimeFrame, 2) < iHigh(mEntrySymbol, mEntryTimeFrame, fractalIndex) &&
                iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, fractalIndex))
            {
                // mHasSetup = true;
                mLastFractalTime = tempFractal.CandleTime();
                // mPGT.SetStartingPrice(iHigh(mEntrySymbol, mEntryTimeFrame, fractalIndex));
                mBrokeFractal = true;
            }
        }

        if (mBrokeFractal)
        {
            lastFractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLastFractalTime);
            if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, lastFractalIndex, 0, true, furthestBetweenFractal))
            {
                return;
            }

            if (furthestBetweenFractal > 3)
            {
                // InvalidateSetup(false);
                return;
            }

            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) - CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) >= OrderHelper::PipsToRange(mMinWickLength))
            {
                mHasSetup = true;
                mPGT.SetStartingPrice(iOpen(mEntrySymbol, mEntryTimeFrame, 0));
            }
        }
    }
}

void FractalSuperTrendPullback::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mPreviousSetupTickets.Size() == 0)
    {
        if (mBrokeFractal)
        {
            // invalidate if SuperTrend changes direction
            if (mSetupType == OP_BUY && mST.Direction() == OP_BUY)
            {
                InvalidateSetup(false);
                return;
            }
            else if (mSetupType == OP_SELL && mST.Direction() == OP_SELL)
            {
                InvalidateSetup(false);
                return;
            }

            // Invalidate if we put in a new further fractal
            if (mFT[0].CandleTime() != mLastFractalTime)
            {
                int currentFractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFT[0].CandleTime());
                int lastFractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFT[0].CandleTime());

                if (mSetupType == OP_BUY)
                {
                    if (iLow(mEntrySymbol, mEntryTimeFrame, currentFractalIndex) < iLow(mEntrySymbol, mEntryTimeFrame, lastFractalIndex))
                    {
                        InvalidateSetup(false);
                        return;
                    }
                }
                else if (mSetupType == OP_SELL)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, currentFractalIndex) > iHigh(mEntrySymbol, mEntryTimeFrame, lastFractalIndex))
                    {
                        InvalidateSetup(false);
                        return;
                    }
                }
            }
        }

        if (mPlacedFirstTicket)
        {
            InvalidateSetup(false);
            return;
        }
    }

    // we placed at least one ticket and now all tickets are closed
    // if (mPlacedFirstTicket && mPreviousSetupTickets.Size() == 0)
    // {
    //     // reset these here since we call InvalidateSetup after placing an order
    //     mBrokeFractal = false;
    //     mStartingEquity = 0;
    //     mPlacedFirstTicket = false;
    //     mLastPriceLevel = 1000;
    //     mPGT.Reset();

    //     InvalidateSetup(false);
    // }
}

void FractalSuperTrendPullback::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<FractalSuperTrendPullback>(this, deletePendingOrder, mStopTrading, error);

    mBrokeFractal = false;
    mStartingEquity = 0;
    mPlacedFirstTicket = false;
    mLastPriceLevel = 1000;
    mPGT.Reset();
}

bool FractalSuperTrendPullback::Confirmation()
{
    // if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    // {
    //     return false;
    // }

    if (mSetupType == OP_BUY)
    {
        if (mPGT.CurrentLevel() <= 0 &&
            mPGT.CurrentLevel() < mLastPriceLevel)
        {
            mLastPriceLevel = mPGT.CurrentLevel();
            return true;
        }
        // return mHAT[0].Type() == OP_BUY &&
        //        mHAT[1].Type() == OP_SELL &&
        //        mHAT[2].Type() == OP_SELL;
    }
    else if (mSetupType == OP_SELL)
    {
        if (mPGT.CurrentLevel() >= 0 &&
            (mPGT.CurrentLevel() > mLastPriceLevel || mLastPriceLevel == 1000))
        {
            mLastPriceLevel = mPGT.CurrentLevel();
            return true;
        }

        // return mHAT[0].Type() == OP_SELL &&
        //        mHAT[1].Type() == OP_BUY &&
        //        mHAT[2].Type() == OP_BUY;
    }

    return false;
}

void FractalSuperTrendPullback::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;

        // only enter in orders that were a result of a deeper retracement. Don't want to be entering in a ton of orders if we are just bouncing around
        // if (mPreviousSetupTickets.Size() > 0 && entry > mPreviousSetupTickets[mPreviousSetupTickets.Size() - 1].OpenPrice())
        // {
        //     return;
        // }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;

        // // only enter in orders that were a result of a deeper retracement. Don't want to be entering in a ton of orders if we are just bouncing around
        // if (mPreviousSetupTickets.Size() > 0 && entry < mPreviousSetupTickets[mPreviousSetupTickets.Size() - 1].OpenPrice())
        // {
        //     return;
        // }
    }

    // first ticket is being placed, track the starting equity so we know when to close
    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountEquity();
        mPlacedFirstTicket = true;
    }

    double lotSize = mLotSize;
    int currentTickets = mPreviousSetupTickets.Size();
    while (currentTickets >= 5)
    {
        lotSize *= 1.5;
        currentTickets -= 5;
    }

    EAHelper::PlaceMarketOrder<FractalSuperTrendPullback>(this, entry, stopLoss, lotSize);
    // InvalidateSetup(false);
}

void FractalSuperTrendPullback::ManageCurrentPendingSetupTicket()
{
}

void FractalSuperTrendPullback::ManageCurrentActiveSetupTicket()
{
}

bool FractalSuperTrendPullback::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void FractalSuperTrendPullback::ManagePreviousSetupTicket(int ticketIndex)
{
    // close all tickets if we are down 10% or up 1%
    double equityPercentChange = (AccountEquity() - mStartingEquity) / AccountEquity() * 100;
    // double equityTarget = MathMax(0.2 / mPreviousSetupTickets.Size(), 0.05);
    // double equityTarget = 1 / mPreviousSetupTickets.Size();
    double equityTarget = 0.1;

    if (equityPercentChange <= -10 || equityPercentChange > equityTarget)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        return;
    }

    if (equityPercentChange < mMinEquityDrawDown)
    {
        mMinEquityDrawDown = equityPercentChange;
    }
}

void FractalSuperTrendPullback::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FractalSuperTrendPullback>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<FractalSuperTrendPullback>(this);
}

void FractalSuperTrendPullback::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FractalSuperTrendPullback>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<FractalSuperTrendPullback>(this, ticketIndex);
}

void FractalSuperTrendPullback::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<FractalSuperTrendPullback>(this);
}

void FractalSuperTrendPullback::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<FractalSuperTrendPullback>(this, partialedTicket, newTicketNumber);
}

void FractalSuperTrendPullback::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<FractalSuperTrendPullback>(this, ticket, Period());
}

void FractalSuperTrendPullback::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<FractalSuperTrendPullback>(this, error, additionalInformation);
}

void FractalSuperTrendPullback::Reset()
{
}