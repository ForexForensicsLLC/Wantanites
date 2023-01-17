//+------------------------------------------------------------------+
//|                                                    PriceRange.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EA\EA.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

class PriceRange : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    int mCloseHour;
    int mCloseMinute;
    double mPipsFromOpen;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

public:
    PriceRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~PriceRange();

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManageCurrentPendingSetupTicket();
    virtual void ManageCurrentActiveSetupTicket();
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(int ticketIndex);
    virtual void CheckCurrentSetupTicket();
    virtual void CheckPreviousSetupTicket(int ticketIndex);
    virtual void RecordTicketOpenData();
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

PriceRange::PriceRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mCloseHour = 0;
    mCloseMinute = 0;
    mPipsFromOpen = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<PriceRange>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<PriceRange, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<PriceRange, SingleTimeFrameEntryTradeRecord>(this);
}

PriceRange::~PriceRange()
{
}

void PriceRange::Run()
{
    EAHelper::Run<PriceRange>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool PriceRange::AllowedToTrade()
{
    // bool allowedToTrade = EAHelper::BelowSpread<PriceRange>(this) && EAHelper::WithinTradingSession<PriceRange>(this);

    if (!EAHelper::BelowSpread<PriceRange>(this))
    {
        Print("Above Spred. ", (MarketInfo(Symbol(), MODE_SPREAD) / 10));
        return false;
    }

    if (!EAHelper::WithinTradingSession<PriceRange>(this))
    {
        Print("Not Within Session. ", iTime(mEntrySymbol, mEntryTimeFrame, 0));
    }

    return true;
}

void PriceRange::CheckSetSetup()
{
    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        Print("Bars: ", iBars(mEntrySymbol, mEntryTimeFrame), ", Bar Count: ", mBarCount);
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    Print("Hour: ", Hour(), ", Hour Start: ", mTradingSessions[0].HourStart(), ", Minute: ", Minute(), ", Minute Start: ", mTradingSessions[0].MinuteStart());
    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        Print("Setup");
        mHasSetup = true;
    }
}

void PriceRange::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void PriceRange::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<PriceRange>(this, deletePendingOrder, mStopTrading, error);
}

bool PriceRange::Confirmation()
{
    Print("Conf");
    return true;
}

void PriceRange::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        Print("No Tick");
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask + OrderHelper::PipsToRange(mPipsFromOpen);
        stopLoss = currentTick.ask;
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid - OrderHelper::PipsToRange(mPipsFromOpen);
        stopLoss = currentTick.bid;
    }

    Print("Sending Order");
    EAHelper::PlaceStopOrder<PriceRange>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        Print("Didn't place Order");
    }

    InvalidateSetup(false);
}

void PriceRange::ManageCurrentPendingSetupTicket()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (Day() != mLastDay)
    {
        InvalidateSetup(true);
    }
}

void PriceRange::ManageCurrentActiveSetupTicket()
{
    if (EAHelper::CloseTicketIfPastTime<PriceRange>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute))
    {
        return;
    }
}

bool PriceRange::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void PriceRange::ManagePreviousSetupTicket(int ticketIndex)
{
}

void PriceRange::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PriceRange>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<PriceRange>(this);
}

void PriceRange::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PriceRange>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<PriceRange>(this, ticketIndex);
}

void PriceRange::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<PriceRange>(this);
}

void PriceRange::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<PriceRange>(this, partialedTicket, newTicketNumber);
}

void PriceRange::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<PriceRange>(this, ticket, Period());
}

void PriceRange::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<PriceRange>(this, error, additionalInformation);
}

void PriceRange::Reset()
{
}