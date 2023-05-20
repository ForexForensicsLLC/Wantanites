//+------------------------------------------------------------------+
//|                                                    NoNewsTimeRangeBreakout.mqh |
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

class NoNewsTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;
    ObjectList<EconomicEvent> *mEconomicEvents;

    bool mLoadedEventsForToday;

public:
    NoNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                            CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                            CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~NoNewsTimeRangeBreakout();

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

NoNewsTimeRangeBreakout::NoNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;
    mEconomicEvents = new ObjectList<EconomicEvent>();
    mLoadedEventsForToday = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<NoNewsTimeRangeBreakout>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<NoNewsTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

NoNewsTimeRangeBreakout::~NoNewsTimeRangeBreakout()
{
    delete mEconomicEvents;
}

void NoNewsTimeRangeBreakout::PreRun()
{
    mTRB.Draw();
}

bool NoNewsTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<NoNewsTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<NoNewsTimeRangeBreakout>(this);
}

void NoNewsTimeRangeBreakout::CheckSetSetup()
{
    if (!mLoadedEventsForToday)
    {
        EAHelper::GetEconomicEventsForDate<NoNewsTimeRangeBreakout>(this, TimeGMT(), "", ImpactEnum::HighImpact);
        mLoadedEventsForToday = true;
    }

    if (EAHelper::MostRecentCandleBrokeTimeRange<NoNewsTimeRangeBreakout>(this))
    {
        if (EAHelper::CurrentCandleIsDuringEconomicEvent<NoNewsTimeRangeBreakout>(this))
        {
            mStopTrading = true;
            return;
        }

        mHasSetup = true;
    }
}

void NoNewsTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (LastDay() != Day())
    {
        InvalidateSetup(true);
    }
}

void NoNewsTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<NoNewsTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);
}

bool NoNewsTimeRangeBreakout::Confirmation()
{
    return true;
}

void NoNewsTimeRangeBreakout::PlaceOrders()
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

    EAHelper::PlaceMarketOrder<NoNewsTimeRangeBreakout>(this, entry, stopLoss);
    mStopTrading = true;
}

void NoNewsTimeRangeBreakout::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void NoNewsTimeRangeBreakout::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void NoNewsTimeRangeBreakout::PreManageTickets()
{
}

bool NoNewsTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void NoNewsTimeRangeBreakout::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void NoNewsTimeRangeBreakout::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void NoNewsTimeRangeBreakout::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void NoNewsTimeRangeBreakout::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<NoNewsTimeRangeBreakout>(this, ticket);
}

void NoNewsTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void NoNewsTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<NoNewsTimeRangeBreakout>(this, ticket, Period());
}

void NoNewsTimeRangeBreakout::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<NoNewsTimeRangeBreakout>(this, error, additionalInformation);
}

bool NoNewsTimeRangeBreakout::ShouldReset()
{
    return !EAHelper::WithinTradingSession<NoNewsTimeRangeBreakout>(this);
}

void NoNewsTimeRangeBreakout::Reset()
{
    mStopTrading = false;
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();

    EAHelper::CloseAllCurrentAndPreviousSetupTickets<NoNewsTimeRangeBreakout>(this);
}