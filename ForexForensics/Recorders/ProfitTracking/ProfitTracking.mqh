//+------------------------------------------------------------------+
//|                                                    ProfitTracking.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class ProfitTracking : public EA<ForexForensicsEntryTradeRecord, EmptyPartialTradeRecord, ProfitTrackingExitTradeRecord, DefaultErrorRecord>
{
public:
    ObjectList<EconomicEvent> *mEconomicEvents;

    List<string> *mEconomicEventTitles;
    List<string> *mEconomicEventSymbols;
    List<int> *mEconomicEventImpacts;

    bool mLoadedEventsForToday;
    bool mDuringNews;

    double mFurthestEquityDrawdownPercent;

public:
    ProfitTracking(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ProfitTrackingExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter);
    ~ProfitTracking();

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
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

ProfitTracking::ProfitTracking(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ProfitTrackingExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter)
    : EA(-99, -1, -1, -1, -1, -1, -1, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedEventsForToday = false;
    mDuringNews = false;

    mFurthestEquityDrawdownPercent = 0.0;
}

ProfitTracking::~ProfitTracking()
{
    delete mEconomicEvents;
}

void ProfitTracking::PreRun()
{
    if (!mLoadedEventsForToday)
    {
        string calendar = "JustEvents";
        EAHelper::GetEconomicEventsForDate<ProfitTracking, EconomicEventRecord>(this, calendar, TimeGMT());

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    double equityChange = EAOrderHelper::GetTotalTicketsEquityPercentChange<ProfitTracking>(this, AccountInfoDouble(ACCOUNT_BALANCE), mCurrentSetupTickets) / 100;
    if (equityChange < mFurthestEquityDrawdownPercent)
    {
        mFurthestEquityDrawdownPercent = equityChange;
    }

    EAOrderHelper::MimicOrders<ProfitTracking>(this);
}

bool ProfitTracking::AllowedToTrade()
{
    return false;
}

void ProfitTracking::CheckSetSetup()
{
}

void ProfitTracking::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void ProfitTracking::InvalidateSetup(bool deletePendingOrder, int error = -1)
{
    EAHelper::InvalidateSetup<ProfitTracking>(this, deletePendingOrder, mStopTrading, error);
}

bool ProfitTracking::Confirmation()
{
    return true;
}

void ProfitTracking::PlaceOrders()
{
}

void ProfitTracking::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void ProfitTracking::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void ProfitTracking::PreManageTickets()
{
}

bool ProfitTracking::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void ProfitTracking::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void ProfitTracking::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void ProfitTracking::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void ProfitTracking::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsEntryTradeRecord<ProfitTracking>(this, ticket);
}

void ProfitTracking::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void ProfitTracking::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordProfitTrackingExitTradeRecord<ProfitTracking>(this, ticket, EntryTimeFrame());
}

void ProfitTracking::RecordError(string methodName, int error, string additionalInformation = "")
{
    EAHelper::RecordDefaultErrorRecord<ProfitTracking>(this, methodName, error, additionalInformation);
}

bool ProfitTracking::ShouldReset()
{
    return DateTimeHelper::CurrentDay() != LastDay();
}

void ProfitTracking::Reset()
{
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();
}