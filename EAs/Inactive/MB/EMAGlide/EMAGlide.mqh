//+------------------------------------------------------------------+
//|                                                    MBEMAGlide.mqh |
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

#include <Wantanites\Framework\Objects\Indicators\Grid\GridTracker.mqh>
#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>

class MBEMAGlide : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;

    int mFirstMBTypeOfTheDay;
    int mFirstMBInSetupNumber;
    int mLastSetupMBNumber;

    double mMinWickLength;

    bool mClearMBs;
    int mClearHour;
    int mClearMinute;

    double mMinStopLossDistance;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

public:
    MBEMAGlide(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~MBEMAGlide();

    double EMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index); }

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

MBEMAGlide::MBEMAGlide(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;

    mFirstMBTypeOfTheDay = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mLastSetupMBNumber = EMPTY;

    mMinWickLength = 0.0;

    mClearMBs = true;
    mClearHour = 0;
    mClearMinute = 0;

    mMinStopLossDistance = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBEMAGlide>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBEMAGlide, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBEMAGlide, SingleTimeFrameEntryTradeRecord>(this);
}

MBEMAGlide::~MBEMAGlide()
{
}

void MBEMAGlide::PreRun()
{
    // if (mClearMBs && Hour() == mClearHour && Minute() == mClearMinute)
    // {
    //     mMBT.Clear();
    //     mClearMBs = false;
    //     mLastSetupMBNumber = EMPTY;
    // }

    mMBT.DrawNMostRecentMBs(-1);
    mMBT.DrawZonesForNMostRecentMBs(-1);
}

bool MBEMAGlide::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBEMAGlide>(this) && EAHelper::WithinTradingSession<MBEMAGlide>(this);
}

void MBEMAGlide::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(tempMBState))
    {
        return;
    }

    if (SetupType() == OP_BUY && tempMBState.Type() == OP_BUY)
    {
        for (int i = 0; i < tempMBState.EndIndex(); i++)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, i) <= EMA(i))
            {
                return;
            }
        }

        mFirstMBInSetupNumber = tempMBState.Number();
        mHasSetup = true;
    }
    else if (SetupType() == OP_SELL && tempMBState.Type() == OP_SELL)
    {
        for (int i = 0; i < tempMBState.EndIndex(); i++)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) >= EMA(i))
            {
                return;
            }
        }

        mFirstMBInSetupNumber = tempMBState.Number();
        mHasSetup = true;
    }
}

void MBEMAGlide::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }
}

void MBEMAGlide::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;
    EAHelper::InvalidateSetup<MBEMAGlide>(this, deletePendingOrder, mStopTrading, error);
}

bool MBEMAGlide::Confirmation()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return false;
    }

    MBState *tempMBState;
    if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    int furthestIndex = EMPTY;
    double furthestPrice = 0.0;
    if (SetupType() == OP_BUY)
    {
        if (!mMBT.HasPendingBullishMB())
        {
            return false;
        }

        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex(), 2, false, furthestIndex))
        {
            return false;
        }

        furthestPrice = iLow(mEntrySymbol, mEntryTimeFrame, furthestIndex);
        if (furthestPrice <= EMA(furthestIndex))
        {
            return false;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (!mMBT.HasPendingBearishMB())
        {
            return false;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex(), 2, false, furthestIndex))
        {
            return false;
        }

        furthestPrice = iHigh(mEntrySymbol, mEntryTimeFrame, furthestIndex);
        if (furthestPrice >= EMA(furthestIndex))
        {
            return false;
        }
    }

    return EAHelper::PriceIsFurtherThanPercentIntoMB<MBEMAGlide>(this, mMBT, mFirstMBInSetupNumber, furthestPrice, .3) &&
           CandleStickHelper::BrokeFurther(SetupType(), mEntrySymbol, mEntryTimeFrame, 1);
}

void MBEMAGlide::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    MBState *tempMBState;
    if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()), entry - mMinStopLossDistance);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()), entry + mMinStopLossDistance);
    }

    EAHelper::PlaceMarketOrder<MBEMAGlide>(this, entry, stopLoss);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLastSetupMBNumber = mFirstMBInSetupNumber;
        InvalidateSetup(false);
    }
}

void MBEMAGlide::PreManageTickets()
{
}

void MBEMAGlide::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void MBEMAGlide::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAHelper::MoveToBreakEvenAfterPips<MBEMAGlide>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool MBEMAGlide::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBEMAGlide>(this, ticket);
}

void MBEMAGlide::ManagePreviousSetupTicket(Ticket &ticket)
{
    // EAHelper::CheckTrailStopLossEveryXPips<MBEMAGlide>(this, ticket, 5, 2.5);
}

void MBEMAGlide::CheckCurrentSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<MBEMAGlide>(this, ticket);
}

void MBEMAGlide::CheckPreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<MBEMAGlide>(this, ticket);
}

void MBEMAGlide::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBEMAGlide>(this, ticket);
}

void MBEMAGlide::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBEMAGlide>(this, partialedTicket, newTicketNumber);
}

void MBEMAGlide::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBEMAGlide>(this, ticket, Period());
}

void MBEMAGlide::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBEMAGlide>(this, error, additionalInformation);
}

bool MBEMAGlide::ShouldReset()
{
    return !EAHelper::WithinTradingSession<MBEMAGlide>(this);
}

void MBEMAGlide::Reset()
{
    mStopTrading = false;
    mFirstMBTypeOfTheDay = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    mClearMBs = true;
    EAHelper::CloseAllCurrentAndPreviousSetupTickets<MBEMAGlide>(this);
}