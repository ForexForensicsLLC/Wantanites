//+------------------------------------------------------------------+
//|                                                    OnlyNewsTimeRangeBreakout.mqh |
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

class OnlyNewsTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;
    ObjectList<EconomicEvent> *mEconomicEvents;

    bool mLoadedEventsForToday;

public:
    OnlyNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~OnlyNewsTimeRangeBreakout();

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

OnlyNewsTimeRangeBreakout::OnlyNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;
    mEconomicEvents = new ObjectList<EconomicEvent>();
    mLoadedEventsForToday = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<OnlyNewsTimeRangeBreakout>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<OnlyNewsTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

OnlyNewsTimeRangeBreakout::~OnlyNewsTimeRangeBreakout()
{
    delete mEconomicEvents;
}

void OnlyNewsTimeRangeBreakout::PreRun()
{
    mTRB.Draw();
}

bool OnlyNewsTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<OnlyNewsTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<OnlyNewsTimeRangeBreakout>(this);
}

void OnlyNewsTimeRangeBreakout::CheckSetSetup()
{
    if (!mLoadedEventsForToday)
    {
        EAHelper::GetEconomicEventsForDate<OnlyNewsTimeRangeBreakout>(this, TimeGMT(), "", ImpactEnum::HighImpact);
        mLoadedEventsForToday = true;
    }

    if (EAHelper::MostRecentCandleBrokeTimeRange<OnlyNewsTimeRangeBreakout>(this))
    {
        if (EAHelper::CurrentCandleIsDuringEconomicEvent<OnlyNewsTimeRangeBreakout>(this))
        {
            mHasSetup = true;
        }
    }
}

void OnlyNewsTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (LastDay() != Day())
    {
        InvalidateSetup(true);
    }
}

void OnlyNewsTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<OnlyNewsTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);
}

bool OnlyNewsTimeRangeBreakout::Confirmation()
{
    return true;
}

void OnlyNewsTimeRangeBreakout::PlaceOrders()
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

    EAHelper::PlaceMarketOrder<OnlyNewsTimeRangeBreakout>(this, entry, stopLoss);
    mStopTrading = true;
}

void OnlyNewsTimeRangeBreakout::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void OnlyNewsTimeRangeBreakout::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void OnlyNewsTimeRangeBreakout::PreManageTickets()
{
}

bool OnlyNewsTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void OnlyNewsTimeRangeBreakout::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void OnlyNewsTimeRangeBreakout::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void OnlyNewsTimeRangeBreakout::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void OnlyNewsTimeRangeBreakout::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<OnlyNewsTimeRangeBreakout>(this, ticket);
}

void OnlyNewsTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void OnlyNewsTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<OnlyNewsTimeRangeBreakout>(this, ticket, Period());
}

void OnlyNewsTimeRangeBreakout::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<OnlyNewsTimeRangeBreakout>(this, error, additionalInformation);
}

bool OnlyNewsTimeRangeBreakout::ShouldReset()
{
    return !EAHelper::WithinTradingSession<OnlyNewsTimeRangeBreakout>(this);
}

void OnlyNewsTimeRangeBreakout::Reset()
{
    mStopTrading = false;
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();

    EAHelper::CloseAllCurrentAndPreviousSetupTickets<OnlyNewsTimeRangeBreakout>(this);
}