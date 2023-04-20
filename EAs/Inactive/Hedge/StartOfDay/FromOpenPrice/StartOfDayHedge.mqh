//+------------------------------------------------------------------+
//|                                                    StartOfDayHedge.mqh |
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

class StartOfDayHedge : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mPipsFromOpen;
    double mTrailStopLossPips;

public:
    StartOfDayHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~StartOfDayHedge();

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

StartOfDayHedge::StartOfDayHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPipsFromOpen = 0.0;
    mTrailStopLossPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayHedge>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayHedge, SingleTimeFrameEntryTradeRecord>(this);
}

StartOfDayHedge::~StartOfDayHedge()
{
}

void StartOfDayHedge::PreRun()
{
}

bool StartOfDayHedge::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayHedge>(this) && EAHelper::WithinTradingSession<StartOfDayHedge>(this);
}

void StartOfDayHedge::CheckSetSetup()
{
    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        mHasSetup = true;
    }
}

void StartOfDayHedge::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void StartOfDayHedge::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<StartOfDayHedge>(this, deletePendingOrder, mStopTrading, error);
}

bool StartOfDayHedge::Confirmation()
{
    return true;
}

void StartOfDayHedge::PlaceOrders()
{
    double entry = CurrentTick().Bid() + OrderHelper::PipsToRange(mPipsFromOpen);
    double stopLoss = 0.0;

    if (mPipsFromOpen > 0)
    {
        if (SetupType() == OP_BUY)
        {
            stopLoss = CurrentTick().Bid();
            EAHelper::PlaceStopOrder<StartOfDayHedge>(this, entry, stopLoss);
        }
        else if (SetupType() == OP_SELL)
        {
            stopLoss = entry + MathAbs(entry - CurrentTick().Bid());
            EAHelper::PlaceLimitOrder<StartOfDayHedge>(this, entry, stopLoss);
        }
    }
    else
    {
        if (SetupType() == OP_BUY)
        {
            stopLoss = entry - MathAbs(entry - CurrentTick().Bid());
            EAHelper::PlaceLimitOrder<StartOfDayHedge>(this, entry, stopLoss);
        }
        else if (SetupType() == OP_SELL)
        {
            stopLoss = CurrentTick().Bid();
            EAHelper::PlaceStopOrder<StartOfDayHedge>(this, entry, stopLoss);
        }
    }

    mStopTrading = true;
}

void StartOfDayHedge::PreManageTickets()
{
}

void StartOfDayHedge::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void StartOfDayHedge::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    // EAHelper::MoveToBreakEvenAfterPips<StartOfDayHedge>(this, ticket, MathAbs(mPipsFromOpen) / 2);
}

bool StartOfDayHedge::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return EAHelper::TicketStopLossIsMovedToBreakEven<StartOfDayHedge>(this, ticket);
    return false;
}

void StartOfDayHedge::ManagePreviousSetupTicket(Ticket &ticket)
{
    // EAHelper::CheckTrailStopLossEveryXPips<StartOfDayHedge>(this, ticket, mTrailStopLossPips * 2, mTrailStopLossPips);
}

void StartOfDayHedge::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void StartOfDayHedge::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void StartOfDayHedge::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StartOfDayHedge>(this, ticket);
}

void StartOfDayHedge::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void StartOfDayHedge::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<StartOfDayHedge>(this, ticket, Period());
}

void StartOfDayHedge::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<StartOfDayHedge>(this, error, additionalInformation);
}

bool StartOfDayHedge::ShouldReset()
{
    return !EAHelper::WithinTradingSession<StartOfDayHedge>(this);
}

void StartOfDayHedge::Reset()
{
    mStopTrading = false;
    mHasSetup = false;

    EAHelper::CloseAllCurrentAndPendingTickets<StartOfDayHedge>(this);
}