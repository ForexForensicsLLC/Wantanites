//+------------------------------------------------------------------+
//|                                                    TheGrannySmith.mqh |
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

class TheGrannySmith : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;
    double mLargeBodyPips;
    double mPushFurtherPips;

    int mSetupMBsCreated;

    datetime mEntryCandleTime;
    datetime mStopLossCandleTime;
    datetime mBreakCandleTime;
    int mBarCount;
    int mManageCurrentSetupBarCount;
    int mConfirmationBarCount;
    int mSetupBarCount;
    int mCheckInvalidateSetupBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mSetupTimeFrame;
    string mSetupSymbol;

    int mLastEntryMB;
    int mLastEntryZone;

    int mMBCount;
    int mLastDay;
    int mEntryMBNumber;

    double mLastManagedBid;
    double mLastManagedAsk;

    double mImbalanceCandlePercentChange;

public:
    TheGrannySmith(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheGrannySmith();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }
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
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

TheGrannySmith::TheGrannySmith(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;
    mLargeBodyPips = 0.0;
    mPushFurtherPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheGrannySmith>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheGrannySmith, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheGrannySmith, MultiTimeFrameEntryTradeRecord>(this);

    mSetupMBsCreated = 0;

    mBreakCandleTime = 0;

    mConfirmationBarCount = 0;
    mBarCount = 0;
    mManageCurrentSetupBarCount = 0;
    mCheckInvalidateSetupBarCount = 0;
    mSetupBarCount = 0;
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;

    mLastEntryMB = EMPTY;
    mLastEntryZone = EMPTY;

    mMBCount = 0;
    mLastDay = 0;

    mImbalanceCandlePercentChange = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupSymbol = Symbol();
    mSetupTimeFrame = 15;

    mEntryMBNumber = EMPTY;

    mLastManagedBid = 0.0;
    mLastManagedAsk = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

TheGrannySmith::~TheGrannySmith()
{
}

double TheGrannySmith::RiskPercent()
{
    return mRiskPercent;
}

void TheGrannySmith::Run()
{
    EAHelper::RunDrawMBT<TheGrannySmith>(this, mSetupMBT);
}

bool TheGrannySmith::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheGrannySmith>(this) && EAHelper::WithinTradingSession<TheGrannySmith>(this);
}

void TheGrannySmith::CheckSetSetup()
{
    if (mLastDay != Day())
    {
        mMBCount = 0;
        mLastDay = Day();
    }

    if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    {
        mSetupMBsCreated = mSetupMBT.MBsCreated();
        mMBCount += 1;
    }

    if (EAHelper::CheckSetSingleMBSetup<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void TheGrannySmith::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }
}

void TheGrannySmith::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheGrannySmith>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
    mStopLossCandleTime = 0;
}

bool TheGrannySmith::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    int bars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (bars <= mConfirmationBarCount)
    {
        return hasTicket;
    }

    mConfirmationBarCount = bars;

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    bool inZone = false;
    bool zoneIsHolding = false;
    int holdingError = EAHelper::MostRecentMBZoneIsHolding<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);

    // bool doji = false;
    bool potentialDoji = false;
    bool brokeCandle = false;
    bool furthestCandle = false;

    int dojiCandleIndex = EMPTY;
    int breakCandleIndex = EMPTY;

    if (mSetupType == OP_BUY)
    {
        // make sure zone is within mb
        if (tempZoneState.EntryPrice() > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        {
            return false;
        }

        int currentBullishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(currentBullishRetracementIndex))
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
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mLargeBodyPips))
                {
                    return false;
                }

                bearishCandleCount += 1;
            }

            if (bearishCandleCount > 1 || (bearishCandleCount == 1 && breakCandleIndex > 2))
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
        // make sure zone is in mb
        if (tempZoneState.EntryPrice() < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        {
            return false;
        }

        int currentBearishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(currentBearishRetracementIndex))
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
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mLargeBodyPips))
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

    bool hasConfirmation = hasTicket || zoneIsHolding;
    if (hasConfirmation)
    {
        mBreakCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, breakCandleIndex);
    }

    return hasConfirmation;
}

void TheGrannySmith::PlaceOrders()
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

    EAHelper::PlaceStopOrder<TheGrannySmith>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mLastEntryZone = holdingZone.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mBarCount = currentBars;
    }
}

void TheGrannySmith::ManageCurrentPendingSetupTicket()
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
            // Print("Broke Below Invalidatino");
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

void TheGrannySmith::ManageCurrentActiveSetupTicket()
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
        if (entryIndex <= 200)
        {
            for (int i = entryIndex - 1; i >= 0; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {

                    if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j) &&
                        currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
                    {
                        mCurrentSetupTicket.Close();
                        return;
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

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 5)
        {
            if (mLastManagedBid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips) &&
                currentTick.bid <= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }
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
        if (entryIndex <= 200)
        {
            for (int i = entryIndex - 1; i >= 0; i--)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j) &&
                        currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
                    {
                        mCurrentSetupTicket.Close();
                        return;
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

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 5)
        {
            if (mLastManagedAsk < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips) &&
                currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool TheGrannySmith::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheGrannySmith>(this, ticket);
}

void TheGrannySmith::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheGrannySmith>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheGrannySmith>(this);
}

void TheGrannySmith::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheGrannySmith>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<TheGrannySmith>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT, mMBCount, mLastEntryZone);
}

void TheGrannySmith::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheGrannySmith>(this, oldTicketIndex, newTicketNumber);
}

void TheGrannySmith::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheGrannySmith>(this, ticket, Period());
}

void TheGrannySmith::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheGrannySmith>(this, error, additionalInformation);
}

void TheGrannySmith::Reset()
{
    mMBCount = 0;
}