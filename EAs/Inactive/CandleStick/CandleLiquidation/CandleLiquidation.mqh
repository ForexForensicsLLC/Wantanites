//+------------------------------------------------------------------+
//|                                                    CandleLiquidation.mqh |
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

void CandleLiquidation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
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

void CandleLiquidation::ManageCurrentPendingSetupTicket()
{
}

void CandleLiquidation::ManageCurrentActiveSetupTicket()
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (openIndex >= 1)
    {
        mCurrentSetupTicket.Close();
    }

    EAHelper::MoveToBreakEvenAfterPips<CandleLiquidation>(this, mCurrentSetupTicket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool CandleLiquidation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<CandleLiquidation>(this, ticket);
}

void CandleLiquidation::ManagePreviousSetupTicket(int ticketIndex)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mPreviousSetupTickets[ticketIndex].OpenTime());
    if (openIndex >= 1)
    {
        mPreviousSetupTickets[ticketIndex].Close();
    }
}

void CandleLiquidation::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleLiquidation>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<CandleLiquidation>(this);
}

void CandleLiquidation::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleLiquidation>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<CandleLiquidation>(this, ticketIndex);
}

void CandleLiquidation::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<CandleLiquidation>(this);
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