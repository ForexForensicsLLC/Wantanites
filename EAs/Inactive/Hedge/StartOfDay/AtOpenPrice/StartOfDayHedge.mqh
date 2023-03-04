//+------------------------------------------------------------------+
//|                                                    StartOfDayHedge.mqh |
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
#include <Wantanites\Framework\Symbols\NASDAQ.mqh>

class StartOfDayHedge : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mTrailStopLossPips;
    double mCloseAllNegativeTickets;

public:
    StartOfDayHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~StartOfDayHedge();

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

StartOfDayHedge::StartOfDayHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTrailStopLossPips = 0.0;
    mCloseAllNegativeTickets = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayHedge>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayHedge, SingleTimeFrameEntryTradeRecord>(this);
}

StartOfDayHedge::~StartOfDayHedge()
{
}

void StartOfDayHedge::PreRun()
{
}

bool StartOfDayHedge::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayHedge>(this) && EAHelper::WithinTradingSession<StartOfDayHedge>(this);
}

void StartOfDayHedge::CheckSetSetup()
{
    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        mHasSetup = true;
    }
}

void StartOfDayHedge::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllNegativeTickets && mPreviousSetupTickets.Size() <= 1)
    {
        mCloseAllNegativeTickets = false;
    }
}

void StartOfDayHedge::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<StartOfDayHedge>(this, deletePendingOrder, mStopTrading, error);
}

bool StartOfDayHedge::Confirmation()
{
    return true;
}

void StartOfDayHedge::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double lotSize = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    if (mPreviousSetupTickets.Size() > 0)
    {
        double currentDrawdown = 0.0;
        double currentLots = 0.0;
        double lossesToCover = 0.0;
        Print("Tickets: ", mPreviousSetupTickets.Size());
        for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
        {
            mPreviousSetupTickets[i].SelectIfOpen("Adding drawdown");
            if (OrderType() == SetupType())
            {
                currentDrawdown += OrderProfit();
                currentLots += OrderLots();
            }
        }

        Print("Current Drawdown: ", currentDrawdown, ", Current Lots: ", currentLots, ", Losses To Cover: ", lossesToCover);
        double valuePerPipPerLot = NASDAQ::PipValuePerLot();
        double equityTarget = (AccountBalance() * 0.001) + MathAbs(currentDrawdown);
        double profitPerPip = equityTarget / mTrailStopLossPips * 2;
        lotSize = equityTarget / valuePerPipPerLot / mTrailStopLossPips * 2;
        Print("Value / Pip / Lot: ", valuePerPipPerLot, ", Pip Target: ", mTrailStopLossPips * 2, ", Equity Target: ", equityTarget, ", Profit / Pip: ", profitPerPip,
              ", Lots: ", lotSize);
    }

    EAHelper::PlaceMarketOrder<StartOfDayHedge>(this, entry, stopLoss, lotSize);
    mStopTrading = true;
}

void StartOfDayHedge::PreManageTickets()
{
    // only need to worry about closing tickets if we have more than 1
    if (mPreviousSetupTickets.Size() <= 1)
    {
        return;
    }

    double runningProfit = 0.0;
    double runningLargestProfit = 0.0;
    bool largestProfitTrailed = false;
    bool allTicketsTrailed = true;
    for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
    {
        mPreviousSetupTickets[i].SelectIfOpen("Adding drawdown");
        if (OrderType() == SetupType())
        {
            runningProfit += OrderProfit();
            if (OrderProfit() > runningLargestProfit)
            {
                runningLargestProfit = OrderProfit();
                if (OrderType() == OP_BUY)
                {
                    largestProfitTrailed = OrderStopLoss() > OrderOpenPrice();
                }
                else if (OrderType() == OP_SELL)
                {
                    largestProfitTrailed = OrderStopLoss() < OrderOpenPrice();
                }
            }

            if (allTicketsTrailed)
            {
                if (OrderType() == OP_BUY && OrderStopLoss() < OrderOpenPrice())
                {
                    allTicketsTrailed = false;
                }
                else if (OrderType() == OP_SELL && OrderStopLoss() > OrderOpenPrice())
                {
                    allTicketsTrailed = false;
                }
            }
        }
    }

    if (!allTicketsTrailed && runningProfit > 0.0 && largestProfitTrailed)
    {
        mCloseAllNegativeTickets = true;
    }
}

void StartOfDayHedge::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void StartOfDayHedge::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool StartOfDayHedge::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
    // return EAHelper::TicketStopLossIsMovedToBreakEven<StartOfDayHedge>(this, ticket);
}

void StartOfDayHedge::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllNegativeTickets && ticket.Profit() < 0)
    {
        ticket.Close();
        return;
    }

    EAHelper::MoveToBreakEvenAfterPips<StartOfDayHedge>(this, ticket, mTrailStopLossPips * 2);
    // EAHelper::CheckPartialTicket<StartOfDayHedge>(this, ticket);
    EAHelper::CheckTrailStopLossEveryXPips<StartOfDayHedge>(this, ticket, mTrailStopLossPips * 2, mTrailStopLossPips);
}

void StartOfDayHedge::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void StartOfDayHedge::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void StartOfDayHedge::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StartOfDayHedge>(this, ticket);
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

    EAHelper::CloseAllCurrentAndPendingTickets<StartOfDayHedge>(this);
}