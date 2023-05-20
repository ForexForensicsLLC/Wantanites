//+------------------------------------------------------------------+
//|                                                    WickBand.mqh |
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

class WickBand : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinWickLength;

    double mLastBid;

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
    WickBand(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~WickBand();

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

WickBand::WickBand(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMinWickLength = 0.0;

    mLastBid = 0.0;

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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<WickBand>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<WickBand, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<WickBand, SingleTimeFrameEntryTradeRecord>(this);
}

WickBand::~WickBand()
{
}

void WickBand::Run()
{
    EAHelper::Run<WickBand>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool WickBand::AllowedToTrade()
{
    return EAHelper::BelowSpread<WickBand>(this) && EAHelper::WithinTradingSession<WickBand>(this);
}

void WickBand::CheckSetSetup()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    if (mLastBid > 0)
    {
        double entryBand = 0.0;
        bool wickedEntryBand = false;
        bool hasMinWickLength = false;
        bool tickCrossedBand = false;

        if (mSetupType == OP_BUY)
        {
            entryBand = LowerBand(0);

            wickedEntryBand = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > entryBand && iLow(mEntrySymbol, mEntryTimeFrame, 0) < entryBand;
            hasMinWickLength = currentTick.bid - iLow(mEntrySymbol, mEntryTimeFrame, 0) >= OrderHelper::PipsToRange(mMinWickLength);
            tickCrossedBand = mLastBid <= entryBand && currentTick.bid >= entryBand;
        }
        else if (mSetupType == OP_SELL)
        {
            entryBand = UpperBand(0);

            wickedEntryBand = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < entryBand && iHigh(mEntrySymbol, mEntryTimeFrame, 0) > entryBand;
            hasMinWickLength = iHigh(mEntrySymbol, mEntryTimeFrame, 0) - currentTick.bid >= OrderHelper::PipsToRange(mMinWickLength);
            tickCrossedBand = mLastBid >= entryBand && currentTick.bid < entryBand;
        }

        if (wickedEntryBand && hasMinWickLength && tickCrossedBand)
        {
            mHasSetup = true;
        }
    }

    mLastBid = currentTick.bid;
}

void WickBand::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void WickBand::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<WickBand>(this, deletePendingOrder, false, error);
}

bool WickBand::Confirmation()
{
    return true;
}

void WickBand::PlaceOrders()
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
        stopLoss = MathMin(entry - OrderHelper::PipsToRange(mMinStopLossPips), iLow(mEntrySymbol, mEntryTimeFrame, 0));
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = MathMax(entry + OrderHelper::PipsToRange(mMinStopLossPips), iHigh(mEntrySymbol, mEntryTimeFrame, 0));
    }

    EAHelper::PlaceMarketOrder<WickBand>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }
}

void WickBand::ManageCurrentPendingSetupTicket()
{
}

void WickBand::ManageCurrentActiveSetupTicket()
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (openIndex >= 1)
    {
        mCurrentSetupTicket.Close();
    }
}

bool WickBand::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void WickBand::ManagePreviousSetupTicket(int ticketIndex)
{
}

void WickBand::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickBand>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<WickBand>(this);
}

void WickBand::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickBand>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<WickBand>(this, ticketIndex);
}

void WickBand::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<WickBand>(this);
}

void WickBand::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickBand>(this, partialedTicket, newTicketNumber);
}

void WickBand::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<WickBand>(this, ticket, Period());
}

void WickBand::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<WickBand>(this, error, additionalInformation);
}

void WickBand::Reset()
{
}