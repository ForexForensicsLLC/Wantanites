//+------------------------------------------------------------------+
//|                                                    CandleLiquidation.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class CandleLiquidation : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinWickLength;

public:
    CandleLiquidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                      CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                      CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~CandleLiquidation();

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

CandleLiquidation::CandleLiquidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                                     double riskPercent,
                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter,
         errorCSVRecordWriter)
{
    mMinWickLength = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<CandleLiquidation>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<CandleLiquidation, SingleTimeFrameEntryTradeRecord>(this);
}

CandleLiquidation::~CandleLiquidation()
{
}

void CandleLiquidation::PreRun()
{
}

bool CandleLiquidation::AllowedToTrade()
{
    return EAHelper::BelowSpread<CandleLiquidation>(this) && EAHelper::WithinTradingSession<CandleLiquidation>(this);
}

void CandleLiquidation::CheckSetSetup()
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

void CandleLiquidation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void CandleLiquidation::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<CandleLiquidation>(this, deletePendingOrder, mStopTrading, error);
}

bool CandleLiquidation::Confirmation()
{
    return true;
}

void CandleLiquidation::PlaceOrders()
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

    EAHelper::PlaceMarketOrder<CandleLiquidation>(this, entry, stopLoss);
    mStopTrading = true;
}

void CandleLiquidation::PreManageTickets()
{
}

void CandleLiquidation::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void CandleLiquidation::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, ticket.OpenTime());
    if (openIndex >= 1)
    {
        ticket.Close();
    }

    EAHelper::MoveToBreakEvenAfterPips<CandleLiquidation>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool CandleLiquidation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<CandleLiquidation>(this, ticket);
}

void CandleLiquidation::ManagePreviousSetupTicket(Ticket &ticket)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, ticket.OpenTime());
    if (openIndex >= 1)
    {
        ticket.Close();
    }
}

void CandleLiquidation::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void CandleLiquidation::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void CandleLiquidation::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<CandleLiquidation>(this, ticket);
}

void CandleLiquidation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void CandleLiquidation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<CandleLiquidation>(this, ticket, Period());
}

void CandleLiquidation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<CandleLiquidation>(this, error, additionalInformation);
}

bool CandleLiquidation::ShouldReset()
{
    return !EAHelper::WithinTradingSession<CandleLiquidation>(this);
}

void CandleLiquidation::Reset()
{
    mStopTrading = false;
    mHasSetup = false;
}