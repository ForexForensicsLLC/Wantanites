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

class DowLiquidation : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinWickLength;

public:
    DowLiquidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~DowLiquidation();

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

DowLiquidation::DowLiquidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                               double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter,
         errorCSVRecordWriter)
{
    mMinWickLength = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<DowLiquidation>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<DowLiquidation, SingleTimeFrameEntryTradeRecord>(this);
}

DowLiquidation::~DowLiquidation()
{
}

void DowLiquidation::PreRun()
{
}

bool DowLiquidation::AllowedToTrade()
{
    return EAHelper::BelowSpread<DowLiquidation>(this) && EAHelper::WithinTradingSession<DowLiquidation>(this);
}

void DowLiquidation::CheckSetSetup()
{
    bool longEnoughWick = false;
    bool crossedOpenAfterLiquidaiton = false;

    if (SetupType() == OP_BUY)
    {
        // make sure we have a potential doji
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
            iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1))
        {
            longEnoughWick = CurrentTick().Bid() - iLow(mEntrySymbol, mEntryTimeFrame, 0) >= OrderHelper::PipsToRange(mMinWickLength);
            crossedOpenAfterLiquidaiton = CurrentTick().Bid() > iOpen(mEntrySymbol, mEntryTimeFrame, 0);
        }
    }
    else if (SetupType() == OP_SELL)
    {
        // make sure we have a potential doji
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
            iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1))
        {
            longEnoughWick = iHigh(mEntrySymbol, mEntryTimeFrame, 0) - CurrentTick().Bid() >= OrderHelper::PipsToRange(mMinWickLength);
            crossedOpenAfterLiquidaiton = CurrentTick().Bid() < iOpen(mEntrySymbol, mEntryTimeFrame, 0);
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