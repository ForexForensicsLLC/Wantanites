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

    virtual double MaxSlippagePips() { return 25; }
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
        string calendar = "EventsAndCandles/" + EntrySymbol();
        EAHelper::GetEconomicEventsForDate<NewsEmulation, EconomicEventAndCandleRecord>(this, calendar, TimeGMT());

        mLoadedEventsForToday = true;
        mWasReset = false;
    }

    double equityChange = EAOrderHelper::GetTotalTicketsEquityPercentChange<NewsEmulation>(this, AccountInfoDouble(ACCOUNT_BALANCE), mCurrentSetupTickets) / 100;
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

void NewsEmulation::CheckCurrentSetupTicket(Ticket &ticket)
{
    bool wasActivated = false;
    int error = ticket.WasActivatedSinceLastCheck(__FUNCTION__, wasActivated);
    if (wasActivated)
    {
        int openIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), ticket.OpenTime());

        double emulatedOpenPrice = ConstantValues::EmptyDouble;
        TicketType type = ticket.Type();

        if (type == TicketType::Buy)
        {
            if (!EAHelper::GetCandleHighForEconomicEvent<NewsEmulation>(this, emulatedOpenPrice, openIndex))
            {
                return;
            }

            emulatedOpenPrice = MathMin(ticket.OpenPrice() + PipConverter::PipsToPoints(MaxSlippagePips()), emulatedOpenPrice);
        }
        else if (type == TicketType::Sell)
        {
            if (!EAHelper::GetCandleLowForEconomicEvent<NewsEmulation>(this, emulatedOpenPrice, openIndex))
            {
                return;
            }

            emulatedOpenPrice = MathMax(ticket.OpenPrice() - PipConverter::PipsToPoints(MaxSlippagePips()), emulatedOpenPrice);
        }

        // override the open price to the emulated open price
        ticket.ExpectedOpenPrice(emulatedOpenPrice);
    }
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
    EAHelper::RecordForexForensicsExitTradeRecord<NewsEmulation>(this, ticket, EntryTimeFrame());
}

void NewsEmulation::RecordError(string methodName, int error, string additionalInformation = "")
{
    EAHelper::RecordDefaultErrorRecord<NewsEmulation>(this, methodName, error, additionalInformation);
}

bool NewsEmulation::ShouldReset()
{
    return DateTimeHelper::CurrentDay() != LastDay();
}

void NewsEmulation::Reset()
{
    mLoadedEventsForToday = false;
    mEconomicEvents.Clear();
}