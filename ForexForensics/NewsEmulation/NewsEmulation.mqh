//+------------------------------------------------------------------+
//|                                                    NewsEmulation.mqh |
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

class NewsEmulation : public EA<ForexForensicsEntryTradeRecord, EmptyPartialTradeRecord, ForexForensicsExitTradeRecord, DefaultErrorRecord>
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
    NewsEmulation(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ForexForensicsExitTradeRecord> *&exitCSVRecordWriter,
                  CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter);
    ~NewsEmulation();

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

NewsEmulation::NewsEmulation(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ForexForensicsExitTradeRecord> *&exitCSVRecordWriter,
                             CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter)
    : EA(-99, -1, -1, -1, -1, -1, -1, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedEventsForToday = false;
    mDuringNews = false;

    mFurthestEquityDrawdownPercent = 0.0;
}

NewsEmulation::~NewsEmulation()
{
    delete mEconomicEvents;
}

void NewsEmulation::PreRun()
{
    if (!mLoadedEventsForToday)
    {
        EAHelper::GetEconomicEventsForDate<NewsEmulation>(this, TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, mEconomicEventImpacts);

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    double equityChange = EAHelper::GetTotalTicketsEquityPercentChange<NewsEmulation>(this, AccountBalance(), mCurrentSetupTickets) / 100;
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

bool NewsEmulation::AllowedToTrade()
{
    return false;
}

void NewsEmulation::CheckSetSetup()
{
}

void NewsEmulation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void NewsEmulation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<NewsEmulation>(this, deletePendingOrder, mStopTrading, error);
}

bool NewsEmulation::Confirmation()
{
    return true;
}

void NewsEmulation::PlaceOrders()
{
}

void NewsEmulation::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void NewsEmulation::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void NewsEmulation::PreManageTickets()
{
}

bool NewsEmulation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void NewsEmulation::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void NewsEmulation::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void NewsEmulation::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void NewsEmulation::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsEntryTradeRecord<NewsEmulation>(this, ticket);
}

void NewsEmulation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void NewsEmulation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsExitTradeRecord<NewsEmulation>(this, ticket, mEntryTimeFrame);
}

void NewsEmulation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordDefaultErrorRecord<NewsEmulation>(this, error, additionalInformation);
}

bool NewsEmulation::ShouldReset()
{
    return Day() != LastDay();
}

void NewsEmulation::Reset()
{
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();
}