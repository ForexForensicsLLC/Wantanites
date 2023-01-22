//+------------------------------------------------------------------+
//|                                                    TimeGrid.mqh |
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
#include <SummitCapital\Framework\Objects\TimeGridTracker.mqh>

class TimeGrid : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeGridTracker *mTGT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mStartingEquity;
    int mLastAchievedLevel;

    double mLotSize;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    TimeGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeGridTracker *&tgt);
    ~TimeGrid();

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
    virtual bool ShouldReset();
    virtual void Reset();
};

TimeGrid::TimeGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeGridTracker *&tgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTGT = tgt;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mStartingEquity = 0;
    mLastAchievedLevel = 10000;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TimeGrid>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TimeGrid, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TimeGrid, SingleTimeFrameEntryTradeRecord>(this);
}

TimeGrid::~TimeGrid()
{
}

void TimeGrid::Run()
{
    mTGT.Draw();
    EAHelper::Run<TimeGrid>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool TimeGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<TimeGrid>(this) && EAHelper::WithinTradingSession<TimeGrid>(this);
}

void TimeGrid::CheckSetSetup()
{
    if (mStartingEquity == 0)
    {
        mStartingEquity = AccountEquity();
    }

    if (mSetupType == OP_BUY)
    {
        if (mTGT.CurrentLevel() > 0 &&
            (mTGT.CurrentLevel() > mLastAchievedLevel || mLastAchievedLevel == 10000))
        {
            mHasSetup = true;
            mLastAchievedLevel = mTGT.CurrentLevel();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (mTGT.CurrentLevel() < 0 &&
            mTGT.CurrentLevel() < mLastAchievedLevel)
        {
            mHasSetup = true;
            mLastAchievedLevel = mTGT.CurrentLevel();
        }
    }
}

void TimeGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day())
    {
        // move these here so that we dont' reset it when we invalidate after placing an order
        mLastAchievedLevel = 10000;
        mStartingEquity = 0;

        InvalidateSetup(true);
    }
}

void TimeGrid::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TimeGrid>(this, deletePendingOrder, mStopTrading, error);
}

bool TimeGrid::Confirmation()
{
    return true;
}

void TimeGrid::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = mTGT.LevelPrice(mTGT.CurrentLevel() - 1);
        takeProfit = mTGT.LevelPrice(mTGT.CurrentLevel() + 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = mTGT.LevelPrice(mTGT.CurrentLevel() + 1);
        takeProfit = mTGT.LevelPrice(mTGT.CurrentLevel() - 1);
    }

    EAHelper::PlaceMarketOrder<TimeGrid>(this, entry, stopLoss, 0.0, mSetupType, takeProfit);
    InvalidateSetup(false);
}

void TimeGrid::ManageCurrentPendingSetupTicket()
{
}

void TimeGrid::ManageCurrentActiveSetupTicket()
{
}

bool TimeGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void TimeGrid::ManagePreviousSetupTicket(int ticketIndex)
{
}

void TimeGrid::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeGrid>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TimeGrid>(this);
}

void TimeGrid::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeGrid>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TimeGrid>(this, ticketIndex);
}

void TimeGrid::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TimeGrid>(this);
}

void TimeGrid::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TimeGrid>(this, partialedTicket, newTicketNumber);
}

void TimeGrid::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TimeGrid>(this, ticket, Period());
}

void TimeGrid::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TimeGrid>(this, error, additionalInformation);
}

bool TimeGrid::ShouldReset()
{
    return !EAHelper::WithinTradingSession<TimeGrid>(this);
}

void TimeGrid::Reset()
{
}