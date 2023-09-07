//+------------------------------------------------------------------+
//|                                                    EMACrossover.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Objects\Indicators\Candle\CandleStickTracker.mqh>

class EMACrossover : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    CandleStickTracker *mCST;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    EMACrossover(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, CandleStickTracker *&cst);
    ~EMACrossover();

    double FastEMA(int index) { return iMA(EntrySymbol(), EntryTimeFrame(), 9, 0, MODE_EMA, PRICE_CLOSE, index); }
    double SlowEMA(int index) { return iMA(EntrySymbol(), EntryTimeFrame(), 21, 0, MODE_EMA, PRICE_CLOSE, index); }

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

EMACrossover::EMACrossover(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, CandleStickTracker *&cst)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mCST = cst;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<EMACrossover>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<EMACrossover, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<EMACrossover, SingleTimeFrameEntryTradeRecord>(this);
}

EMACrossover::~EMACrossover()
{
}

void EMACrossover::PreRun()
{
}

bool EMACrossover::AllowedToTrade()
{
    return EARunHelper::BelowSpread<EMACrossover>(this) && EARunHelper::WithinTradingSession<EMACrossover>(this);
}

void EMACrossover::CheckSetSetup()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (SetupType() == SignalType::Bullish)
    {
        if (FastEMA(1) > SlowEMA(1) && FastEMA(2) <= SlowEMA(2))
        {
            mHasSetup = true;
        }
    }
    else if (SetupType() == SignalType::Bearish)
    {
        if (FastEMA(1) < SlowEMA(1) && FastEMA(2) >= SlowEMA(2))
        {
            mHasSetup = true;
        }
    }
}

void EMACrossover::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void EMACrossover::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<EMACrossover>(this, deletePendingOrder, mStopTrading, error);
}

bool EMACrossover::Confirmation()
{
    return true;
}

void EMACrossover::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        stopLoss = entry - PipConverter::PipsToPoints(mMinStopLossPips);
        takeProfit = entry + (MathAbs(entry - stopLoss) * 3);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        stopLoss = entry + PipConverter::PipsToPoints(mMinStopLossPips);
        takeProfit = entry - (MathAbs(entry - stopLoss) * 3);
    }

    bool canLose = MathRand() % 11 == 0;
    if (canLose)
    {
        EAOrderHelper::PlaceMarketOrder<EMACrossover>(this, entry, stopLoss);
    }
    else if (EASetupHelper::TradeWillWin<EMACrossover>(this, iTime(EntrySymbol(), EntryTimeFrame(), 0), stopLoss, takeProfit))
    {
        EAOrderHelper::PlaceMarketOrder<EMACrossover>(this, entry, stopLoss);
    }

    InvalidateSetup(false);
}

void EMACrossover::PreManageTickets()
{
}

void EMACrossover::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void EMACrossover::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<EMACrossover>(this, ticket);
}

bool EMACrossover::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void EMACrossover::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void EMACrossover::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void EMACrossover::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void EMACrossover::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<EMACrossover>(this, ticket);
}

void EMACrossover::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EARecordHelper::RecordPartialTradeRecord<EMACrossover>(this, partialedTicket, newTicketNumber);
}

void EMACrossover::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<EMACrossover>(this, ticket);
}

void EMACrossover::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<EMACrossover>(this, methodName, error, additionalInformation);
}

bool EMACrossover::ShouldReset()
{
    return false;
}

void EMACrossover::Reset()
{
}