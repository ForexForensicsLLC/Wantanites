//+------------------------------------------------------------------+
//|                                                    FeatureEngineering.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

#include <Wantanites\Framework\Objects\Indicators\HeikinAshi\HeikinAshiTracker.mqh>

class FeatureEngineering : public EA<FeatureEngineeringEntryTradeRecord, EmptyPartialTradeRecord, FeatureEngineeringExitTradeRecord, DefaultErrorRecord>
{
public:
    MBTracker *mMBT;
    HeikinAshiTracker *mHAT;

    ObjectList<EconomicEvent> *mEconomicEvents;

    List<string> *mEconomicEventTitles;
    List<string> *mEconomicEventSymbols;
    List<int> *mEconomicEventImpacts;

    bool mLoadedEventsForToday;
    bool mDuringNews;

    double mFurthestEquityDrawdownPercent;

public:
    FeatureEngineering(CSVRecordWriter<FeatureEngineeringEntryTradeRecord> *&entryCSVRecordWriter,
                       CSVRecordWriter<FeatureEngineeringExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter);
    ~FeatureEngineering();

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

FeatureEngineering::FeatureEngineering(CSVRecordWriter<FeatureEngineeringEntryTradeRecord> *&entryCSVRecordWriter,
                                       CSVRecordWriter<FeatureEngineeringExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter)
    : EA(-99, -1, -1, -1, -1, -1, -1, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mMBT = new MBTracker(false, EntrySymbol(), EntryTimeFrame(), -1, 2, 3, CandlePart::Body, CandlePart::Body, true, 5, true, CandlePart::Body, ZonePartInMB::Whole,
                         false, false, true, CandlePart::Wick, true, false);

    mHAT = new HeikinAshiTracker();

    mLoadedEventsForToday = false;
    mDuringNews = false;

    mFurthestEquityDrawdownPercent = 0.0;
}

FeatureEngineering::~FeatureEngineering()
{
    delete mEconomicEvents;
    delete mMBT;
    delete mHAT;
}

void FeatureEngineering::PreRun()
{
    if (!mLoadedEventsForToday)
    {
        string calendar = "EventsAndCandles/" + EntrySymbol();
        EASetupHelper::GetEconomicEventsForDate<FeatureEngineering, EconomicEventAndCandleRecord>(this, calendar, TimeGMT(), false);

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    double equityChange = EAOrderHelper::GetTotalTicketsEquityPercentChange<FeatureEngineering>(this, AccountInfoDouble(ACCOUNT_BALANCE), mCurrentSetupTickets) / 100;
    if (equityChange < mFurthestEquityDrawdownPercent)
    {
        mFurthestEquityDrawdownPercent = equityChange;
    }

    EAOrderHelper::MimicOrders<FeatureEngineering>(this);
}

bool FeatureEngineering::AllowedToTrade()
{
    return false;
}

void FeatureEngineering::CheckSetSetup()
{
}

void FeatureEngineering::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void FeatureEngineering::InvalidateSetup(bool deletePendingOrder, int error = -1)
{
    EASetupHelper::InvalidateSetup<FeatureEngineering>(this, deletePendingOrder, mStopTrading, error);
}

bool FeatureEngineering::Confirmation()
{
    return true;
}

void FeatureEngineering::PlaceOrders()
{
}

void FeatureEngineering::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void FeatureEngineering::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void FeatureEngineering::PreManageTickets()
{
}

bool FeatureEngineering::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void FeatureEngineering::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void FeatureEngineering::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void FeatureEngineering::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void FeatureEngineering::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordFeatureEngineeringEntryTradeRecord<FeatureEngineering>(this, ticket);
}

void FeatureEngineering::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void FeatureEngineering::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordFeatureEngineeringExitTradeRecord<FeatureEngineering>(this, ticket);
}

void FeatureEngineering::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordDefaultErrorRecord<FeatureEngineering>(this, methodName, error, additionalInformation);
}

bool FeatureEngineering::ShouldReset()
{
    return DateTimeHelper::CurrentDay() != LastDay();
}

void FeatureEngineering::Reset()
{
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();
}