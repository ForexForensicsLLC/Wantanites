//+------------------------------------------------------------------+
//|                                                    ImpulseReversal.mqh |
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

#include <Wantanites\Framework\Objects\PriceGridTracker.mqh>
#include <Wantanites\Framework\Symbols\EURUSD.mqh>

class ImpulseReversal : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinPercentChange;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    double mMinEquityDrawDown;

public:
    ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~ImpulseReversal();

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
    virtual void Reset();
};

ImpulseReversal::ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMinPercentChange = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mMinEquityDrawDown = 0;
    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseReversal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseReversal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseReversal, SingleTimeFrameEntryTradeRecord>(this);
}

ImpulseReversal::~ImpulseReversal()
{
    Print("Magic Number: ", MagicNumber(), ", Min Equity DD: ", mMinEquityDrawDown);
}

void ImpulseReversal::PreRun()
{
}

bool ImpulseReversal::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseReversal>(this) && EAHelper::WithinTradingSession<ImpulseReversal>(this);
}

void ImpulseReversal::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    bool hasImbalance = false;
    bool hasMinPercentChange = false;

    if (SetupType() == OP_BUY)
    {
        for (int i = 2; i <= 4; i++)
        {
            if (CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i))
            {
                hasImbalance = true;
            }

            if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mMinPercentChange))
            {
                hasMinPercentChange = true;
            }
        }

        if (!hasImbalance || !hasMinPercentChange)
        {
            return;
        }

        mHasSetup = true;
    }
    else if (SetupType() == OP_SELL)
    {
        for (int i = 2; i <= 4; i++)
        {
            if (CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i))
            {
                hasImbalance = true;
            }

            if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mMinPercentChange))
            {
                hasMinPercentChange = true;
            }
        }

        if (!hasImbalance || !hasMinPercentChange)
        {
            return;
        }

        mHasSetup = true;
    }
}

void ImpulseReversal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void ImpulseReversal::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseReversal>(this, deletePendingOrder, mStopTrading, error);
}

bool ImpulseReversal::Confirmation()
{
    bool hasTicket = !mCurrentSetupTicket.IsEmpty();
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return hasTicket;
    }

    return false;
}

void ImpulseReversal::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = CurrentTick().Ask();
    }
    else if (mSetupType == OP_SELL)
    {
        entry = CurrentTick().Bid();
    }

    EAHelper::PlaceMarketOrder<ImpulseReversal>(this, entry, stopLoss, lotSize);
}

void ImpulseReversal::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void ImpulseReversal::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool ImpulseReversal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void ImpulseReversal::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void ImpulseReversal::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void ImpulseReversal::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void ImpulseReversal::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseReversal>(this);
}

void ImpulseReversal::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseReversal>(this, partialedTicket, newTicketNumber);
}

void ImpulseReversal::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseReversal>(this, ticket, Period());
}

void ImpulseReversal::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseReversal>(this, error, additionalInformation);
}

void ImpulseReversal::Reset()
{
    InvalidateSetup(false);
    mStopTrading = false;
}