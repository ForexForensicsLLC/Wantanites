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
    virtual bool CheckCurrentSetupTicket(Ticket &ticket);
    virtual bool CheckPreviousSetupTicket(Ticket &ticket);
    virtual void RecordTicketOpenData(Ticket &ticket);
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(string methodName, int error, string additionalInformation);
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
        EAHelper::GetEconomicEventsForDate<NewsEmulation>(this, "", TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, mEconomicEventImpacts);

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    double equityChange = EAOrderHelper::GetTotalTicketsEquityPercentChange<NewsEmulation>(this, AccountBalance(), mCurrentSetupTickets) / 100;
    if (equityChange < mFurthestEquityDrawdownPercent)
    {
        mFurthestEquityDrawdownPercent = equityChange;
    }

    EAOrderHelper::MimicOrders<NewsEmulation>(this);
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

void NewsEmulation::InvalidateSetup(bool deletePendingOrder, int error = -1)
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

bool NewsEmulation::CheckCurrentSetupTicket(Ticket &ticket)
{
    bool wasActivated = false;
    int error = ticket.WasActivatedSinceLastCheck(__FUNCTION__, wasActivated);
    if (wasActivated)
    {
        int currentTickets = mCurrentSetupTickets.Size();
        ObjectList<EconomicEvent> *events = new ObjectList<EconomicEvent>();
        int openIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), ticket.OpenTime());

        if (EAHelper::GetEconomicEventsForCandle<NewsEmulation>(this, events, openIndex))
        {
            TicketType type = ticket.Type();
            int newTicketNumber = ConstantValues::EmptyInt;

            if (type == TicketType::Buy)
            {
                double candleHigh = ConstantValues::EmptyDouble;
                for (int i = 0; i < events.Size(); i++)
                {
                    if (events[i].High() > candleHigh)
                    {
                        candleHigh = events[i].High();
                    }
                }

                double newOpenPrice = MathMin(ticket.OpenPrice() + PipConverter::PipsToPoints(25), candleHigh);

                if (CurrentTick().Ask() >= newOpenPrice)
                {
                    EAOrderHelper::PlaceMarketOrder<NewsEmulation>(this, newOpenPrice, ticket.CurrentStopLoss(), ticket.LotSize(), ticket.TakeProfit(), type);
                }
                else
                {
                    EAOrderHelper::PlaceStopOrder<NewsEmulation>(this, newOpenPrice, ticket.CurrentStopLoss(), ticket.LotSize(), ticket.TakeProfit(), false, 0.0, type);
                }
            }
            else if (type == TicketType::Sell)
            {
                double candleLow = ConstantValues::EmptyDouble;
                for (int i = 0; i < events.Size(); i++)
                {
                    if (events[i].Low() < candleHigh || candleLow == ConstantValues::EmptyDouble)
                    {
                        candleLow = events[i].Low();
                    }
                }

                double newOpenPrice = MathMax(ticket.OpenPrice() - PipConverter::PipsToRange(25), candleLow);

                if (CurrentTick().Bid() <= newOpenPrice)
                {
                    EAOrderHelper::PlaceMarketOrder<NewsEmulation>(this, newOpenPrice, ticket.CurrentStopLoss(), ticket.LotSize(), ticket.TakeProfit(), type);
                }
                else
                {
                    EAOrderHelper::PlaceStopOrder<NewsEmulation>(this, newOpenPrice, ticket.CurrentStopLoss(), ticket.LotSize(), ticket.TakeProfit(), false, 0.0, type);
                }
            }
        }

        // successfully added a new ticket
        if (currentTickets != mCurrentSetupTickets.Size())
        {
            mCurrentSetupTickets.RemoveWhere<TTicketNumberLocator, int>(Ticket::EqualsTicketNumber, ticket.Number());
            return true;
        }

        delete events;
    }

    return false;
}

bool NewsEmulation::CheckPreviousSetupTicket(Ticket &ticket)
{
    return false;
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

void NewsEmulation::RecordError(string methodName, int error, string additionalInformation = "")
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