//+------------------------------------------------------------------+
//|                                                    ImpulseReversal.mqh |
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

class ImpulseReversal : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mMinPercentChange;
    datetime mCandleZoneTime;
    datetime mFurthestIntoCandleZoneTime;
    double mLargeBodyPips;
    double mMaxBigDipperPips;

    double mEntryPaddingPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPip;

    datetime mEntryCandleTime;

    int mBarCount;
    int mLastEntryMB;

    int mEntryTimeFrame;
    string mEntrySymbol;

public:
    ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ImpulseReversal();

    virtual double RiskPercent();

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

ImpulseReversal::ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinPercentChange = 0.0;
    mCandleZoneTime = 0;
    mFurthestIntoCandleZoneTime = 0;
    mLargeBodyPips = 0.0;
    mMaxBigDipperPips = 0.0;

    mEntryPaddingPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPip = 0.0;

    mBarCount = 0;
    mEntryCandleTime = 0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseReversal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseReversal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseReversal, SingleTimeFrameEntryTradeRecord>(this);
}

ImpulseReversal::~ImpulseReversal()
{
}

double ImpulseReversal::RiskPercent()
{
    return mRiskPercent;
}

void ImpulseReversal::Run()
{
    EAHelper::RunDrawMBT<ImpulseReversal>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseReversal::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseReversal>(this) && EAHelper::WithinTradingSession<ImpulseReversal>(this) &&
           mLastEntryMB < mSetupMBT.MBsCreated() - 1;
}

void ImpulseReversal::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    // looking for opposite MB
    int setupType = mSetupType == OP_BUY ? OP_SELL : OP_BUY;
    if (EAHelper::CheckSetSingleMBSetup<ImpulseReversal>(this, mSetupMBT, mFirstMBInSetupNumber, setupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        bool hasImpulse = false;
        if (mSetupType == OP_BUY)
        {
            for (int i = tempMBState.EndIndex(); i >= 1; i--)
            {
                if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) <= -mMinPercentChange)
                {
                    hasImpulse = true;
                }

                if (hasImpulse && CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, i))
                {
                    mCandleZoneTime = iTime(mEntrySymbol, mEntryTimeFrame, i + 1);
                    mHasSetup = true;
                    return;
                }
            }
        }
        else if (mSetupType == OP_SELL)
        {
            for (int i = tempMBState.EndIndex(); i >= 1; i--)
            {
                if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= mMinPercentChange)
                {
                    hasImpulse = true;
                }

                if (hasImpulse && CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, i))
                {
                    mCandleZoneTime = iTime(mEntrySymbol, mEntryTimeFrame, i + 1);
                    mHasSetup = true;
                    return;
                }
            }
        }
    }
}

void ImpulseReversal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
            return;
        }

        if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
        {
            return;
        }

        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (mSetupType == OP_BUY)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }

    if (mCandleZoneTime > 0 && iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
    {
        int candleZoneIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCandleZoneTime);
        if (mSetupType == OP_BUY)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, candleZoneIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, candleZoneIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }

    if (mFurthestIntoCandleZoneTime > 0 && iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
    {
        int furthestIntoZoneIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFurthestIntoCandleZoneTime);
        if (mSetupType == OP_BUY)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, furthestIntoZoneIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, furthestIntoZoneIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }
}

void ImpulseReversal::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseReversal>(this, deletePendingOrder, false, error);

    mFirstMBInSetupNumber = EMPTY;
    mCandleZoneTime = 0;
    mFurthestIntoCandleZoneTime = 0;
}

bool ImpulseReversal::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCandleZoneTime);
    if (zoneCandleIndex < 20)
    {
        return false;
    }

    bool potentialDoji = false;
    bool brokeCandle = false;
    bool furthestCandle = false;

    int dojiCandleIndex = EMPTY;
    int breakCandleIndex = EMPTY;

    if (mSetupType == OP_BUY)
    {
        int highestIndex = EMPTY;
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex - 1, 1, true, highestIndex))
        {
            return false;
        }

        if (mFurthestIntoCandleZoneTime == 0)
        {
            int tempLowestIndex = EMPTY;
            if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, highestIndex, 1, true, tempLowestIndex))
            {
                return false;
            }

            if (iLow(mEntrySymbol, mEntryTimeFrame, tempLowestIndex) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
            {
                return false;
            }

            mFurthestIntoCandleZoneTime = iTime(mEntrySymbol, mEntryTimeFrame, tempLowestIndex);
        }

        int furthestIntoCandleZoneIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFurthestIntoCandleZoneTime);

        // find most recent push up
        int mostRecentPushUp = EMPTY;
        int bullishCandleIndex = EMPTY;
        int fractalCandleIndex = EMPTY;
        bool pushedBelowMostRecentPushUp = false;

        for (int i = furthestIntoCandleZoneIndex; i < highestIndex; i++)
        {
            if (bullishCandleIndex == EMPTY && iClose(mEntrySymbol, mEntryTimeFrame, i) > iOpen(mEntrySymbol, mEntryTimeFrame, i))
            {
                bullishCandleIndex = i;
            }

            if (fractalCandleIndex == EMPTY &&
                iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i - 1))
            {
                fractalCandleIndex = i;
            }

            if (bullishCandleIndex != EMPTY && fractalCandleIndex != EMPTY)
            {
                break;
            }
        }

        if (bullishCandleIndex == EMPTY && fractalCandleIndex == EMPTY)
        {
            return false;
        }

        if (fractalCandleIndex > bullishCandleIndex)
        {
            mostRecentPushUp = bullishCandleIndex;
        }
        else if (iHigh(mEntrySymbol, mEntryTimeFrame, bullishCandleIndex) > iHigh(mEntrySymbol, mEntryTimeFrame, fractalCandleIndex))
        {
            mostRecentPushUp = bullishCandleIndex;
        }
        else
        {
            mostRecentPushUp = fractalCandleIndex;
        }

        // find first break above
        bool brokePushUp = false;
        for (int i = mostRecentPushUp; i >= 1; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp))
            {
                bool largeBody = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mLargeBodyPips);
                bool hasImpulse = CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i) ||
                                  CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i + 1);

                if (hasImpulse || largeBody)
                {
                    breakCandleIndex = i;
                    brokePushUp = true;
                    break;
                }
                else
                {
                    return hasTicket;
                }
            }
        }

        if (!brokePushUp)
        {
            return false;
        }

        int bearishCandleCount = 0;
        for (int i = breakCandleIndex - 1; i >= 1; i--)
        {
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mMaxBigDipperPips))
                {
                    return false;
                }

                bearishCandleCount += 1;
            }

            if (bearishCandleCount > 1)
            {
                return false;
            }
        }

        if (bearishCandleCount == 0)
        {
            return false;
        }

        // Big Dipper Entry
        bool twoPreviousIsBullish = iOpen(mEntrySymbol, mEntryTimeFrame, 2) < iClose(mEntrySymbol, mEntryTimeFrame, 2);
        bool previousIsBearish = iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iClose(mEntrySymbol, mEntryTimeFrame, 1);

        if (!twoPreviousIsBullish || !previousIsBearish)
        {
            return hasTicket;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        int lowestIndex = EMPTY;
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex - 1, 1, true, lowestIndex))
        {
            return false;
        }

        if (mFurthestIntoCandleZoneTime == 0)
        {
            int tempHighestIndex = EMPTY;
            if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, lowestIndex, 1, true, tempHighestIndex))
            {
                return false;
            }

            if (iHigh(mEntrySymbol, mEntryTimeFrame, tempHighestIndex) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
            {
                return false;
            }

            mFurthestIntoCandleZoneTime = iTime(mEntrySymbol, mEntryTimeFrame, tempHighestIndex);
        }

        int furthestIntoCandleZoneIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFurthestIntoCandleZoneTime);

        // find most recent push up
        int mostRecentPushDown = EMPTY;
        int bearishCandleIndex = EMPTY;
        int fractalCandleIndex = EMPTY;
        bool pushedAboveMostRecentPushDown = false;

        for (int i = furthestIntoCandleZoneIndex; i < lowestIndex; i++)
        {
            if (bearishCandleIndex == EMPTY && iClose(mEntrySymbol, mEntryTimeFrame, i) < iOpen(mEntrySymbol, mEntryTimeFrame, i))
            {
                bearishCandleIndex = i;
            }

            if (fractalCandleIndex == EMPTY &&
                iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i - 1))
            {
                fractalCandleIndex = i;
            }

            if (bearishCandleIndex != EMPTY && fractalCandleIndex != EMPTY)
            {
                break;
            }
        }

        if (bearishCandleIndex == EMPTY && fractalCandleIndex == EMPTY)
        {
            return false;
        }

        if (fractalCandleIndex > bearishCandleIndex)
        {
            mostRecentPushDown = bearishCandleIndex;
        }
        else if (iLow(mEntrySymbol, mEntryTimeFrame, bearishCandleIndex) < iLow(mEntrySymbol, mEntryTimeFrame, fractalCandleIndex))
        {
            mostRecentPushDown = bearishCandleIndex;
        }
        else
        {
            mostRecentPushDown = fractalCandleIndex;
        }

        // wait to break above
        bool brokePushDown = false;
        for (int i = mostRecentPushDown; i >= 1; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown))
            {
                bool largeBody = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mLargeBodyPips);
                bool hasImpulse = CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i) ||
                                  CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i + 1);

                if (hasImpulse || largeBody)
                {
                    breakCandleIndex = i;
                    brokePushDown = true;
                    break;
                }
                else
                {
                    return hasTicket;
                }
            }
        }

        if (!brokePushDown)
        {
            return false;
        }

        int bullishCandleCount = 0;
        for (int i = breakCandleIndex - 1; i >= 1; i--)
        {
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mMaxBigDipperPips))
                {
                    return false;
                }

                bullishCandleCount += 1;
            }

            if (bullishCandleCount > 1)
            {
                return false;
            }
        }

        if (bullishCandleCount == 0)
        {
            return false;
        }

        // Big Dipper Entry
        // Need Bullish -> Bearish - > Bullish after inner break
        bool twoPreviousIsBearish = iOpen(mEntrySymbol, mEntryTimeFrame, 2) > iClose(mEntrySymbol, mEntryTimeFrame, 2);
        bool previousIsBullish = iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iClose(mEntrySymbol, mEntryTimeFrame, 1);

        if (!twoPreviousIsBearish || !previousIsBullish)
        {
            return hasTicket;
        }
    }

    return true;
}

void ImpulseReversal::PlaceOrders()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
    {
        return;
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips) + OrderHelper::PipsToRange(mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<ImpulseReversal>(this, entry, stopLoss, 0.0, true, mBEAdditionalPip);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ImpulseReversal::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void ImpulseReversal::ManageCurrentActiveSetupTicket()
{
    if (!mLastEntryMB != mFirstMBInSetupNumber)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
    }

    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (EAHelper::CloseIfPercentIntoStopLoss<ImpulseReversal>(this, mCurrentSetupTicket, 0.5))
    {
        return;
    }

    int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips || mLastEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseReversal>(this, mBEAdditionalPip);
    }

    EAHelper::CheckPartialTicket<ImpulseReversal>(this, mCurrentSetupTicket);
}

bool ImpulseReversal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseReversal>(this, ticket);
}

void ImpulseReversal::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<ImpulseReversal>(this, mPreviousSetupTickets[ticketIndex]);
}

void ImpulseReversal::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseReversal>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseReversal>(this);
}

void ImpulseReversal::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseReversal>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseReversal>(this, ticketIndex);
}

void ImpulseReversal::RecordTicketOpenData()
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
}