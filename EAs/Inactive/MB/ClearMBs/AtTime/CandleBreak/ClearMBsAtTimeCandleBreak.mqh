//+------------------------------------------------------------------+
//|                                                    ClearMBsAtTime.mqh |
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

class ClearMBsAtTime : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;

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
    ClearMBsAtTime(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~ClearMBsAtTime();

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

ClearMBsAtTime::ClearMBsAtTime(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;

    mFirstMBInSetupNumber = EMPTY;
    mLastSetupMBNumber = EMPTY;

    mMinWickLength = 0.0;

    mClearMBs = true;
    mClearHour = 0;
    mClearMinute = 0;

    mMinStopLossDistance = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ClearMBsAtTime>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ClearMBsAtTime, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ClearMBsAtTime, SingleTimeFrameEntryTradeRecord>(this);
}

ClearMBsAtTime::~ClearMBsAtTime()
{
}

void ClearMBsAtTime::PreRun()
{
    if (mClearMBs && Hour() == mClearHour && Minute() == mClearMinute)
    {
        mMBT.Clear();
        mClearMBs = false;
        mLastSetupMBNumber = EMPTY;
    }

    mMBT.DrawNMostRecentMBs(-1);
    mMBT.DrawZonesForNMostRecentMBs(-1);
}

bool ClearMBsAtTime::AllowedToTrade()
{
    return EAHelper::BelowSpread<ClearMBsAtTime>(this) && EAHelper::WithinTradingSession<ClearMBsAtTime>(this);
}

void ClearMBsAtTime::CheckSetSetup()
{
    if (mMBT.CurrentMBs() <= 0)
    {
        return;
    }

    if (mLastSetupMBNumber == mMBT.MBsCreated() - 1)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<ClearMBsAtTime>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
    {
        mHasSetup = true;
    }
}

void ClearMBsAtTime::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
    }
}

void ClearMBsAtTime::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;
    EAHelper::InvalidateSetup<ClearMBsAtTime>(this, deletePendingOrder, mStopTrading, error);
}

bool ClearMBsAtTime::Confirmation()
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

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    int startOfMBIndex = EMPTY;
    int firstCandleInZone = EMPTY;
    if (SetupType() == OP_BUY)
    {
        if (!mMBT.CurrentBullishRetracementIndexIsValid(startOfMBIndex))
        {
            return false;
        }

        for (int i = startOfMBIndex; i > 0; i--)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, i) < tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }
    }
    else if (SetupType() == OP_SELL)
    {
        if (!mMBT.CurrentBearishRetracementIndexIsValid(startOfMBIndex))
        {
            return false;
        }

        for (int i = startOfMBIndex; i > 0; i--)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }
    }

    return firstCandleInZone > 3 && CandleStickHelper::BrokeFurther(SetupType(), mEntrySymbol, mEntryTimeFrame, 1);
}

void ClearMBsAtTime::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    ZoneState *tempZoneState;
    if (!mMBT.GetNthMostRecentMBsClosestValidZone(0, tempZoneState))
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = MathMin(tempZoneState.ExitPrice(), entry - mMinStopLossDistance);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = MathMax(tempZoneState.ExitPrice(), entry + mMinStopLossDistance);
    }

    if (OrderHelper::RangeToPips(MathAbs(entry - stopLoss)) >= 15)
    {
        InvalidateSetup(false);
        return;
    }

    EAHelper::PlaceMarketOrder<ClearMBsAtTime>(this, entry, stopLoss);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLastSetupMBNumber = mFirstMBInSetupNumber;
        InvalidateSetup(false);
    }
}

void ClearMBsAtTime::PreManageTickets()
{
}

void ClearMBsAtTime::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void ClearMBsAtTime::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    if (EAHelper::CloseIfPercentIntoStopLoss<ClearMBsAtTime>(this, ticket, 0.5))
    {
        return;
    }

    EAHelper::MoveToBreakEvenAfterPips<ClearMBsAtTime>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool ClearMBsAtTime::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ClearMBsAtTime>(this, ticket);
}

void ClearMBsAtTime::ManagePreviousSetupTicket(Ticket &ticket)
{
    // EAHelper::CheckTrailStopLossEveryXPips<ClearMBsAtTime>(this, ticket, 5, 2.5);
}

void ClearMBsAtTime::CheckCurrentSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<ClearMBsAtTime>(this, ticket);
}

void ClearMBsAtTime::CheckPreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<ClearMBsAtTime>(this, ticket);
}

void ClearMBsAtTime::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ClearMBsAtTime>(this, ticket);
}

void ClearMBsAtTime::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ClearMBsAtTime>(this, partialedTicket, newTicketNumber);
}

void ClearMBsAtTime::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ClearMBsAtTime>(this, ticket, Period());
}

void ClearMBsAtTime::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ClearMBsAtTime>(this, error, additionalInformation);
}

bool ClearMBsAtTime::ShouldReset()
{
    return !EAHelper::WithinTradingSession<ClearMBsAtTime>(this);
}

void ClearMBsAtTime::Reset()
{
    mClearMBs = true;
    EAHelper::CloseAllCurrentAndPreviousSetupTickets<ClearMBsAtTime>(this);
}