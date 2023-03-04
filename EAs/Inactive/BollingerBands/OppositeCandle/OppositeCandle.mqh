//+------------------------------------------------------------------+
//|                                                    OppositeCandle.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class OppositeCandle : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

public:
    OppositeCandle(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~OppositeCandle();

    double UpperBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, shift); }
    double MiddleBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, shift); }
    double LowerBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, shift); }

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

OppositeCandle::OppositeCandle(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mBarCount = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<OppositeCandle>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<OppositeCandle, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<OppositeCandle, SingleTimeFrameEntryTradeRecord>(this);
}

OppositeCandle::~OppositeCandle()
{
}

void OppositeCandle::Run()
{
    EAHelper::Run<OppositeCandle>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool OppositeCandle::AllowedToTrade()
{
    return EAHelper::BelowSpread<OppositeCandle>(this) && EAHelper::WithinTradingSession<OppositeCandle>(this);
}

void OppositeCandle::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) < LowerBand(2) &&
            CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) > UpperBand(2) &&
            CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mHasSetup = true;
        }
    }
}

void OppositeCandle::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void OppositeCandle::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<OppositeCandle>(this, deletePendingOrder, false, error);
}

bool OppositeCandle::Confirmation()
{
    return true;
}

void OppositeCandle::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

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
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));
    }

    EAHelper::PlaceMarketOrder<OppositeCandle>(this, entry, stopLoss);
    mStopTrading = true;
}

void OppositeCandle::ManageCurrentPendingSetupTicket()
{
}

void OppositeCandle::ManageCurrentActiveSetupTicket()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (currentTick.bid > UpperBand(0))
        {
            mCurrentSetupTicket.Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (currentTick.ask < LowerBand(0))
        {
            mCurrentSetupTicket.Close();
        }
    }
}

bool OppositeCandle::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void OppositeCandle::ManagePreviousSetupTicket(int ticketIndex)
{
}

void OppositeCandle::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<OppositeCandle>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<OppositeCandle>(this);
}

void OppositeCandle::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<OppositeCandle>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<OppositeCandle>(this, ticketIndex);
}

void OppositeCandle::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<OppositeCandle>(this);
}

void OppositeCandle::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<OppositeCandle>(this, partialedTicket, newTicketNumber);
}

void OppositeCandle::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<OppositeCandle>(this, ticket, Period());
}

void OppositeCandle::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<OppositeCandle>(this, error, additionalInformation);
}

void OppositeCandle::Reset()
{
    mStopTrading = false;
}