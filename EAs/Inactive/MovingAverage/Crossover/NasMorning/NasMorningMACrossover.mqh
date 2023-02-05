//+------------------------------------------------------------------+
//|                                                    NasMorningCrossover.mqh |
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

class NasMorningCrossover : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

public:
    NasMorningCrossover(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~NasMorningCrossover();

    double FastEMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 5, 0, MODE_EMA, PRICE_CLOSE, index); }
    double SlowEMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 10, 0, MODE_EMA, PRICE_CLOSE, index); }

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void PreRun();
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

NasMorningCrossover::NasMorningCrossover(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<NasMorningCrossover>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<NasMorningCrossover, SingleTimeFrameEntryTradeRecord>(this);
}

NasMorningCrossover::~NasMorningCrossover()
{
}

void NasMorningCrossover::PreRun()
{
}

bool NasMorningCrossover::AllowedToTrade()
{
    return EAHelper::BelowSpread<NasMorningCrossover>(this) && EAHelper::WithinTradingSession<NasMorningCrossover>(this);
}

void NasMorningCrossover::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        if (FastEMA(2) < SlowEMA(2) && FastEMA(1) >= SlowEMA(1))
        {
            mHasSetup = true;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (FastEMA(2) > SlowEMA(2) && FastEMA(1) <= SlowEMA(1))
        {
            mHasSetup = true;
        }
    }
}

void NasMorningCrossover::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void NasMorningCrossover::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<NasMorningCrossover>(this, deletePendingOrder, mStopTrading, error);
}

bool NasMorningCrossover::Confirmation()
{
    return true;
}

void NasMorningCrossover::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

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

    EAHelper::PlaceMarketOrder<NasMorningCrossover>(this, entry, stopLoss);
    mStopTrading = true;
}

void NasMorningCrossover::ManageCurrentPendingSetupTicket()
{
}

void NasMorningCrossover::ManageCurrentActiveSetupTicket()
{
    // EAHelper::MoveToBreakEvenAfterPips<NasMorningCrossover>(this, mCurrentSetupTicket, mPipsToWaitBeforeBE, mBEAdditionalPips);

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        if (FastEMA(1) < SlowEMA(1))
        {
            mCurrentSetupTicket.Close();
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (FastEMA(1) > SlowEMA(1))
        {
            mCurrentSetupTicket.Close();
        }
    }
}

bool NasMorningCrossover::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return EAHelper::TicketStopLossIsMovedToBreakEven<NasMorningCrossover>(this, ticket);
    return false;
}

void NasMorningCrossover::ManagePreviousSetupTicket(int ticketIndex)
{
    // EAHelper::CloseTicketIfPastTime<NasMorningCrossover>(this, mPreviousSetupTickets[ticketIndex], mCloseHour, mCloseMinute);
    // int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mPreviousSetupTickets[ticketIndex].OpenTime());
    // if (openIndex >= 1)
    // {
    //     mPreviousSetupTickets[ticketIndex].Close();
    // }
}

void NasMorningCrossover::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<NasMorningCrossover>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<NasMorningCrossover>(this);
}

void NasMorningCrossover::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<NasMorningCrossover>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<NasMorningCrossover>(this, ticketIndex);
}

void NasMorningCrossover::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<NasMorningCrossover>(this);
}

void NasMorningCrossover::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void NasMorningCrossover::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<NasMorningCrossover>(this, ticket, Period());
}

void NasMorningCrossover::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<NasMorningCrossover>(this, error, additionalInformation);
}

bool NasMorningCrossover::ShouldReset()
{
    return !EAHelper::WithinTradingSession<NasMorningCrossover>(this);
}

void NasMorningCrossover::Reset()
{
    mStopTrading = false;
    InvalidateSetup(true);
}