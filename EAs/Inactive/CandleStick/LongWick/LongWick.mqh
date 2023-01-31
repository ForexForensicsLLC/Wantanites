//+------------------------------------------------------------------+
//|                                                    LongWick.mqh |
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

class LongWick : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinWickLength;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    datetime mLastEntryCandleTime;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    LongWick(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~LongWick();

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

LongWick::LongWick(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMinWickLength = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LongWick>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LongWick, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LongWick, SingleTimeFrameEntryTradeRecord>(this);
}

LongWick::~LongWick()
{
}

void LongWick::PreRun()
{
}

bool LongWick::AllowedToTrade()
{
    return EAHelper::BelowSpread<LongWick>(this) && EAHelper::WithinTradingSession<LongWick>(this);
}

void LongWick::CheckSetSetup()
{
    double wickLength = 0.0;
    if (SetupType() == OP_BUY)
    {
        if (CurrentTick().Bid() > iOpen(mEntrySymbol, mEntryTimeFrame, 0))
        {
            return;
        }

        wickLength = CurrentTick().Bid() - iLow(mEntrySymbol, mEntryTimeFrame, 0);
    }
    else if (SetupType() == OP_SELL)
    {
        if (CurrentTick().Bid() < iOpen(mEntrySymbol, mEntryTimeFrame, 0))
        {
            return;
        }

        wickLength = iHigh(mEntrySymbol, mEntryTimeFrame, 0) - CurrentTick().Bid();
    }

    if (wickLength >= OrderHelper::PipsToRange(mMinWickLength))
    {
        mHasSetup = true;
    }
}

void LongWick::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void LongWick::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<LongWick>(this, deletePendingOrder, mStopTrading, error);
}

bool LongWick::Confirmation()
{
    return true;
}

void LongWick::PlaceOrders()
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

    EAHelper::PlaceMarketOrder<LongWick>(this, entry, stopLoss);
    mStopTrading = true;
}

void LongWick::ManageCurrentPendingSetupTicket()
{
}

void LongWick::ManageCurrentActiveSetupTicket()
{
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (entryIndex > 0)
    {
        if (SetupType() == OP_BUY)
        {
            if (CurrentTick().Bid() > mCurrentSetupTicket.OpenPrice() &&
                iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1))
            {
                mCurrentSetupTicket.Close();
            }
        }
        else if (SetupType() == OP_SELL)
        {
            if (CurrentTick().Bid() < mCurrentSetupTicket.OpenPrice() &&
                iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1))
            {
                mCurrentSetupTicket.Close();
            }
        }
    }

    EAHelper::MoveToBreakEvenAfterPips<LongWick>(this, mCurrentSetupTicket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool LongWick::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LongWick>(this, ticket);
}

void LongWick::ManagePreviousSetupTicket(int ticketIndex)
{
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mPreviousSetupTickets[ticketIndex].OpenTime());
    if (entryIndex == 0)
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1))
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }
}

void LongWick::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LongWick>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<LongWick>(this);
}

void LongWick::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LongWick>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<LongWick>(this, ticketIndex);
}

void LongWick::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LongWick>(this);
}

void LongWick::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void LongWick::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LongWick>(this, ticket, Period());
}

void LongWick::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LongWick>(this, error, additionalInformation);
}

bool LongWick::ShouldReset()
{
    return !EAHelper::WithinTradingSession<LongWick>(this);
}

void LongWick::Reset()
{
    InvalidateSetup(false);
    mStopTrading = false;
}