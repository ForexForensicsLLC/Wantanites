//+------------------------------------------------------------------+
//|                                                    ReEnterReversal.mqh |
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

class ReEnterReversal : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;

    datetime mBrokeRangeCandleTime;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    int mCloseHour;
    int mCloseMinute;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    ReEnterReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~ReEnterReversal();

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

ReEnterReversal::ReEnterReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;

    mBrokeRangeCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mCloseHour = 0;
    mCloseMinute = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ReEnterReversal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ReEnterReversal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ReEnterReversal, SingleTimeFrameEntryTradeRecord>(this);
}

ReEnterReversal::~ReEnterReversal()
{
}

void ReEnterReversal::Run()
{
    EAHelper::RunDrawTimeRange<ReEnterReversal>(this, mTRB);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool ReEnterReversal::AllowedToTrade()
{
    return EAHelper::BelowSpread<ReEnterReversal>(this) && EAHelper::WithinTradingSession<ReEnterReversal>(this);
}

void ReEnterReversal::CheckSetSetup()
{
    if (EAHelper::HasTimeRangeBreakoutReversal<ReEnterReversal>(this))
    {
        mHasSetup = true;
        mBrokeRangeCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }
}

void ReEnterReversal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day())
    {
        InvalidateSetup(true);
    }
}

void ReEnterReversal::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<ReEnterReversal>(this, deletePendingOrder, mStopTrading, error);
    mBrokeRangeCandleTime = 0;
}

bool ReEnterReversal::Confirmation()
{
    if (mBrokeRangeCandleTime == 0)
    {
        return false;
    }

    int brokeRangeCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mBrokeRangeCandleTime);
    if (brokeRangeCandleIndex <= 0)
    {
        return false;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    double furthestBody = 0.0;
    double halfOfRange = mTRB.RangeHigh() - (mTRB.RangeWidth() * 0.5);
    if (mSetupType == OP_BUY)
    {
        if (!MQLHelper::GetLowestBodyBetween(mEntrySymbol, mEntryTimeFrame, brokeRangeCandleIndex, 1, true, furthestBody))
        {
            return false;
        }

        if (furthestBody > mTRB.RangeLow())
        {
            return false;
        }

        return currentTick.ask >= halfOfRange;
    }
    else if (mSetupType == OP_SELL)
    {
        if (!MQLHelper::GetHighestBodyBetween(mEntrySymbol, mEntryTimeFrame, brokeRangeCandleIndex, 1, true, furthestBody))
        {
            return false;
        }

        if (furthestBody < mTRB.RangeHigh())
        {
            return false;
        }

        return currentTick.bid <= halfOfRange;
    }

    return false;
}

void ReEnterReversal::PlaceOrders()
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
        stopLoss = mTRB.RangeLow();
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = mTRB.RangeHigh();
    }

    EAHelper::PlaceMarketOrder<ReEnterReversal>(this, entry, stopLoss);
    mStopTrading = true;
}

void ReEnterReversal::ManageCurrentPendingSetupTicket()
{
}

void ReEnterReversal::ManageCurrentActiveSetupTicket()
{
    EAHelper::CloseTicketIfPastTime<ReEnterReversal>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute);
}

bool ReEnterReversal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void ReEnterReversal::ManagePreviousSetupTicket(int ticketIndex)
{
}

void ReEnterReversal::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ReEnterReversal>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ReEnterReversal>(this);
}

void ReEnterReversal::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ReEnterReversal>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ReEnterReversal>(this, ticketIndex);
}

void ReEnterReversal::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ReEnterReversal>(this);
}

void ReEnterReversal::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ReEnterReversal>(this, partialedTicket, newTicketNumber);
}

void ReEnterReversal::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ReEnterReversal>(this, ticket, Period());
}

void ReEnterReversal::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ReEnterReversal>(this, error, additionalInformation);
}

void ReEnterReversal::Reset()
{
    mStopTrading = false;
}