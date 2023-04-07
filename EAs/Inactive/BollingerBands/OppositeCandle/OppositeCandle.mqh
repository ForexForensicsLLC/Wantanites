//+------------------------------------------------------------------+
//|                                                    OppositeCandle.mqh |
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

class OppositeCandle : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
public:
    OppositeCandle(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~OppositeCandle();

    double UpperBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, shift); }
    double MiddleBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, shift); }
    double LowerBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, shift); }

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

OppositeCandle::OppositeCandle(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    EAHelper::FindSetPreviousAndCurrentSetupTickets<OppositeCandle>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<OppositeCandle, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<OppositeCandle, SingleTimeFrameEntryTradeRecord>(this);
}

OppositeCandle::~OppositeCandle()
{
}

void OppositeCandle::PreRun()
{
}

bool OppositeCandle::AllowedToTrade()
{
    return EAHelper::BelowSpread<OppositeCandle>(this) && EAHelper::WithinTradingSession<OppositeCandle>(this);
}

void OppositeCandle::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) < LowerBand(2) &&
            CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 2) < -0.15 &&
            CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mHasSetup = true;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 2) > UpperBand(2) &&
            CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 2) > 0.15 &&
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
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));
    }

    EAHelper::PlaceMarketOrder<OppositeCandle>(this, entry, stopLoss);
    mStopTrading = true;
}

void OppositeCandle::PreManageTickets()
{
}

void OppositeCandle::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void OppositeCandle::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    if (SetupType() == OP_BUY)
    {
        if (CurrentTick().Bid() > UpperBand(0))
        {
            ticket.Close();
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (CurrentTick().Ask() < LowerBand(0))
        {
            ticket.Close();
        }
    }
}

bool OppositeCandle::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void OppositeCandle::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void OppositeCandle::CheckCurrentSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<OppositeCandle>(this, ticket);
}

void OppositeCandle::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void OppositeCandle::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<OppositeCandle>(this, ticket);
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

bool OppositeCandle::ShouldReset()
{
    return !EAHelper::WithinTradingSession<OppositeCandle>(this);
}

void OppositeCandle::Reset()
{
    mStopTrading = false;
}