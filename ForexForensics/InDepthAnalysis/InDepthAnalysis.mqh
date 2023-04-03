//+------------------------------------------------------------------+
//|                                                    InDepthAnalysis.mqh |
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

class InDepthAnalysis : public EA<ForexForensicsEntryTradeRecord, EmptyPartialTradeRecord, ForexForensicsExitTradeRecord, DefaultErrorRecord>
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
    InDepthAnalysis(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ForexForensicsExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter);
    ~InDepthAnalysis();

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

InDepthAnalysis::InDepthAnalysis(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ForexForensicsExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter)
    : EA(-99, -1, -1, -1, -1, -1, -1, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedEventsForToday = false;
    mDuringNews = false;

    mFurthestEquityDrawdownPercent = 0.0;
}

InDepthAnalysis::~InDepthAnalysis()
{
    delete mEconomicEvents;
}

void InDepthAnalysis::PreRun()
{
    if (!mLoadedEventsForToday)
    {
        EAHelper::GetEconomicEventsForDate<InDepthAnalysis>(this, TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, mEconomicEventImpacts);

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    double equityChange = EAHelper::GetTotalTicketsEquityPercentChange<InDepthAnalysis>(this, AccountBalance(), mCurrentSetupTickets) / 100;
    if (equityChange < mFurthestEquityDrawdownPercent)
    {
        mFurthestEquityDrawdownPercent = equityChange;
    }

    if (OrdersTotal() > mCurrentSetupTickets.Size())
    {
        for (int i = 0; i < OrdersTotal(); i++)
        {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                RecordError(GetLastError());
                continue;
            }

            if (!mCurrentSetupTickets.Contains<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, OrderTicket()))
            {
                Ticket *ticket = new Ticket(OrderTicket());
                ticket.OriginalOpenPrice(ticket.OpenPrice());
                mCurrentSetupTickets.Add(ticket);
            }
        }
    }
}

bool InDepthAnalysis::AllowedToTrade()
{
    return false;
}

void InDepthAnalysis::CheckSetSetup()
{
}

void InDepthAnalysis::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void InDepthAnalysis::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<InDepthAnalysis>(this, deletePendingOrder, mStopTrading, error);
}

bool InDepthAnalysis::Confirmation()
{
    return true;
}

void InDepthAnalysis::PlaceOrders()
{
}

void InDepthAnalysis::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void InDepthAnalysis::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void InDepthAnalysis::PreManageTickets()
{
}

bool InDepthAnalysis::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void InDepthAnalysis::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void InDepthAnalysis::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void InDepthAnalysis::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void InDepthAnalysis::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsEntryTradeRecord<InDepthAnalysis>(this, ticket);
}

void InDepthAnalysis::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void InDepthAnalysis::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsExitTradeRecord<InDepthAnalysis>(this, ticket, mEntryTimeFrame);
}

void InDepthAnalysis::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordDefaultErrorRecord<InDepthAnalysis>(this, error, additionalInformation);
}

bool InDepthAnalysis::ShouldReset()
{
    return Day() != LastDay();
}

void InDepthAnalysis::Reset()
{
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();
}