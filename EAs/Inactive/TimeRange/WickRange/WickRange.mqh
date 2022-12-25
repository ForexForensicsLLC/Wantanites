//+------------------------------------------------------------------+
//|                                                    WickRange.mqh |
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

class WickRange : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;

    datetime mWickRangeCandleTime;

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
    WickRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~WickRange();

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

WickRange::WickRange(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;

    mWickRangeCandleTime = 0;

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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<WickRange>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<WickRange, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<WickRange, SingleTimeFrameEntryTradeRecord>(this);
}

WickRange::~WickRange()
{
}

void WickRange::Run()
{
    EAHelper::RunDrawTimeRange<WickRange>(this, mTRB);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool WickRange::AllowedToTrade()
{
    return EAHelper::BelowSpread<WickRange>(this) && EAHelper::WithinTradingSession<WickRange>(this);
}

void WickRange::CheckSetSetup()
{
    if (mSetupType == OP_BUY)
    {
        if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) > mTRB.RangeLow() &&
            iLow(mEntrySymbol, mEntryTimeFrame, 1) < mTRB.RangeLow())
        {
            mHasSetup = true;
            mWickRangeCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) < mTRB.RangeHigh() &&
            iHigh(mEntrySymbol, mEntryTimeFrame, 1) > mTRB.RangeHigh())
        {
            mHasSetup = true;
            mWickRangeCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        }
    }
}

void WickRange::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mLastDay != Day())
    {
        InvalidateSetup(true);
        return;
    }

    if (mWickRangeCandleTime > 0)
    {
        int wickRangeCandleIndex = iTime(mEntrySymbol, mEntryTimeFrame, mWickRangeCandleTime);
        if (mSetupType == OP_BUY)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, wickRangeCandleIndex))
            {
                mStopTrading = true;
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, wickRangeCandleIndex))
            {
                mStopTrading = true;
                InvalidateSetup(true);
            }
        }
    }
}

void WickRange::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<WickRange>(this, deletePendingOrder, mStopTrading, error);
    mWickRangeCandleTime = 0;
}

bool WickRange::Confirmation()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return false;
    }

    if (mWickRangeCandleTime == 0)
    {
        return false;
    }

    int wickRangeCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mWickRangeCandleTime);
    if (wickRangeCandleIndex <= 0)
    {
        return false;
    }

    return CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, 1);
}

void WickRange::PlaceOrders()
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

    EAHelper::PlaceMarketOrder<WickRange>(this, entry, stopLoss);
    mStopTrading = true;
}

void WickRange::ManageCurrentPendingSetupTicket()
{
}

void WickRange::ManageCurrentActiveSetupTicket()
{
    EAHelper::CloseTicketIfPastTime<WickRange>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute);
}

bool WickRange::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void WickRange::ManagePreviousSetupTicket(int ticketIndex)
{
}

void WickRange::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickRange>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<WickRange>(this);
}

void WickRange::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickRange>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<WickRange>(this, ticketIndex);
}

void WickRange::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<WickRange>(this);
}

void WickRange::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickRange>(this, partialedTicket, newTicketNumber);
}

void WickRange::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<WickRange>(this, ticket, Period());
}

void WickRange::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<WickRange>(this, error, additionalInformation);
}

void WickRange::Reset()
{
    mStopTrading = false;
}