//+------------------------------------------------------------------+
//|                                                    MBInnerBreak.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>

class MBInnerBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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

    datetime mEntryCandleTime;
    datetime mBreakCandleTime;

    int mLastEntryMB;

    double mLastManagedBid;
    double mLastManagedAsk;

public:
    MBInnerBreak(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBInnerBreak();

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
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

MBInnerBreak::MBInnerBreak(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;

    mEntryCandleTime = 0;
    mBreakCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;
    mLargeBodyPips = 0.0;
    mPushFurtherPips = 0.0;

    mLastEntryMB = ConstantValues::EmptyInt;

    mLastManagedBid = 0.0;
    mLastManagedAsk = 0.0;

    mLargestAccountBalance = 100000;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<MBInnerBreak>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<MBInnerBreak, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<MBInnerBreak, SingleTimeFrameEntryTradeRecord>(this);
}

MBInnerBreak::~MBInnerBreak()
{
}

void MBInnerBreak::PreRun()
{
}

bool MBInnerBreak::AllowedToTrade()
{
    return EARunHelper::BelowSpread<MBInnerBreak>(this) && EARunHelper::WithinTradingSession<MBInnerBreak>(this);
}

void MBInnerBreak::CheckSetSetup()
{
    if (EASetupHelper::CheckSetSingleMBSetup<MBInnerBreak>(this, mSetupMBT, mFirstMBInSetupNumber, SetupType()))
    {
        mHasSetup = true;
    }
}

void MBInnerBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != ConstantValues::EmptyInt)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }
}

void MBInnerBreak::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<MBInnerBreak>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;
}

bool MBInnerBreak::Confirmation()
{
    bool hasTicket = !mCurrentSetupTickets.IsEmpty();

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return hasTicket;
    }

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

    // bool doji = false;
    bool potentialDoji = false;
    bool brokeCandle = false;
    bool furthestCandle = false;

    int dojiCandleIndex = EMPTY;
    int breakCandleIndex = EMPTY;

    if (SetupType() == SignalType::Bullish)
    {
        int currentBullishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(currentBullishRetracementIndex))
        {
            return false;
        }

        int lowestIndex = EMPTY;
        if (!MQLHelper::GetLowestIndexBetween(EntrySymbol(), EntryTimeFrame(), currentBullishRetracementIndex, 1, true, lowestIndex))
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
            if (bullishCandleIndex == EMPTY && iClose(EntrySymbol(), EntryTimeFrame(), i) > iOpen(EntrySymbol(), EntryTimeFrame(), i))
            {
                bullishCandleIndex = i;
            }

            if (fractalCandleIndex == EMPTY &&
                iHigh(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), i + 1) &&
                iHigh(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), i - 1))
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
        else if (iHigh(EntrySymbol(), EntryTimeFrame(), bullishCandleIndex) > iHigh(EntrySymbol(), EntryTimeFrame(), fractalCandleIndex))
        {
            mostRecentPushUp = bullishCandleIndex;
        }
        else
        {
            mostRecentPushUp = fractalCandleIndex;
        }

        // make sure we pushed below
        bool bullish = iClose(EntrySymbol(), EntryTimeFrame(), mostRecentPushUp) > iOpen(EntrySymbol(), EntryTimeFrame(), mostRecentPushUp);
        for (int i = mostRecentPushUp; i >= lowestIndex; i--)
        {
            if (iClose(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), mostRecentPushUp))
            {
                // double percentBody = CandleStickHelper::PercentBody(EntrySymbol(), EntryTimeFrame(), i);
                double bodyLength = CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), i);
                bool singleCandleImpulse = /* percentBody >= 0.9*/ !bullish && bodyLength >= PipConverter::PipsToPoints(mLargeBodyPips);

                bool pushedFurther = iLow(EntrySymbol(), EntryTimeFrame(), mostRecentPushUp) - iLow(EntrySymbol(), EntryTimeFrame(), i) >= PipConverter::PipsToPoints(mPushFurtherPips);

                if (singleCandleImpulse || pushedFurther)
                {
                    pushedBelowMostRecentPushUp = true;
                    break;
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
            if (iClose(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), mostRecentPushUp))
            {
                // don't enter if the break happened more than 5 candles prior
                if (i > 5)
                {
                    return hasTicket;
                }

                bool largeBody = CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), i) >= PipConverter::PipsToPoints(mLargeBodyPips);
                bool hasImpulse = CandleStickHelper::HasImbalance(SignalType::Bullish, EntrySymbol(), EntryTimeFrame(), i) ||
                                  CandleStickHelper::HasImbalance(SignalType::Bullish, EntrySymbol(), EntryTimeFrame(), i + 1);

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
            if (CandleStickHelper::IsBearish(EntrySymbol(), EntryTimeFrame(), i))
            {
                if (CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), i) > PipConverter::PipsToPoints(mLargeBodyPips))
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
        bool twoPreviousIsBullish = iOpen(EntrySymbol(), EntryTimeFrame(), 2) < iClose(EntrySymbol(), EntryTimeFrame(), 2);
        bool previousIsBearish = iOpen(EntrySymbol(), EntryTimeFrame(), 1) > iClose(EntrySymbol(), EntryTimeFrame(), 1);
        bool previousDoesNotBreakBelowTwoPrevious = iClose(EntrySymbol(), EntryTimeFrame(), 1) > iLow(EntrySymbol(), EntryTimeFrame(), 2);

        if (!twoPreviousIsBullish || !previousIsBearish || !previousDoesNotBreakBelowTwoPrevious)
        {
            return hasTicket;
        }
    }
    else if (SetupType() == SignalType::Bearish)
    {
        int currentBearishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(currentBearishRetracementIndex))
        {
            return false;
        }

        int highestIndex = EMPTY;
        if (!MQLHelper::GetHighestIndexBetween(EntrySymbol(), EntryTimeFrame(), currentBearishRetracementIndex, 1, true, highestIndex))
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
            if (bearishCandleIndex == EMPTY && iClose(EntrySymbol(), EntryTimeFrame(), i) < iOpen(EntrySymbol(), EntryTimeFrame(), i))
            {
                bearishCandleIndex = i;
            }

            if (fractalCandleIndex == EMPTY &&
                iLow(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), i + 1) &&
                iLow(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), i - 1))
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
        else if (iLow(EntrySymbol(), EntryTimeFrame(), bearishCandleIndex) < iLow(EntrySymbol(), EntryTimeFrame(), fractalCandleIndex))
        {
            mostRecentPushDown = bearishCandleIndex;
        }
        else
        {
            mostRecentPushDown = fractalCandleIndex;
        }

        // make sure we pushed below
        bool bearish = iClose(EntrySymbol(), EntryTimeFrame(), mostRecentPushDown) < iOpen(EntrySymbol(), EntryTimeFrame(), mostRecentPushDown);
        for (int i = mostRecentPushDown; i >= highestIndex; i--)
        {
            if (iClose(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), mostRecentPushDown))
            {
                double percentBody = CandleStickHelper::PercentBody(EntrySymbol(), EntryTimeFrame(), i);
                double bodyLength = CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), i);
                bool singleCandleImpulse = /*percentBody >= 0.9*/ !bearish && bodyLength >= PipConverter::PipsToPoints(mLargeBodyPips);

                bool pushedFurther = iHigh(EntrySymbol(), EntryTimeFrame(), i) - iHigh(EntrySymbol(), EntryTimeFrame(), mostRecentPushDown) >= PipConverter::PipsToPoints(mPushFurtherPips);
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
            if (iClose(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), mostRecentPushDown))
            {
                if (i > 5)
                {
                    return hasTicket;
                }

                bool largeBody = CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), i) >= PipConverter::PipsToPoints(mLargeBodyPips);
                bool hasImpulse = CandleStickHelper::HasImbalance(SignalType::Bearish, EntrySymbol(), EntryTimeFrame(), i) ||
                                  CandleStickHelper::HasImbalance(SignalType::Bearish, EntrySymbol(), EntryTimeFrame(), i + 1);

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
            if (CandleStickHelper::IsBullish(EntrySymbol(), EntryTimeFrame(), i))
            {
                if (CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), i) > PipConverter::PipsToPoints(mLargeBodyPips))
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
        bool twoPreviousIsBearish = iOpen(EntrySymbol(), EntryTimeFrame(), 2) > iClose(EntrySymbol(), EntryTimeFrame(), 2);
        bool previousIsBullish = iOpen(EntrySymbol(), EntryTimeFrame(), 1) < iClose(EntrySymbol(), EntryTimeFrame(), 1);
        bool previousDoesNotBreakAboveTwoPrevious = iClose(EntrySymbol(), EntryTimeFrame(), 1) < iHigh(EntrySymbol(), EntryTimeFrame(), 2);

        if (!twoPreviousIsBearish || !previousIsBullish || !previousDoesNotBreakAboveTwoPrevious)
        {
            return hasTicket;
        }
    }

    mBreakCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), breakCandleIndex);
    return true;
}

void MBInnerBreak::PlaceOrders()
{
    int currentBars = iBars(EntrySymbol(), EntryTimeFrame());
    if (currentBars <= BarCount())
    {
        return;
    }

    if (!mCurrentSetupTickets.IsEmpty())
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

    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        int breakCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mBreakCandleTime);
        double lowest = -1.0;
        if (!MQLHelper::GetLowestLowBetween(EntrySymbol(), EntryTimeFrame(), breakCandleIndex - 1, 0, true, lowest))
        {
            return;
        }

        entry = iHigh(EntrySymbol(), EntryTimeFrame(), 1) + PipConverter::PipsToPoints(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - PipConverter::PipsToPoints(mStopLossPaddingPips), entry - PipConverter::PipsToPoints(mMinStopLossPips));
    }
    else if (SetupType() == SignalType::Bearish)
    {
        int breakCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mBreakCandleTime);
        double highest = -1.0;
        if (!MQLHelper::GetHighestHighBetween(EntrySymbol(), EntryTimeFrame(), breakCandleIndex - 1, 0, true, highest))
        {
            return;
        }

        entry = iLow(EntrySymbol(), EntryTimeFrame(), 1) - PipConverter::PipsToPoints(mEntryPaddingPips);
        stopLoss = MathMax(highest + PipConverter::PipsToPoints(mStopLossPaddingPips) + PipConverter::PipsToPoints(mMaxSpreadPips),
                           entry + PipConverter::PipsToPoints(mMinStopLossPips));
    }

    EAOrderHelper::PlaceStopOrder<MBInnerBreak>(this, entry, stopLoss);

    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLastEntryMB = mostRecentMB.Number();
        mEntryCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 1);
    }
}

void MBInnerBreak::PreManageTickets()
{
}

void MBInnerBreak::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
    int entryCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);

    if (SetupType() == SignalType::Bullish && entryCandleIndex > 1)
    {
        if (iLow(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
        {
            // Print("Broke Below Invalidatino");
            InvalidateSetup(true);
        }
    }
    else if (SetupType() == SignalType::Bearish && entryCandleIndex > 1)
    {
        if (iHigh(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void MBInnerBreak::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    // int selectError = ticket.SelectIfOpen("Stuff");
    // if (TerminalErrors::IsTerminalError(selectError))
    // {
    //     RecordError(selectError);
    //     return;
    // }

    // int entryIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    // bool movedPips = false;

    // if (SetupType() == SignalType::Bullish)
    // {
    //     if (entryIndex > 5)
    //     {
    //         // close if we are still opening within our entry and get the chance to close at BE
    //         if (iOpen(EntrySymbol(), EntryTimeFrame(), 1) < iHigh(EntrySymbol(), EntryTimeFrame(), entryIndex) && CurrentTick().Bid() >= OrderOpenPrice())
    //         {
    //             ticket.Close();
    //         }
    //     }

    //     // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
    //     // close if we break a low within our stop loss
    //     if (entryIndex <= 200)
    //     {
    //         // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
    //         for (int i = entryIndex - 2; i >= 0; i--)
    //         {
    //             if (iLow(EntrySymbol(), EntryTimeFrame(), i) > OrderOpenPrice())
    //             {
    //                 break;
    //             }

    //             for (int j = entryIndex; j > i; j--)
    //             {
    //                 if (iLow(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), j))
    //                 {
    //                     // managed to break back out, close at BE
    //                     if (CurrentTick().Bid() >= OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips))
    //                     {
    //                         ticket.Close();
    //                         return;
    //                     }

    //                     // pushed too far into SL, take the -0.5
    //                     if (EAHelper::CloseIfPercentIntoStopLoss<MBInnerBreak>(this, ticket, 0.5))
    //                     {
    //                         return;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     else
    //     {
    //         // TOD: Create error code
    //         string additionalInformation = "Entry Index: " + entryIndex;
    //         RecordError(-1, additionalInformation);
    //     }

    //     // get too close to our entry after 5 candles and coming back
    //     if (entryIndex >= 5)
    //     {
    //         if (mLastManagedBid > OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips) &&
    //             CurrentTick().Bid() <= OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips))
    //         {
    //             ticket.Close();
    //             return;
    //         }
    //     }

    //     movedPips = CurrentTick().Bid() - OrderOpenPrice() >= PipConverter::PipsToPoints(mPipsToWaitBeforeBE);
    // }
    // else if (SetupType() == SignalType::Bearish)
    // {
    //     // early close
    //     if (entryIndex > 5)
    //     {
    //         // close if we are still opening above our entry and we get the chance to close at BE
    //         if (iOpen(EntrySymbol(), EntryTimeFrame(), 1) > iLow(EntrySymbol(), EntryTimeFrame(), entryIndex) && CurrentTick().Ask() <= OrderOpenPrice())
    //         {
    //             ticket.Close();
    //         }
    //     }

    //     // middle close
    //     // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
    //     // close if we break a high within our stop loss
    //     if (entryIndex <= 200)
    //     {
    //         // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
    //         for (int i = entryIndex - 2; i >= 0; i--)
    //         {
    //             if (iHigh(EntrySymbol(), EntryTimeFrame(), i) < OrderOpenPrice())
    //             {
    //                 break;
    //             }

    //             for (int j = entryIndex; j > i; j--)
    //             {
    //                 if (iHigh(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), j))
    //                 {
    //                     // managed to break back out, close at BE
    //                     if (CurrentTick().Ask() <= OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips))
    //                     {
    //                         ticket.Close();
    //                         return;
    //                     }

    //                     // pushed too far into SL, take the -0.5
    //                     if (EAHelper::CloseIfPercentIntoStopLoss<MBInnerBreak>(this, ticket, 0.5))
    //                     {
    //                         return;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     else
    //     {
    //         // TOD: Create error code
    //         string additionalInformation = "Entry Index: " + entryIndex;
    //         RecordError(-1, additionalInformation);
    //     }

    //     // get too close to our entry after 5 candles and coming back
    //     if (entryIndex >= 5)
    //     {
    //         if (mLastManagedAsk < OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips) &&
    //             CurrentTick().Ask() >= OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips))
    //         {
    //             ticket.Close();
    //             return;
    //         }
    //     }

    //     movedPips = OrderOpenPrice() - CurrentTick().Ask() >= PipConverter::PipsToPoints(mPipsToWaitBeforeBE);
    // }

    // if (movedPips)
    // {
    //     EAHelper::MoveTicketToBreakEvenAsSoonAsPossible<MBInnerBreak>(this, ticket, mBEAdditionalPips);
    // }

    EAOrderHelper::MoveToBreakEvenAfterPips<MBInnerBreak>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
    // mLastManagedAsk = CurrenTick().Ask();
    // mLastManagedBid = CurrenTick().Bid();
}

bool MBInnerBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAOrderHelper::TicketStopLossIsMovedToBreakEven<MBInnerBreak>(this, ticket);
}

void MBInnerBreak::ManagePreviousSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<MBInnerBreak>(this, ticket);
}

void MBInnerBreak::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void MBInnerBreak::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void MBInnerBreak::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<MBInnerBreak>(this, ticket);
}

void MBInnerBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EARecordHelper::RecordPartialTradeRecord<MBInnerBreak>(this, partialedTicket, newTicketNumber);
}

void MBInnerBreak::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<MBInnerBreak>(this, ticket);
}

void MBInnerBreak::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<MBInnerBreak>(this, methodName, error, additionalInformation);
}

bool MBInnerBreak::ShouldReset()
{
    return false;
}

void MBInnerBreak::Reset()
{
}