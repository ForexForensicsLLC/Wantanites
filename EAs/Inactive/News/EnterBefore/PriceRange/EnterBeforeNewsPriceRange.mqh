//+------------------------------------------------------------------+
//|                                                    EnterBeforeNewsPriceRange.mqh |
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

class EnterBeforeNewsPriceRange : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    ObjectList<EconomicEvent> *mEconomicEvents;
    bool mLoadedTodaysEvents;

    double mEntryPipsFromOrderTrigger;
    double mPipsToWatiBeforeBE;
    double mBEAdditionalPips;

public:
    EnterBeforeNewsPriceRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~EnterBeforeNewsPriceRange();

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

EnterBeforeNewsPriceRange::EnterBeforeNewsPriceRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();
    mLoadedTodaysEvents = false;

    mEntryPipsFromOrderTrigger = 0.0;
    mPipsToWatiBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EnterBeforeNewsPriceRange>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EnterBeforeNewsPriceRange, SingleTimeFrameEntryTradeRecord>(this);
}

EnterBeforeNewsPriceRange::~EnterBeforeNewsPriceRange()
{
    delete mEconomicEvents;
}

void EnterBeforeNewsPriceRange::PreRun()
{
}

bool EnterBeforeNewsPriceRange::AllowedToTrade()
{
    return EAHelper::BelowSpread<EnterBeforeNewsPriceRange>(this) && EAHelper::WithinTradingSession<EnterBeforeNewsPriceRange>(this);
}

void EnterBeforeNewsPriceRange::CheckSetSetup()
{
    if (!mLoadedTodaysEvents)
    {
        EAHelper::GetEconomicEventsForDate<EnterBeforeNewsPriceRange>(this, TimeGMT(), "USD", ImpactEnum::HighImpact);
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

void EnterBeforeNewsPriceRange::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void EnterBeforeNewsPriceRange::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<EnterBeforeNewsPriceRange>(this, deletePendingOrder, mStopTrading, error);
}

bool EnterBeforeNewsPriceRange::Confirmation()
{
    return true;
}

void EnterBeforeNewsPriceRange::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask() + OrderHelper::PipsToRange(mEntryPipsFromOrderTrigger);
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid() - OrderHelper::PipsToRange(mEntryPipsFromOrderTrigger);
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceStopOrder<EnterBeforeNewsPriceRange>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void EnterBeforeNewsPriceRange::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsPriceRange::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAHelper::MoveToBreakEvenAfterPips<EnterBeforeNewsPriceRange>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

void EnterBeforeNewsPriceRange::PreManageTickets()
{
}

bool EnterBeforeNewsPriceRange::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void EnterBeforeNewsPriceRange::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsPriceRange::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsPriceRange::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void EnterBeforeNewsPriceRange::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<EnterBeforeNewsPriceRange>(this, ticket);
}

void EnterBeforeNewsPriceRange::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void EnterBeforeNewsPriceRange::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EnterBeforeNewsPriceRange>(this, ticket, Period());
}

void EnterBeforeNewsPriceRange::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EnterBeforeNewsPriceRange>(this, error, additionalInformation);
}

bool EnterBeforeNewsPriceRange::ShouldReset()
{
    return !EAHelper::WithinTradingSession<EnterBeforeNewsPriceRange>(this);
}

void EnterBeforeNewsPriceRange::Reset()
{
    Print("Reset");
    mStopTrading = false;
    mLoadedTodaysEvents = false;
    InvalidateSetup(true);

    mEconomicEvents.Clear();

    EAHelper::CloseAllCurrentAndPreviousSetupTickets<EnterBeforeNewsPriceRange>(this);
}