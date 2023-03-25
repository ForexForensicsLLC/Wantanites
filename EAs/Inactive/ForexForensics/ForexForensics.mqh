//+------------------------------------------------------------------+
//|                                                    ForexForensics.mqh |
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

class ForexForensics : public EA<ForexForensicsEntryTradeRecord, EmptyPartialTradeRecord, ForexForensicsExitTradeRecord, DefaultErrorRecord>
{
public:
    ObjectList<EconomicEvent> *mEconomicEvents;

    List<string> *mEconomicEventTitles;
    List<string> *mEconomicEventSymbols;
    List<int> *mEconomicEventImpacts;

    bool mLoadedEventsForToday;
    bool mDuringNews;

public:
    ForexForensics(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ForexForensicsExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter);
    ~ForexForensics();

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

ForexForensics::ForexForensics(CSVRecordWriter<ForexForensicsEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<ForexForensicsExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<DefaultErrorRecord> *&errorCSVRecordWriter)
    : EA(-99, -1, -1, -1, -1, -1, -1, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedEventsForToday = false;
    mDuringNews = false;
}

ForexForensics::~ForexForensics()
{
    delete mEconomicEvents;
}

void ForexForensics::PreRun()
{
    if (!mLoadedEventsForToday)
    {
        Print("Loading Events for ", TimeGMT());
        EAHelper::GetEconomicEventsForDate<ForexForensics>(this, TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, mEconomicEventImpacts);

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    if (OrdersTotal() > mCurrentSetupTickets.Size())
    {
        for (int i = 0; i < OrdersTotal(); i++)
        {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                Print("Failed to select order at position ", i);
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

bool ForexForensics::AllowedToTrade()
{
    return false;
}

void ForexForensics::CheckSetSetup()
{
}

void ForexForensics::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void ForexForensics::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ForexForensics>(this, deletePendingOrder, mStopTrading, error);
}

bool ForexForensics::Confirmation()
{
    return true;
}

void ForexForensics::PlaceOrders()
{
}

void ForexForensics::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void ForexForensics::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void ForexForensics::PreManageTickets()
{
}

bool ForexForensics::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void ForexForensics::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void ForexForensics::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void ForexForensics::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void ForexForensics::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsEntryTradeRecord<ForexForensics>(this, ticket);
}

void ForexForensics::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void ForexForensics::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordForexForensicsExitTradeRecord<ForexForensics>(this, ticket, mEntryTimeFrame);
}

void ForexForensics::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordDefaultErrorRecord<ForexForensics>(this, error, additionalInformation);
}

bool ForexForensics::ShouldReset()
{
    return Day() != LastDay();
}

void ForexForensics::Reset()
{
    Print("Resetting");
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();
}