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

    int mFurthestAchievedLevel;

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

    mFurthestAchievedLevel = 0;

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
    // reached a new level that we haven't been at before
    if (mTGT.CurrentLevel() <= 1 &&
        mTGT.CurrentLevel() > -6 &&
        mTGT.CurrentLevel() < mFurthestAchievedLevel)
    {
        mHasSetup = true;
        mFurthestAchievedLevel = mTGT.CurrentLevel();
    }
}

void TimeGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day() || mTGT.CurrentLevel() >= 1)
    {
        InvalidateSetup(true);
        mFurthestAchievedLevel = 0; // move this here so that we dont' reset it when we invalidate after placing an order
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

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = mTGT.LevelPrice(mTGT.CurrentLevel() + 1);
    }

    EAHelper::PlaceMarketOrder<TimeGrid>(this, entry, stopLoss, mLotSize);
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
    // no matter what close if we've hit the 6th level
    if (mTGT.CurrentLevel() == -6)
    {
        mPreviousSetupTickets[0].Close();
        return;
    }

    if (mSetupType == OP_BUY)
    {
        // close all buys that we've accumulated once we retrace into the positive levels
        if (mTGT.CurrentLevel() == 1)
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // should close the previous ticket after we've entered a new one
        if (mPreviousSetupTickets.Size() >= 2)
        {
            mPreviousSetupTickets[0].Close();
        }
    }
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

void TimeGrid::Reset()
{
}