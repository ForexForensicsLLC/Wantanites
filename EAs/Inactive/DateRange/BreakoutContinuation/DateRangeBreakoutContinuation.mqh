//+------------------------------------------------------------------+
//|                                                    DateRangeBreakoutContinuation.mqh |
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

#include <Wantanites\Framework\Objects\Indicators\Grid\GridTracker.mqh>
#include <Wantanites\Framework\Objects\Indicators\Time\DateRangeBreakout.mqh>

class DateRangeBreakoutContinuation : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    DateRangeBreakout *mDRB;
    GridTracker *mGT;

    int mCloseMonth;
    int mCloseDay;

    int mLastAchievedLevel;
    Dictionary<int, int> *mLevelsWithTickets;

    bool mCloseAllTickets;
    bool mFirstTicket;
    double mStartingEquity;

public:
    DateRangeBreakoutContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                  CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                  CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, DateRangeBreakout *&drb, GridTracker *&gt);
    ~DateRangeBreakoutContinuation();

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

DateRangeBreakoutContinuation::DateRangeBreakoutContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, DateRangeBreakout *&drb, GridTracker *&gt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mDRB = drb;
    mGT = gt;

    mCloseMonth = 0;
    mCloseDay = 0;

    mLastAchievedLevel = 10000;
    mLevelsWithTickets = new Dictionary<int, int>();

    mCloseAllTickets = false;
    mFirstTicket = true;
    mStartingEquity = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<DateRangeBreakoutContinuation>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<DateRangeBreakoutContinuation, SingleTimeFrameEntryTradeRecord>(this);
}

DateRangeBreakoutContinuation::~DateRangeBreakoutContinuation()
{
    delete mLevelsWithTickets;
}

void DateRangeBreakoutContinuation::PreRun()
{
    mDRB.Draw();
}

bool DateRangeBreakoutContinuation::AllowedToTrade()
{
    return EAHelper::BelowSpread<DateRangeBreakoutContinuation>(this) && EAHelper::WithinTradingSession<DateRangeBreakoutContinuation>(this);
}

void DateRangeBreakoutContinuation::CheckSetSetup()
{
    if (EAHelper::MostRecentCandleBrokeDateRange<DateRangeBreakoutContinuation>(this))
    {
        mGT.UpdateBasePrice(CurrentTick().Bid());
        mHasSetup = true;
    }
}

void DateRangeBreakoutContinuation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void DateRangeBreakoutContinuation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<DateRangeBreakoutContinuation>(this, deletePendingOrder, mStopTrading, error);
}

bool DateRangeBreakoutContinuation::Confirmation()
{
    if (mGT.CurrentLevel() != mLastAchievedLevel && !mLevelsWithTickets.HasKey(mGT.CurrentLevel()))
    {
        mLastAchievedLevel = mGT.CurrentLevel();
        return true;
    }

    return false;
}

void DateRangeBreakoutContinuation::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        // stopLoss = mGT.LevelPrice(mGT.CurrentLevel() - 2);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        // stopLoss = mGT.LevelPrice(mGT.CurrentLevel() + 2);
    }

    if (mFirstTicket)
    {
        mStartingEquity = AccountEquity();
        mFirstTicket = false;
    }

    EAHelper::PlaceMarketOrder<DateRangeBreakoutContinuation>(this, entry, stopLoss);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLevelsWithTickets.Add(mGT.CurrentLevel(), mCurrentSetupTickets[0].Number());
    }
}

void DateRangeBreakoutContinuation::PreManageTickets()
{
    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<DateRangeBreakoutContinuation>(this, mStartingEquity);
    if (equityPercentChange < -15)
    {
        mCloseAllTickets = true;
        mStopTrading = true;
    }
}

void DateRangeBreakoutContinuation::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void DateRangeBreakoutContinuation::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
    }

    EAHelper::MoveToBreakEvenAfterPips<DateRangeBreakoutContinuation>(this, ticket, 100);
}

bool DateRangeBreakoutContinuation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<DateRangeBreakoutContinuation>(this, ticket);
}

void DateRangeBreakoutContinuation::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
    }

    EAHelper::CheckTrailStopLossEveryXPips<DateRangeBreakoutContinuation>(this, ticket, 200, 100);
}

void DateRangeBreakoutContinuation::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void DateRangeBreakoutContinuation::CheckPreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<DateRangeBreakoutContinuation>(this, ticket);
}

void DateRangeBreakoutContinuation::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<DateRangeBreakoutContinuation>(this, ticket);
}

void DateRangeBreakoutContinuation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void DateRangeBreakoutContinuation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<DateRangeBreakoutContinuation>(this, ticket, Period());
}

void DateRangeBreakoutContinuation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<DateRangeBreakoutContinuation>(this, error, additionalInformation);
}

bool DateRangeBreakoutContinuation::ShouldReset()
{
    return Month() == mCloseMonth && Day() >= mCloseDay;
}

void DateRangeBreakoutContinuation::Reset()
{
    mStopTrading = false;
    InvalidateSetup(false);
    mLevelsWithTickets.Clear();

    mCloseAllTickets = false;
    mFirstTicket = true;
    mStartingEquity = 0;

    // the year we start running the program on will be correct for the next range and doeesn't need to be incremented
    if (TimeYear(mDRB.RangeStartTime()) != Year())
    {
        mDRB.IncrementYearAndReset();
    }

    EAHelper::CloseAllCurrentAndPendingTickets<DateRangeBreakoutContinuation>(this);
}