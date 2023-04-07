//+------------------------------------------------------------------+
//|                                                    StartOfDayTimeRangeBreakout.mqh |
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

#include <Wantanites\Framework\Objects\Indicators\Time\TimeRangeBreakout.mqh>

class StartOfDayTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;

public:
    StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~StartOfDayTimeRangeBreakout();

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

StartOfDayTimeRangeBreakout::StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayTimeRangeBreakout>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

StartOfDayTimeRangeBreakout::~StartOfDayTimeRangeBreakout()
{
}

void StartOfDayTimeRangeBreakout::PreRun()
{
    mTRB.Draw();
}

bool StartOfDayTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::CheckSetSetup()
{
    if (EAHelper::MostRecentCandleBrokeTimeRange<StartOfDayTimeRangeBreakout>(this))
    {
        mHasSetup = true;
    }
}

void StartOfDayTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (LastDay() != Day())
    {
        InvalidateSetup(true);
    }
}

void StartOfDayTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<StartOfDayTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);
}

bool StartOfDayTimeRangeBreakout::Confirmation()
{
    return true;
}

void StartOfDayTimeRangeBreakout::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = mTRB.RangeLow();
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = mTRB.RangeHigh();
    }

    EAHelper::PlaceMarketOrder<StartOfDayTimeRangeBreakout>(this, entry, stopLoss);
    mStopTrading = true;
}

void StartOfDayTimeRangeBreakout::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void StartOfDayTimeRangeBreakout::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void StartOfDayTimeRangeBreakout::PreManageTickets()
{
}

bool StartOfDayTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void StartOfDayTimeRangeBreakout::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void StartOfDayTimeRangeBreakout::CheckCurrentSetupTicket(Ticket &ticket)
{
    // Make sure we are only ever losing how much we intend to risk, even if we entered at a worse price due to slippage
    if ((AccountEquity() - AccountBalance()) / AccountBalance() * 100 <= -RiskPercent())
    {
        ticket.Close();
    }
}

void StartOfDayTimeRangeBreakout::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void StartOfDayTimeRangeBreakout::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StartOfDayTimeRangeBreakout>(this, ticket);
}

void StartOfDayTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void StartOfDayTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<StartOfDayTimeRangeBreakout>(this, ticket, Period());
}

void StartOfDayTimeRangeBreakout::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<StartOfDayTimeRangeBreakout>(this, error, additionalInformation);
}

bool StartOfDayTimeRangeBreakout::ShouldReset()
{
    return !EAHelper::WithinTradingSession<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::Reset()
{
    mStopTrading = false;
    EAHelper::CloseAllCurrentAndPreviousSetupTickets<StartOfDayTimeRangeBreakout>(this);
}