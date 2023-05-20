//+------------------------------------------------------------------+
//|                                                    TimeGrid.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>
#include <Wantanites\Framework\Objects\Indicators\Grid\TimeGridTracker.mqh>

class TimeGrid : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    GridTracker *mGT;

    double mLotSize;
    double mStartingEquity;
    int mLastAchievedLevel;

public:
    TimeGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt);
    ~TimeGrid();

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

TimeGrid::TimeGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mGT = gt;

    mLotSize = 0;
    mStartingEquity = 0;
    mLastAchievedLevel = 10000;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TimeGrid>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TimeGrid, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TimeGrid, SingleTimeFrameEntryTradeRecord>(this);
}

TimeGrid::~TimeGrid()
{
}

void TimeGrid::PreRun()
{
    mGT.Draw();
}

bool TimeGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<TimeGrid>(this) && EAHelper::WithinTradingSession<TimeGrid>(this);
}

void TimeGrid::CheckSetSetup()
{
    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        mGT.UpdateBasePrice(CurrentTick().Bid());
        mHasSetup = true;
    }
}

void TimeGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // if (mLastAchievedLevel != 0 && mGT.CurrentLevel() == 0)
    // {
    //     InvalidateSetup(true);
    // }
}

void TimeGrid::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<TimeGrid>(this, deletePendingOrder, mStopTrading, error);

    mLastAchievedLevel = 10000;
    mStartingEquity = 0;
}

bool TimeGrid::Confirmation()
{
    if (SetupType() == OP_BUY)
    {
        if (mGT.CurrentLevel() > 0 &&
            (mGT.CurrentLevel() > mLastAchievedLevel || mLastAchievedLevel == 10000))
        {
            mLastAchievedLevel = mGT.CurrentLevel();
            return true;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (mGT.CurrentLevel() < 0 &&
            mGT.CurrentLevel() < mLastAchievedLevel)
        {
            mLastAchievedLevel = mGT.CurrentLevel();
            return true;
        }
    }

    return false;
}

void TimeGrid::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = mGT.LevelPrice(mGT.CurrentLevel() - 1);
        takeProfit = mGT.LevelPrice(mGT.CurrentLevel() + 1);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = mGT.LevelPrice(mGT.CurrentLevel() + 1);
        takeProfit = mGT.LevelPrice(mGT.CurrentLevel() - 1);
    }

    if (mStartingEquity == 0)
    {
        mStartingEquity = AccountEquity();
    }

    EAHelper::PlaceMarketOrder<TimeGrid>(this, entry, stopLoss, 0.0, SetupType(), takeProfit);
}

void TimeGrid::PreManageTickets()
{
}

void TimeGrid::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void TimeGrid::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool TimeGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void TimeGrid::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void TimeGrid::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void TimeGrid::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void TimeGrid::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TimeGrid>(this, ticket);
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
    mStopTrading = false;
    InvalidateSetup(true);
}