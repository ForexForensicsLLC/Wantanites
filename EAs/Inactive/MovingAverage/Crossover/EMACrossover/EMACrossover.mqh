//+------------------------------------------------------------------+
//|                                                    EMACrossover.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\EA\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>

class EMACrossover : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    EMACrossover(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~EMACrossover();

    double FastEMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 25, 0, MODE_EMA, PRICE_CLOSE, index); }
    double SlowEMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index); }

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

EMACrossover::EMACrossover(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EMACrossover>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<EMACrossover, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EMACrossover, SingleTimeFrameEntryTradeRecord>(this);
}

EMACrossover::~EMACrossover()
{
}

void EMACrossover::Run()
{
    EAHelper::Run<EMACrossover>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool EMACrossover::AllowedToTrade()
{
    return EAHelper::BelowSpread<EMACrossover>(this) && EAHelper::WithinTradingSession<EMACrossover>(this);
}

void EMACrossover::CheckSetSetup()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (FastEMA(1) > SlowEMA(1) && FastEMA(2) <= SlowEMA(2))
        {
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
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

void EMACrossover::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<EMACrossover>(this, deletePendingOrder, mStopTrading, error);
}

bool EMACrossover::Confirmation()
{
    return true;
}

void EMACrossover::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = entry - OrderHelper::PipsToRange(mMinStopLossPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = entry + OrderHelper::PipsToRange(mMinStopLossPips + mMaxSpreadPips);
    }

    EAHelper::PlaceMarketOrder<EMACrossover>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void EMACrossover::ManageCurrentPendingSetupTicket()
{
}

void EMACrossover::ManageCurrentActiveSetupTicket()
{
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (entryIndex <= 0)
    {
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (FastEMA(0) < SlowEMA(0) && currentTick.bid > mCurrentSetupTicket.OpenPrice())
        {
            mCurrentSetupTicket.Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (FastEMA(0) > SlowEMA(0) && currentTick.ask < mCurrentSetupTicket.OpenPrice())
        {
            mCurrentSetupTicket.Close();
        }
    }
}

bool EMACrossover::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void EMACrossover::ManagePreviousSetupTicket(int ticketIndex)
{
}

void EMACrossover::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EMACrossover>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<EMACrossover>(this);
}

void EMACrossover::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EMACrossover>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<EMACrossover>(this, ticketIndex);
}

void EMACrossover::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<EMACrossover>(this);
}

void EMACrossover::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<EMACrossover>(this, partialedTicket, newTicketNumber);
}

void EMACrossover::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EMACrossover>(this, ticket, Period());
}

void EMACrossover::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EMACrossover>(this, error, additionalInformation);
}

void EMACrossover::Reset()
{
    mStopTrading = false;
    InvalidateSetup(true);
}