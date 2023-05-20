//+------------------------------------------------------------------+
//|                                                    ConsecutiveMonrningMBs.mqh |
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

class ConsecutiveMonrningMBs : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    ConsecutiveMonrningMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~ConsecutiveMonrningMBs();

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

ConsecutiveMonrningMBs::ConsecutiveMonrningMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ConsecutiveMonrningMBs>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ConsecutiveMonrningMBs, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ConsecutiveMonrningMBs, SingleTimeFrameEntryTradeRecord>(this);
}

ConsecutiveMonrningMBs::~ConsecutiveMonrningMBs()
{
}

void ConsecutiveMonrningMBs::PreRun()
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

bool ConsecutiveMonrningMBs::AllowedToTrade()
{
    return EAHelper::BelowSpread<ConsecutiveMonrningMBs>(this) && EAHelper::WithinTradingSession<ConsecutiveMonrningMBs>(this);
}

void ConsecutiveMonrningMBs::CheckSetSetup()
{
    // if (mMBT.CurrentMBs() <= 0)
    // {
    //     return;
    // }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    if (mFirstMBTypeOfTheDay == EMPTY)
    {
        if (EAHelper::MBWasCreatedAfterSessionStart<ConsecutiveMonrningMBs>(this, mMBT, mMBT.MBsCreated() - 1))
        {
            mFirstMBTypeOfTheDay = mMBT.GetNthMostRecentMBsType(0);
            Print("First MB of the day type: ", mFirstMBTypeOfTheDay);
        }
    }
    else
    {
        if (mFirstMBTypeOfTheDay != SetupType())
        {
            Print("EA: ", SetupType(), " done for the day");
            mStopTrading = true;
            return;
        }

        if (mLastSetupMBNumber == mMBT.MBsCreated() - 1)
        {
            return;
        }

        if (EAHelper::CheckSetSingleMBSetup<ConsecutiveMonrningMBs>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
        {
            Print("Setup");
            mHasSetup = true;
        }
    }
}

void ConsecutiveMonrningMBs::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (mFirstMBTypeOfTheDay != EMPTY && mMBT.GetNthMostRecentMBsType(0) != SetupType())
    {
        mStopTrading = true;
        InvalidateSetup(true);
    }
}

void ConsecutiveMonrningMBs::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;
    EAHelper::InvalidateSetup<ConsecutiveMonrningMBs>(this, deletePendingOrder, mStopTrading, error);
}

bool ConsecutiveMonrningMBs::Confirmation()
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

    double price = 0.0;
    if (SetupType() == OP_BUY)
    {
        price = iLow(mEntrySymbol, mEntryTimeFrame, 2);
    }
    else if (SetupType() == OP_SELL)
    {
        price = iHigh(mEntrySymbol, mEntryTimeFrame, 2);
    }

    return EAHelper::PriceIsFurtherThanPercentIntoMB<ConsecutiveMonrningMBs>(this, mMBT, mFirstMBInSetupNumber, price, .3) &&
           CandleStickHelper::BrokeFurther(SetupType(), mEntrySymbol, mEntryTimeFrame, 1);
}

void ConsecutiveMonrningMBs::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    MBState *tempMBState;
    if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    // ZoneState *tempZoneState;
    // if (!mMBT.GetNthMostRecentMBsClosestValidZone(0, tempZoneState))
    // {
    //     return;
    // }

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

    // if (OrderHelper::RangeToPips(MathAbs(entry - stopLoss)) >= 15)
    // {
    //     InvalidateSetup(false);
    //     return;
    // }

    EAHelper::PlaceMarketOrder<ConsecutiveMonrningMBs>(this, entry, stopLoss);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLastSetupMBNumber = mFirstMBInSetupNumber;
        InvalidateSetup(false);
    }
}

void ConsecutiveMonrningMBs::PreManageTickets()
{
}

void ConsecutiveMonrningMBs::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void ConsecutiveMonrningMBs::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAHelper::MoveToBreakEvenAfterPips<ConsecutiveMonrningMBs>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool ConsecutiveMonrningMBs::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ConsecutiveMonrningMBs>(this, ticket);
}

void ConsecutiveMonrningMBs::ManagePreviousSetupTicket(Ticket &ticket)
{
    // EAHelper::CheckTrailStopLossEveryXPips<ConsecutiveMonrningMBs>(this, ticket, 5, 2.5);
}

void ConsecutiveMonrningMBs::CheckCurrentSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<ConsecutiveMonrningMBs>(this, ticket);
}

void ConsecutiveMonrningMBs::CheckPreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<ConsecutiveMonrningMBs>(this, ticket);
}

void ConsecutiveMonrningMBs::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ConsecutiveMonrningMBs>(this, ticket);
}

void ConsecutiveMonrningMBs::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ConsecutiveMonrningMBs>(this, partialedTicket, newTicketNumber);
}

void ConsecutiveMonrningMBs::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ConsecutiveMonrningMBs>(this, ticket, Period());
}

void ConsecutiveMonrningMBs::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ConsecutiveMonrningMBs>(this, error, additionalInformation);
}

bool ConsecutiveMonrningMBs::ShouldReset()
{
    return !EAHelper::WithinTradingSession<ConsecutiveMonrningMBs>(this);
}

void ConsecutiveMonrningMBs::Reset()
{
    mStopTrading = false;
    mFirstMBTypeOfTheDay = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    mClearMBs = true;
    EAHelper::CloseAllCurrentAndPreviousSetupTickets<ConsecutiveMonrningMBs>(this);
}