//+------------------------------------------------------------------+
//|                                                    MBInnerBreak.mqh |
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

class MBInnerBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mSecondMBInSetupNumber;
    int mFirstMBInSetupNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;
    double mLargeBodyPips;
    double mMaxBigDipperBodyPips;
    double mPushFurtherPips;

    datetime mEntryCandleTime;
    datetime mBreakCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

    double mLastManagedBid;
    double mLastManagedAsk;

public:
    MBInnerBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBInnerBreak();

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

MBInnerBreak::MBInnerBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;

    mSecondMBInSetupNumber = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mBreakCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;
    mLargeBodyPips = 0.0;
    mMaxBigDipperBodyPips = 0.0;
    mPushFurtherPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedBid = 0.0;
    mLastManagedAsk = 0.0;

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBInnerBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBInnerBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBInnerBreak, SingleTimeFrameEntryTradeRecord>(this);
}

MBInnerBreak::~MBInnerBreak()
{
}

void MBInnerBreak::Run()
{
    EAHelper::RunDrawMBT<MBInnerBreak>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MBInnerBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBInnerBreak>(this) && EAHelper::WithinTradingSession<MBInnerBreak>(this);
}

void MBInnerBreak::CheckSetSetup()
{
    if (EAHelper::CheckSetDoubleMBSetup<MBInnerBreak>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mSetupType))
    {
        MBState *firstMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBState))
        {
            return;
        }

        if (!firstMBState.ClosestValidZoneIsHolding(firstMBState.EndIndex()))
        {
            return;
        }

        MBState *secondMBState;
        if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, secondMBState))
        {
            return;
        }

        if (firstMBState.EndIndex() - secondMBState.StartIndex() > 2)
        {
            return;
        }

        mHasSetup = true;
    }
}

void MBInnerBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSecondMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mSecondMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }
}

void MBInnerBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBInnerBreak>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
}

bool MBInnerBreak::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, tempMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    // bool doji = false;
    bool potentialDoji = false;
    bool brokeCandle = false;
    bool furthestCandle = false;

    int dojiCandleIndex = EMPTY;
    int breakCandleIndex = EMPTY;

    if (mSetupType == OP_BUY)
    {
        int currentBullishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(currentBullishRetracementIndex))
        {
            return false;
        }

        if (tempMBState.EndIndex() - currentBullishRetracementIndex > 2)
        {
            return false;
        }

        int lowestIndex = EMPTY;
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex, 1, true, lowestIndex))
        {
            return false;
        }

        // find most recent push up
        int mostRecentPushUp = EMPTY;
        int bullishCandleIndex = EMPTY;
        int fractalCandleIndex = EMPTY;
        bool pushedBelowMostRecentPushUp = false;

        for (int i = lowestIndex + 1; i <= currentBullishRetracementIndex; i++)
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

        // make sure we pushed below
        bool bullish = iClose(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp) > iOpen(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp);
        for (int i = mostRecentPushUp; i >= lowestIndex; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp))
            {
                // double percentBody = CandleStickHelper::PercentBody(mEntrySymbol, mEntryTimeFrame, i);
                double bodyLength = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i);
                bool singleCandleImpulse = /* percentBody >= 0.9*/ !bullish && bodyLength >= OrderHelper::PipsToRange(mLargeBodyPips);

                bool pushedFurther = iLow(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp) - iLow(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mPushFurtherPips);

                if (singleCandleImpulse || pushedFurther)
                {
                    pushedBelowMostRecentPushUp = true;
                }
            }
        }

        if (!pushedBelowMostRecentPushUp)
        {
            return false;
        }

        // find first break above
        bool brokePushUp = false;
        for (int i = mostRecentPushUp - 1; i >= 1; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp))
            {
                // don't enter if the break happened more than 5 candles prior
                if (i > 5)
                {
                    return hasTicket;
                }

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
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mMaxBigDipperBodyPips))
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

        // Big Dipper Entry
        bool twoPreviousIsBullish = iOpen(mEntrySymbol, mEntryTimeFrame, 2) < iClose(mEntrySymbol, mEntryTimeFrame, 2);
        bool previousIsBearish = iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iClose(mEntrySymbol, mEntryTimeFrame, 1);
        bool previousDoesNotBreakBelowTwoPrevious = iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2);

        if (!twoPreviousIsBullish || !previousIsBearish || !previousDoesNotBreakBelowTwoPrevious)
        {
            return hasTicket;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        int currentBearishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(currentBearishRetracementIndex))
        {
            return false;
        }

        if (tempMBState.EndIndex() - currentBearishRetracementIndex > 2)
        {
            return false;
        }

        int highestIndex = EMPTY;
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, currentBearishRetracementIndex, 1, true, highestIndex))
        {
            return false;
        }

        // find most recent push up
        int mostRecentPushDown = EMPTY;
        int bearishCandleIndex = EMPTY;
        int fractalCandleIndex = EMPTY;
        bool pushedAboveMostRecentPushDown = false;

        for (int i = highestIndex + 1; i <= currentBearishRetracementIndex; i++)
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

        // make sure we pushed below
        bool bearish = iClose(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown) < iOpen(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown);
        for (int i = mostRecentPushDown; i >= highestIndex; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown))
            {
                double percentBody = CandleStickHelper::PercentBody(mEntrySymbol, mEntryTimeFrame, i);
                double bodyLength = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i);
                bool singleCandleImpulse = /*percentBody >= 0.9*/ !bearish && bodyLength >= OrderHelper::PipsToRange(mLargeBodyPips);

                bool pushedFurther = iHigh(mEntrySymbol, mEntryTimeFrame, i) - iHigh(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown) >= OrderHelper::PipsToRange(mPushFurtherPips);
                if (singleCandleImpulse || pushedFurther)
                {
                    pushedAboveMostRecentPushDown = true;
                }
            }
        }

        if (!pushedAboveMostRecentPushDown)
        {
            return false;
        }

        // wait to break above
        bool brokePushDown = false;
        for (int i = mostRecentPushDown; i >= 1; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown))
            {
                if (i > 5)
                {
                    return hasTicket;
                }

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
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mMaxBigDipperBodyPips))
                {
                    return false;
                }

                bullishCandleCount += 1;
            }

            if (bullishCandleCount > 1 || (bullishCandleCount == 1 && breakCandleIndex > 2))
            {
                return false;
            }
        }

        // Big Dipper Entry
        // Need Bullish -> Bearish - > Bullish after inner break
        bool twoPreviousIsBearish = iOpen(mEntrySymbol, mEntryTimeFrame, 2) > iClose(mEntrySymbol, mEntryTimeFrame, 2);
        bool previousIsBullish = iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iClose(mEntrySymbol, mEntryTimeFrame, 1);
        bool previousDoesNotBreakAboveTwoPrevious = iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2);

        if (!twoPreviousIsBearish || !previousIsBullish || !previousDoesNotBreakAboveTwoPrevious)
        {
            return hasTicket;
        }
    }

    mBreakCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, breakCandleIndex);
    return true;
}

void MBInnerBreak::PlaceOrders()
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

    MBState *mostRecentMB;
    if (!mSetupMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return;
    }

    ZoneState *holdingZone;
    if (!mostRecentMB.GetClosestValidZone(holdingZone))
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
        int breakCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mBreakCandleTime);
        double lowest = -1.0;
        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, breakCandleIndex - 1, 0, true, lowest))
        {
            return;
        }

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        int breakCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mBreakCandleTime);
        double highest = -1.0;
        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, breakCandleIndex - 1, 0, true, highest))
        {
            return;
        }

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips) + OrderHelper::PipsToRange(mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<MBInnerBreak>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void MBInnerBreak::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);

    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mSetupType == OP_BUY && entryCandleIndex > 1)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL && entryCandleIndex > 1)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void MBInnerBreak::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
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
        if (entryIndex > 5)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.bid >= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a low within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }

                        // pushed too far into SL, take the -0.5
                        if (EAHelper::CloseIfPercentIntoStopLoss<MBInnerBreak>(this, mCurrentSetupTicket, 0.5))
                        {
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        if (entryIndex > 5)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.ask <= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // middle close
        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a high within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }

                        // pushed too far into SL, take the -0.5
                        if (EAHelper::CloseIfPercentIntoStopLoss<MBInnerBreak>(this, mCurrentSetupTicket, 0.5))
                        {
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBInnerBreak>(this, 0);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool MBInnerBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBInnerBreak>(this, ticket);
}

void MBInnerBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MBInnerBreak>(this, mPreviousSetupTickets[ticketIndex]);
}

void MBInnerBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBInnerBreak>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MBInnerBreak>(this);
}

void MBInnerBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBInnerBreak>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MBInnerBreak>(this, ticketIndex);
}

void MBInnerBreak::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBInnerBreak>(this);
}

void MBInnerBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBInnerBreak>(this, partialedTicket, newTicketNumber);
}

void MBInnerBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBInnerBreak>(this, ticket, Period());
}

void MBInnerBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBInnerBreak>(this, error, additionalInformation);
}

void MBInnerBreak::Reset()
{
}