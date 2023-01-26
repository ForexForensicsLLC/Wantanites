//+------------------------------------------------------------------+
//|                                                    StartOfDayHedge.mqh |
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

class StartOfDayHedge : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mTakeProfitPips;
    double mTrailStopLossPips;

public:
    StartOfDayHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~StartOfDayHedge();

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
    virtual bool ShouldReset();
    virtual void Reset();
};

StartOfDayHedge::StartOfDayHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mTakeProfitPips = 0.0;
    mTrailStopLossPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayHedge>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<StartOfDayHedge, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayHedge, SingleTimeFrameEntryTradeRecord>(this);
}

StartOfDayHedge::~StartOfDayHedge()
{
}

void StartOfDayHedge::Run()
{
    EAHelper::Run<StartOfDayHedge>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool StartOfDayHedge::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayHedge>(this) && EAHelper::WithinTradingSession<StartOfDayHedge>(this);
}

void StartOfDayHedge::CheckSetSetup()
{
    mHasSetup = true;
}

void StartOfDayHedge::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void StartOfDayHedge::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<StartOfDayHedge>(this, deletePendingOrder, mStopTrading, error);
}

bool StartOfDayHedge::Confirmation()
{
    return Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart();
}

void StartOfDayHedge::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    // double takeProfit = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
        // takeProfit = entry + OrderHelper::PipsToRange(mTakeProfitPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
        // takeProfit = entry - OrderHelper::PipsToRange(mTakeProfitPips);
    }

    EAHelper::PlaceMarketOrder<StartOfDayHedge>(this, entry, stopLoss);
    mStopTrading = true;
}

void StartOfDayHedge::ManageCurrentPendingSetupTicket()
{
}

void StartOfDayHedge::ManageCurrentActiveSetupTicket()
{
}

bool StartOfDayHedge::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void StartOfDayHedge::ManagePreviousSetupTicket(int ticketIndex)
{
    mPreviousSetupTickets[ticketIndex].SelectIfOpen("Managing");

    double newSL = 0.0;
    if (OrderStopLoss() == mPreviousSetupTickets[ticketIndex].mOriginalStopLoss)
    {
        // instanly cut SL in half to limit losses to 0.5 RR
        if (SetupType() == OP_BUY)
        {
            newSL = OrderStopLoss() + (OrderHelper::PipsToRange(mStopLossPaddingPips) / 2);
            OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), clrNONE);
        }
        else if (SetupType() == OP_SELL)
        {
            newSL = OrderStopLoss() - (OrderHelper::PipsToRange(mStopLossPaddingPips) / 2);
            OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), clrNONE);
        }
    }
    else
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            RecordError(GetLastError());
            return;
        }

        double startingPrice = 0.0;

        // trail SL
        if (SetupType() == OP_BUY)
        {
            startingPrice = MathMax(OrderStopLoss(), OrderOpenPrice());
            if (currentTick.bid - startingPrice > OrderHelper::PipsToRange(mTrailStopLossPips))
            {
                double newSl = NormalizeDouble(currentTick.bid - (OrderHelper::PipsToRange(mTrailStopLossPips) / 2), Digits());
                OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), newSl, OrderTakeProfit(), OrderExpiration(), clrNONE);
            }
        }
        else if (SetupType() == OP_SELL)
        {
            startingPrice = MathMin(OrderStopLoss(), OrderOpenPrice());
            if (startingPrice - currentTick.bid > OrderHelper::PipsToRange(mTrailStopLossPips))
            {
                double newSl = NormalizeDouble(currentTick.bid + (OrderHelper::PipsToRange(mTrailStopLossPips) / 2), Digits());
                OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), newSl, OrderTakeProfit(), OrderExpiration(), clrNONE);
            }
        }
    }
}

void StartOfDayHedge::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StartOfDayHedge>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<StartOfDayHedge>(this);
}

void StartOfDayHedge::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StartOfDayHedge>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<StartOfDayHedge>(this, ticketIndex);
}

void StartOfDayHedge::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StartOfDayHedge>(this);
}

void StartOfDayHedge::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<StartOfDayHedge>(this, partialedTicket, newTicketNumber);
}

void StartOfDayHedge::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<StartOfDayHedge>(this, ticket, Period());
}

void StartOfDayHedge::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<StartOfDayHedge>(this, error, additionalInformation);
}

bool StartOfDayHedge::ShouldReset()
{
    return !EAHelper::WithinTradingSession<StartOfDayHedge>(this);
}

void StartOfDayHedge::Reset()
{
    mStopTrading = false;
    mHasSetup = false;
}