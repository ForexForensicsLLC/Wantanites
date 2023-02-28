//+------------------------------------------------------------------+
//|                                                    DonchianChannelGrid.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataObjects\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>

#include <WantaCapital\Framework\Objects\Indicators\DonchianChannel\DonchianChannel.mqh>
#include <WantaCapital\Framework\Objects\Indicators\Grid\GridTracker.mqh>
#include <WantaCapital\Framework\Objects\DataStructures\Dictionary.mqh>

class DonchianChannelGrid : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    GridTracker *mGT;
    DonchianChannel *mDC;
    Dictionary<int, int> *mLevelsWithTickets;

    double mStartingLotSize;
    double mLotsPerBalancePeriod;
    double mLotsPerBalanceLotIncrement;
    int mIncreaseLotSizePeriod;
    double mIncreaseLotSizeFactor;
    double mMaxEquityDrawDownPercent;

    bool mFirstTrade;
    double mStartingEquity;
    int mPreviousAchievedLevel;
    int mLevelProfitTargetHit;
    bool mCloseAllTickets;

    double mFurthestEquityDrawDownPercent;
    datetime mFurthestEquityDrawDownTime;

public:
    DonchianChannelGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt, DonchianChannel *&dc);
    ~DonchianChannelGrid();

    double RSI(int index) { return iRSI(mEntrySymbol, mEntryTimeFrame, 14, PRICE_CLOSE, index); }
    double EMA(int index) { return iMA(mEntrySymbol, 1440, 200, 0, MODE_EMA, PRICE_CLOSE, index); }

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void PreRun();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void PreManageTickets();
    virtual void ManageCurrentPendingSetupTicket(Ticket &ticket);
    virtual void ManageCurrentActiveSetupTicket(Ticket &ticket);
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(Ticket &ticket);
    virtual void CheckCurrentSetupTicket(Ticket &ticket);
    virtual void CheckPreviousSetupTicket(Ticket &ticket);
    virtual void RecordTicketOpenData(Ticket &ticket);
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

DonchianChannelGrid::DonchianChannelGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt, DonchianChannel *&dc)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mGT = gt;
    mDC = dc;
    mLevelsWithTickets = new Dictionary<int, int>();

    mStartingLotSize = 0.0;
    mLotsPerBalancePeriod = 0.0;
    mLotsPerBalanceLotIncrement = 0.0;
    mIncreaseLotSizePeriod = 0;
    mIncreaseLotSizeFactor = 0.0;
    mMaxEquityDrawDownPercent = 0.0;

    mFirstTrade = true;
    mStartingEquity = 0;
    mPreviousAchievedLevel = 1000;
    mLevelProfitTargetHit = -99;
    mCloseAllTickets = false;

    mFurthestEquityDrawDownPercent = 0.0;
    mFurthestEquityDrawDownTime = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<DonchianChannelGrid>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<DonchianChannelGrid, SingleTimeFrameEntryTradeRecord>(this);
}

DonchianChannelGrid::~DonchianChannelGrid()
{
    Print("Magic Number: ", MagicNumber(), ", Furthest Equity DD Percent: ", mFurthestEquityDrawDownPercent, " at ", TimeToStr(mFurthestEquityDrawDownTime));
    delete mLevelsWithTickets;
}

void DonchianChannelGrid::PreRun()
{
    mDC.Draw();
    mGT.Draw();
}

bool DonchianChannelGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<DonchianChannelGrid>(this);
}

void DonchianChannelGrid::CheckSetSetup()
{
    int barsOnOtherSideOfMid = 40;
    if (SetupType() == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) < mDC.MiddleChannel(2) && iClose(mEntrySymbol, mEntryTimeFrame, 1) > mDC.MiddleChannel(1))
        {
            for (int i = 40; i > 1; i--)
            {
                if (MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) > mDC.MiddleChannel(i))
                {
                    return;
                }
            }

            mGT.UpdateBasePrice(CurrentTick().Bid());
            mHasSetup = true;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) > mDC.MiddleChannel(2) && iClose(mEntrySymbol, mEntryTimeFrame, 1) < mDC.MiddleChannel(1))
        {
            for (int i = 40; i > 1; i--)
            {
                if (MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) < mDC.MiddleChannel(i))
                {
                    return;
                }
            }

            mGT.UpdateBasePrice(CurrentTick().Bid());
            mHasSetup = true;
        }
    }
}

void DonchianChannelGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(true);
        return;
    }

    if (mHasSetup)
    {
        if (SetupType() == OP_BUY)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < mDC.MiddleChannel(1) && mPreviousSetupTickets.Size() == 0)
            {
                InvalidateSetup(true);
            }
        }
        else if (SetupType() == OP_SELL)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > mDC.MiddleChannel(1) && mPreviousSetupTickets.Size() == 0)
            {
                InvalidateSetup(true);
            }
        }
    }
}

void DonchianChannelGrid::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    Print("Invaliding Setup: ", MagicNumber());
    EAHelper::InvalidateSetup<DonchianChannelGrid>(this, deletePendingOrder, mStopTrading, error);

    mFirstTrade = true;
    mPreviousAchievedLevel = 1000;
    mStartingEquity = 0;
    mLevelProfitTargetHit = -99;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
    mGT.UpdateBasePrice(0.0);
}

bool DonchianChannelGrid::Confirmation()
{
    if (mGT.CurrentLevel() != mPreviousAchievedLevel && !mLevelsWithTickets.HasKey(mGT.CurrentLevel()))
    {
        mPreviousAchievedLevel = mGT.CurrentLevel();
        return true;
    }

    return false;
}

void DonchianChannelGrid::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        takeProfit = mGT.LevelPrice(mGT.CurrentLevel() + 1);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        takeProfit = mGT.LevelPrice(mGT.CurrentLevel() - 1);
    }

    if (mFirstTrade)
    {
        mStartingEquity = AccountBalance();
        mFirstTrade = false;
    }

    double lotSize = mStartingLotSize;
    if (mPreviousSetupTickets.Size() >= 10)
    {
        int increaseLotSizeTimes = MathFloor(mPreviousSetupTickets.Size() / mIncreaseLotSizePeriod);
        lotSize *= MathPow(mIncreaseLotSizeFactor, increaseLotSizeTimes);
        takeProfit = 0.0;
    }

    EAHelper::PlaceMarketOrder<DonchianChannelGrid>(this, entry, stopLoss, lotSize, SetupType(), takeProfit);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLevelsWithTickets.Add(mGT.CurrentLevel(), mCurrentSetupTickets[0].Number());
    }
}

void DonchianChannelGrid::PreManageTickets()
{
    if (mCloseAllTickets)
    {
        return;
    }

    if (mPreviousSetupTickets.Size() >= 10)
    {
        double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<DonchianChannelGrid>(this, mStartingEquity);
        if (equityPercentChange > mFurthestEquityDrawDownPercent)
        {
            mFurthestEquityDrawDownPercent = equityPercentChange;
            mFurthestEquityDrawDownTime = TimeCurrent();
        }

        if (/*equityPercentChange <= mMaxEquityDrawDownPercent ||*/ equityPercentChange >= .2)
        {
            mCloseAllTickets = true;
            return;
        }
    }
}

void DonchianChannelGrid::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void DonchianChannelGrid::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool DonchianChannelGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void DonchianChannelGrid::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
    }
}

void DonchianChannelGrid::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void DonchianChannelGrid::CheckPreviousSetupTicket(Ticket &ticket)
{
    bool isClosed = false;
    int error = ticket.IsClosed(isClosed);
    if (isClosed)
    {
        mLevelsWithTickets.RemoveByValue(ticket.Number());
    }
}

void DonchianChannelGrid::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<DonchianChannelGrid>(this, ticket);
}

void DonchianChannelGrid::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void DonchianChannelGrid::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<DonchianChannelGrid>(this, ticket, Period());
}

void DonchianChannelGrid::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<DonchianChannelGrid>(this, error, additionalInformation);
}

bool DonchianChannelGrid::ShouldReset()
{
    return false;
}

void DonchianChannelGrid::Reset()
{
}