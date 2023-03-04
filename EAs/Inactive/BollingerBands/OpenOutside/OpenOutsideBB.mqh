//+------------------------------------------------------------------+
//|                                                    OpenOutside.mqh |
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

class OpenOutside : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    OpenOutside(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~OpenOutside();

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

OpenOutside::OpenOutside(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<OpenOutside>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<OpenOutside, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<OpenOutside, SingleTimeFrameEntryTradeRecord>(this);
}

OpenOutside::~OpenOutside()
{
}

void OpenOutside::Run()
{
    EAHelper::Run<OpenOutside>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool OpenOutside::AllowedToTrade()
{
    return EAHelper::BelowSpread<OpenOutside>(this) && EAHelper::WithinTradingSession<OpenOutside>(this);
}

void OpenOutside::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) < LowerBand(2) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) > LowerBand(1))
        {
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) > UpperBand(2) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) < UpperBand(1))
        {
            mHasSetup = true;
        }
    }
}

void OpenOutside::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void OpenOutside::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<OpenOutside>(this, deletePendingOrder, false, error);
}

bool OpenOutside::Confirmation()
{
    return true;
}

void OpenOutside::PlaceOrders()
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
        stopLoss = entry - OrderHelper::PipsToRange(mMinStopLossPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = entry + OrderHelper::PipsToRange(mMinStopLossPips + mMaxSpreadPips);
    }

    EAHelper::PlaceMarketOrder<OpenOutside>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void OpenOutside::ManageCurrentPendingSetupTicket()
{
}

void OpenOutside::ManageCurrentActiveSetupTicket()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (currentTick.bid > MiddleBand(0))
        {
            mCurrentSetupTicket.Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (currentTick.ask < MiddleBand(0))
        {
            mCurrentSetupTicket.Close();
        }
    }
}

bool OpenOutside::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void OpenOutside::ManagePreviousSetupTicket(int ticketIndex)
{
}

void OpenOutside::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<OpenOutside>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<OpenOutside>(this);
}

void OpenOutside::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<OpenOutside>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<OpenOutside>(this, ticketIndex);
}

void OpenOutside::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<OpenOutside>(this);
}

void OpenOutside::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<OpenOutside>(this, partialedTicket, newTicketNumber);
}

void OpenOutside::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<OpenOutside>(this, ticket, Period());
}

void OpenOutside::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<OpenOutside>(this, error, additionalInformation);
}

void OpenOutside::Reset()
{
}