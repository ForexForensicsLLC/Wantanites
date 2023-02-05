//+------------------------------------------------------------------+
//|                                                    NasMorningBreak.mqh |
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

class NasMorningBreak : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    datetime mLastFractalTime;

public:
    NasMorningBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~NasMorningBreak();

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

NasMorningBreak::NasMorningBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mLastFractalTime = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<NasMorningBreak>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<NasMorningBreak, SingleTimeFrameEntryTradeRecord>(this);
}

NasMorningBreak::~NasMorningBreak()
{
}

void NasMorningBreak::PreRun()
{
}

bool NasMorningBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<NasMorningBreak>(this) && EAHelper::WithinTradingSession<NasMorningBreak>(this);
}

void NasMorningBreak::CheckSetSetup()
{
    double currentFractal = 0.0;
    double furthestBetweenFractal = 0.0;

    if (SetupType() == OP_BUY)
    {
        // go back to 3 so that we only consider fractals that are already created and not potential fractals based on our current candle
        for (int i = 3; i <= 15; i++)
        {
            currentFractal = iFractals(mEntrySymbol, mEntryTimeFrame, MODE_UPPER, i);
            if (currentFractal > 0)
            {
                if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, i, 1, false, furthestBetweenFractal))
                {
                    return;
                }

                if (furthestBetweenFractal < iHigh(mEntrySymbol, mEntryTimeFrame, i))
                {
                    mLastFractalTime = iTime(mEntrySymbol, mEntryTimeFrame, i);
                    mHasSetup = true;
                }
                else
                {
                    mStopTrading = true;
                }

                break;
            }
        }
    }
    else if (SetupType() == OP_SELL)
    {
        // go back to 3 so that we only consider fractals that are already created and not potential fractals based on our current candle
        for (int i = 3; i <= 15; i++)
        {
            currentFractal = iFractals(mEntrySymbol, mEntryTimeFrame, MODE_LOWER, i);
            if (currentFractal > 0)
            {
                if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, i, 1, false, furthestBetweenFractal))
                {
                    return;
                }

                if (furthestBetweenFractal > iLow(mEntrySymbol, mEntryTimeFrame, i))
                {
                    mLastFractalTime = iTime(mEntrySymbol, mEntryTimeFrame, i);
                    mHasSetup = true;
                }
                else
                {
                    mStopTrading = true;
                }

                break;
            }
        }
    }
}

void NasMorningBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (LastDay() != Day())
    {
        InvalidateSetup(true);
    }
}

void NasMorningBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<NasMorningBreak>(this, deletePendingOrder, mStopTrading, error);
    mLastFractalTime = 0;
}

bool NasMorningBreak::Confirmation()
{
    return true;
}

void NasMorningBreak::PlaceOrders()
{
    if (mLastFractalTime <= 0)
    {
        return;
    }

    int lastFractalIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLastFractalTime);

    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, lastFractalIndex) + OrderHelper::PipsToRange(mMaxSpreadPips);

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, lastFractalIndex, 0, true, stopLoss))
        {
            return;
        }

        stopLoss = MathMin(stopLoss, entry - OrderHelper::PipsToRange(mStopLossPaddingPips));
    }
    else if (SetupType() == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, lastFractalIndex);

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, lastFractalIndex, 0, true, stopLoss))
        {
            return;
        }

        stopLoss += OrderHelper::PipsToRange(mMaxSpreadPips);
        stopLoss = MathMax(stopLoss, entry + OrderHelper::PipsToRange(mStopLossPaddingPips));
    }

    EAHelper::PlaceStopOrder<NasMorningBreak>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);
    mStopTrading = true;
}

void NasMorningBreak::PreManageTickets()
{
}

void NasMorningBreak::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void NasMorningBreak::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, ticket.OpenTime());
    if (openIndex >= 1)
    {
        ticket.Close();
    }

    EAHelper::MoveToBreakEvenAfterPips<NasMorningBreak>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool NasMorningBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<NasMorningBreak>(this, ticket);
}

void NasMorningBreak::ManagePreviousSetupTicket(Ticket &ticket)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, ticket.OpenTime());
    if (openIndex >= 1)
    {
        ticket.Close();
    }
}

void NasMorningBreak::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void NasMorningBreak::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void NasMorningBreak::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<NasMorningBreak>(this, ticket);
}

void NasMorningBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void NasMorningBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<NasMorningBreak>(this, ticket, Period());
}

void NasMorningBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<NasMorningBreak>(this, error, additionalInformation);
}

bool NasMorningBreak::ShouldReset()
{
    return !EAHelper::WithinTradingSession<NasMorningBreak>(this);
}

void NasMorningBreak::Reset()
{
    mStopTrading = false;
    InvalidateSetup(true);
}