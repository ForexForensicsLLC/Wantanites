//+------------------------------------------------------------------+
//|                                                    EnterBeforeNewsHedge.mqh |
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

#include <Wantanites\Framework\Objects\DataObjects\EconomicEvent.mqh>

class EnterBeforeNewsHedge : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    ObjectList<EconomicEvent> *mEconomicEvents;
    bool mLoadedTodaysEvents;

    double mPipsToWatiBeforeBE;
    double mBEAdditionalPips;

public:
    EnterBeforeNewsHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~EnterBeforeNewsHedge();

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

EnterBeforeNewsHedge::EnterBeforeNewsHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();
    mLoadedTodaysEvents = false;

    mPipsToWatiBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EnterBeforeNewsHedge>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EnterBeforeNewsHedge, SingleTimeFrameEntryTradeRecord>(this);
}

EnterBeforeNewsHedge::~EnterBeforeNewsHedge()
{
    delete mEconomicEvents;
}

void EnterBeforeNewsHedge::PreRun()
{
}

bool EnterBeforeNewsHedge::AllowedToTrade()
{
    return EAHelper::BelowSpread<EnterBeforeNewsHedge>(this) && EAHelper::WithinTradingSession<EnterBeforeNewsHedge>(this);
}

void EnterBeforeNewsHedge::CheckSetSetup()
{
    if (!mLoadedTodaysEvents)
    {
        EAHelper::GetEconomicEventsForDate<EnterBeforeNewsHedge>(this, TimeGMT(), "USD", ImpactEnum::HighImpact);
        mLoadedTodaysEvents = true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    // this doesn't need to be offseted by MQls utc offset for some reason? Maybe its taken into account already?
    datetime timeCurrent = TimeGMT();
    int minTimeDifference = 60 * 5; // 5  minutes in seconds

    for (int i = 0; i < mEconomicEvents.Size(); i++)
    {
        // already past event
        if (timeCurrent > mEconomicEvents[i].Date())
        {
            continue;
        }

        // we are 5 minutes within a new event
        if (mEconomicEvents[i].Date() - timeCurrent <= minTimeDifference)
        {
            // remove it so that we don't enter on it again
            mEconomicEvents.Remove(i);
            mHasSetup = true;

            return;
        }
    }
}

void EnterBeforeNewsHedge::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void EnterBeforeNewsHedge::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<EnterBeforeNewsHedge>(this, deletePendingOrder, mStopTrading, error);
}

bool EnterBeforeNewsHedge::Confirmation()
{
    return true;
}

void EnterBeforeNewsHedge::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceMarketOrder<EnterBeforeNewsHedge>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void EnterBeforeNewsHedge::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsHedge::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAHelper::MoveToBreakEvenAfterPips<EnterBeforeNewsHedge>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

void EnterBeforeNewsHedge::PreManageTickets()
{
}

bool EnterBeforeNewsHedge::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void EnterBeforeNewsHedge::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsHedge::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsHedge::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsHedge::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<EnterBeforeNewsHedge>(this, ticket);
}

void EnterBeforeNewsHedge::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void EnterBeforeNewsHedge::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EnterBeforeNewsHedge>(this, ticket, Period());
}

void EnterBeforeNewsHedge::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EnterBeforeNewsHedge>(this, error, additionalInformation);
}

bool EnterBeforeNewsHedge::ShouldReset()
{
    return !EAHelper::WithinTradingSession<EnterBeforeNewsHedge>(this);
}

void EnterBeforeNewsHedge::Reset()
{
    mStopTrading = false;
    mLoadedTodaysEvents = false;
    InvalidateSetup(true);

    mEconomicEvents.Clear();

    EAHelper::CloseAllCurrentAndPreviousSetupTickets<EnterBeforeNewsHedge>(this);
}