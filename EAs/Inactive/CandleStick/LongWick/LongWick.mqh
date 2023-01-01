//+------------------------------------------------------------------+
//|                                                    LongWick.mqh |
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

class LongWick : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinWickLength;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    datetime mLastEntryCandleTime;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    LongWick(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~LongWick();

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

LongWick::LongWick(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMinWickLength = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LongWick>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LongWick, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LongWick, SingleTimeFrameEntryTradeRecord>(this);
}

LongWick::~LongWick()
{
}

void LongWick::Run()
{
    EAHelper::Run<LongWick>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool LongWick::AllowedToTrade()
{
    return EAHelper::BelowSpread<LongWick>(this) && EAHelper::WithinTradingSession<LongWick>(this);
}

void LongWick::CheckSetSetup()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    // if (mLastEntryCandleTime > 0)
    // {
    //     int lastEntryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLastEntryCandleTime);
    //     if (lastEntryCandleIndex <= 0)
    //     {
    //         return;
    //     }
    // }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double wickLength = 0.0;
    if (mSetupType == OP_BUY)
    {
        // need this check or else the wick length check will pass for most bullish candles since it will take into account their body
        if (currentTick.bid > iOpen(mEntrySymbol, mEntryTimeFrame, 0))
        {
            return;
        }

        wickLength = currentTick.bid - iLow(mEntrySymbol, mEntryTimeFrame, 0);
    }
    else if (mSetupType == OP_SELL)
    {
        // need this check or else the wick length check will pass for most bearish candles since it will take into account their body
        if (currentTick.bid < iOpen(mEntrySymbol, mEntryTimeFrame, 0))
        {
            return;
        }

        wickLength = iHigh(mEntrySymbol, mEntryTimeFrame, 0) - currentTick.bid;
    }

    if (wickLength >= OrderHelper::PipsToRange(mMinWickLength))
    {
        mHasSetup = true;
    }
}

void LongWick::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void LongWick::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<LongWick>(this, deletePendingOrder, mStopTrading, error);
}

bool LongWick::Confirmation()
{
    return true;
}

void LongWick::PlaceOrders()
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
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 0);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 0) + OrderHelper::PipsToRange(mMaxSpreadPips);
    }

    EAHelper::PlaceMarketOrder<LongWick>(this, entry, stopLoss);
    mLastEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);

    InvalidateSetup(false);
}

void LongWick::ManageCurrentPendingSetupTicket()
{
}

void LongWick::ManageCurrentActiveSetupTicket()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (openIndex >= 2)
    {
        bool withinStopLoss = false;
        if (mSetupType == OP_BUY)
        {
            withinStopLoss = currentTick.bid <= mCurrentSetupTicket.OpenPrice();
        }
        else if (mSetupType == OP_SELL)
        {
            withinStopLoss = currentTick.ask >= mCurrentSetupTicket.OpenPrice();
        }

        if (withinStopLoss)
        {
            mCurrentSetupTicket.Close();
            return;
        }
        else
        {
            EAHelper::MoveTicketToBreakEven<LongWick>(this, mCurrentSetupTicket);
        }
    }
}

bool LongWick::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LongWick>(this, ticket);
}

void LongWick::ManagePreviousSetupTicket(int ticketIndex)
{
    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }
}

void LongWick::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LongWick>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<LongWick>(this);
}

void LongWick::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LongWick>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<LongWick>(this, ticketIndex);
}

void LongWick::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LongWick>(this);
}

void LongWick::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LongWick>(this, partialedTicket, newTicketNumber);
}

void LongWick::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LongWick>(this, ticket, Period());
}

void LongWick::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LongWick>(this, error, additionalInformation);
}

void LongWick::Reset()
{
}