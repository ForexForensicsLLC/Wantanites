//+------------------------------------------------------------------+
//|                                                    PriceRange.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataObjects\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>

class PriceRange : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    int mFurthestThreshold;
    double mPipsFromOpen;

public:
    PriceRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~PriceRange();

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

PriceRange::PriceRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mFurthestThreshold = 0;
    mPipsFromOpen = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<PriceRange>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<PriceRange, SingleTimeFrameEntryTradeRecord>(this);
}

PriceRange::~PriceRange()
{
}

void PriceRange::PreRun()
{
}

bool PriceRange::AllowedToTrade()
{
    return EAHelper::BelowSpread<PriceRange>(this) && EAHelper::WithinTradingSession<PriceRange>(this);
}

void PriceRange::CheckSetSetup()
{
    int furthestHigh = EMPTY;
    int furthestLow = EMPTY;

    if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, mFurthestThreshold, 0, true, furthestHigh))
    {
        return;
    }

    if (furthestHigh <= 1)
    {
        mHasSetup = true;
        return;
    }

    if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, mFurthestThreshold, 0, true, furthestLow))
    {
        return;
    }

    if (furthestLow <= 1)
    {
        mHasSetup = true;
        return;
    }
}

void PriceRange::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void PriceRange::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<PriceRange>(this, deletePendingOrder, mStopTrading, error);
}

bool PriceRange::Confirmation()
{
    return true;
}

void PriceRange::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask() + OrderHelper::PipsToRange(mPipsFromOpen);
        stopLoss = CurrentTick().Ask() - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid() - OrderHelper::PipsToRange(mPipsFromOpen);
        stopLoss = CurrentTick().Bid() + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceStopOrder<PriceRange>(this, entry, stopLoss);
    mStopTrading = true;
}

void PriceRange::PreManageTickets()
{
}

void PriceRange::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void PriceRange::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool PriceRange::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void PriceRange::ManagePreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckTrailStopLossEveryXPips<PriceRange>(this, ticket, 100, 50);
}

void PriceRange::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void PriceRange::CheckPreviousSetupTicket(Ticket &ticket)
{
    // EAHelper::CheckPartialTicket<PriceRange>(this, ticket);
}

void PriceRange::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<PriceRange>(this, ticket);
}

void PriceRange::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void PriceRange::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<PriceRange>(this, ticket, Period());
}

void PriceRange::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<PriceRange>(this, error, additionalInformation);
}

bool PriceRange::ShouldReset()
{
    return !EAHelper::WithinTradingSession<PriceRange>(this);
}

void PriceRange::Reset()
{
    mStopTrading = false;
    InvalidateSetup(true);
    EAHelper::CloseAllPendingTickets<PriceRange>(this);
}