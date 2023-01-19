//+------------------------------------------------------------------+
//|                                                    DowLiquidation.mqh |
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

class DowLiquidation : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinWickLength;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    DowLiquidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~DowLiquidation();

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

DowLiquidation::DowLiquidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMinWickLength = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<DowLiquidation>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<DowLiquidation, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<DowLiquidation, SingleTimeFrameEntryTradeRecord>(this);
}

DowLiquidation::~DowLiquidation()
{
}

void DowLiquidation::Run()
{
    EAHelper::Run<DowLiquidation>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool DowLiquidation::AllowedToTrade()
{
    return EAHelper::BelowSpread<DowLiquidation>(this) && EAHelper::WithinTradingSession<DowLiquidation>(this);
}

void DowLiquidation::CheckSetSetup()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    bool longEnoughWick = false;
    bool crossedOpenAfterLiquidaiton = false;

    if (mSetupType == OP_BUY)
    {
        // make sure we have a potential doji
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
            iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1))
        {
            longEnoughWick = currentTick.bid - iLow(mEntrySymbol, mEntryTimeFrame, 0) >= OrderHelper::PipsToRange(mMinWickLength);
            crossedOpenAfterLiquidaiton = currentTick.bid > iOpen(mEntrySymbol, mEntryTimeFrame, 0);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // make sure we have a potential doji
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
            iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1))
        {
            longEnoughWick = iHigh(mEntrySymbol, mEntryTimeFrame, 0) - currentTick.bid >= OrderHelper::PipsToRange(mMinWickLength);
            crossedOpenAfterLiquidaiton = currentTick.bid < iOpen(mEntrySymbol, mEntryTimeFrame, 0);
        }
    }

    if (longEnoughWick || crossedOpenAfterLiquidaiton)
    {
        mHasSetup = true;
    }
}

void DowLiquidation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void DowLiquidation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<DowLiquidation>(this, deletePendingOrder, mStopTrading, error);
}

bool DowLiquidation::Confirmation()
{
    return true;
}

void DowLiquidation::PlaceOrders()
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
        stopLoss = entry + OrderHelper::PipsToRange(mMinStopLossPips);
    }

    EAHelper::PlaceMarketOrder<DowLiquidation>(this, entry, stopLoss);
    mStopTrading = true;
}

void DowLiquidation::ManageCurrentPendingSetupTicket()
{
}

void DowLiquidation::ManageCurrentActiveSetupTicket()
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (openIndex >= 1)
    {
        mCurrentSetupTicket.Close();
    }

    EAHelper::MoveToBreakEvenAfterPips<DowLiquidation>(this, mCurrentSetupTicket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool DowLiquidation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<DowLiquidation>(this, ticket);
}

void DowLiquidation::ManagePreviousSetupTicket(int ticketIndex)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mPreviousSetupTickets[ticketIndex].OpenTime());
    if (openIndex >= 1)
    {
        mPreviousSetupTickets[ticketIndex].Close();
    }
}

void DowLiquidation::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<DowLiquidation>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<DowLiquidation>(this);
}

void DowLiquidation::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<DowLiquidation>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<DowLiquidation>(this, ticketIndex);
}

void DowLiquidation::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<DowLiquidation>(this);
}

void DowLiquidation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<DowLiquidation>(this, partialedTicket, newTicketNumber);
}

void DowLiquidation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<DowLiquidation>(this, ticket, Period());
}

void DowLiquidation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<DowLiquidation>(this, error, additionalInformation);
}

bool DowLiquidation::ShouldReset()
{
    return !EAHelper::WithinTradingSession<DowLiquidation>(this);
}

void DowLiquidation::Reset()
{
    mStopTrading = false;
    mHasSetup = false;
}