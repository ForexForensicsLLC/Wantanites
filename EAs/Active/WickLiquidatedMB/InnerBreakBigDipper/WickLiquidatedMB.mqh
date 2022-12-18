//+------------------------------------------------------------------+
//|                                                    WickLiquidatedMB.mqh |
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

class WickLiquidatedMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    datetime mWickLiquidatedMBTime;
    datetime mInnerStructureTime;
    bool mDecentPushAfterInnerStructure;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;
    double mLargeBodyPips;
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
    WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~WickLiquidatedMB();

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

WickLiquidatedMB::WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mWickLiquidatedMBTime = 0;
    mInnerStructureTime = 0;
    mDecentPushAfterInnerStructure = false;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mBreakCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;
    mLargeBodyPips = 0.0;
    mPushFurtherPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedBid = 0.0;
    mLastManagedAsk = 0.0;

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<WickLiquidatedMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<WickLiquidatedMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<WickLiquidatedMB, SingleTimeFrameEntryTradeRecord>(this);
}

WickLiquidatedMB::~WickLiquidatedMB()
{
}

void WickLiquidatedMB::Run()
{
    EAHelper::RunDrawMBT<WickLiquidatedMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool WickLiquidatedMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<WickLiquidatedMB>(this) && EAHelper::WithinTradingSession<WickLiquidatedMB>(this);
}

void WickLiquidatedMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<WickLiquidatedMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (mSetupType == OP_BUY)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) &&
                CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
            {
                mWickLiquidatedMBTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
                mHasSetup = true;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) &&
                CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
            {
                mWickLiquidatedMBTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
                mHasSetup = true;
            }
        }
    }
}

void WickLiquidatedMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
            return;
        }
    }

    if (mWickLiquidatedMBTime != 0)
    {
        int wickLiquidatedMBIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mWickLiquidatedMBTime);
        if (mSetupType == OP_BUY && iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, wickLiquidatedMBIndex))
        {
            InvalidateSetup(true);
            return;
        }
        else if (mSetupType == OP_SELL && iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, wickLiquidatedMBIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void WickLiquidatedMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<WickLiquidatedMB>(this, deletePendingOrder, false, error);

    mFirstMBInSetupNumber = EMPTY;
    mWickLiquidatedMBTime = 0;
    mInnerStructureTime = 0;
    mDecentPushAfterInnerStructure = false;
}

bool WickLiquidatedMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    int wickLiquidatedMBIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mWickLiquidatedMBTime);
    int breakCandleIndex = EMPTY;
    if (mSetupType == OP_BUY)
    {
        // find most recent push up
        if (mInnerStructureTime == 0)
        {
            int mostRecentPushUp = EMPTY;
            int bullishCandleIndex = EMPTY;
            int fractalCandleIndex = EMPTY;
            bool pushedBelowMostRecentPushUp = false;

            for (int i = wickLiquidatedMBIndex - 1; i >= 1; i--)
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

            if (fractalCandleIndex == EMPTY)
            {
                mostRecentPushUp = bullishCandleIndex;
            }
            else if (bullishCandleIndex == EMPTY)
            {
                mostRecentPushUp = fractalCandleIndex;
            }
            else if (fractalCandleIndex > bullishCandleIndex)
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

            if (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp) > iHigh(mEntrySymbol, mEntryTimeFrame, wickLiquidatedMBIndex))
            {
                return false;
            }

            mInnerStructureTime = iTime(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp);
        }

        int mostRecentPushUp = iBarShift(mEntrySymbol, mEntryTimeFrame, mInnerStructureTime);

        // make sure we pushed below
        // needs to be 2 since we are looking for an imbalance as well
        for (int i = mostRecentPushUp; i >= 2; i--)
        {
            bool pushedFurther = (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, mostRecentPushUp) -
                                  CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, i)) >= OrderHelper::PipsToRange(mPushFurtherPips);

            bool largeBody = CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i) &&
                             CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i) &&
                             CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mLargeBodyPips);

            if (pushedFurther || largeBody)
            {
                mDecentPushAfterInnerStructure = true;
                break;
            }
        }

        if (!mDecentPushAfterInnerStructure)
        {
            return false;
        }

        // find first break above
        bool brokePushUp = false;
        for (int i = mostRecentPushUp - 1; i >= 1; i--)
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
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mLargeBodyPips))
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
        // find most recent push up
        if (mInnerStructureTime == 0)
        {
            // find most recent push up
            int mostRecentPushDown = EMPTY;
            int bearishCandleIndex = EMPTY;
            int fractalCandleIndex = EMPTY;
            bool pushedAboveMostRecentPushDown = false;

            for (int i = wickLiquidatedMBIndex - 1; i >= 1; i--)
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

            if (fractalCandleIndex == EMPTY)
            {
                mostRecentPushDown = bearishCandleIndex;
            }
            else if (bearishCandleIndex == EMPTY)
            {
                mostRecentPushDown = fractalCandleIndex;
            }
            else if (fractalCandleIndex > bearishCandleIndex)
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

            if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown) < iLow(mEntrySymbol, mEntryTimeFrame, wickLiquidatedMBIndex))
            {
                return false;
            }

            mInnerStructureTime = iTime(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown);
        }

        int mostRecentPushDown = iBarShift(mEntrySymbol, mEntryTimeFrame, mInnerStructureTime);

        // make sure we pushed back up
        for (int i = mostRecentPushDown - 1; i >= 2; i--)
        {
            bool pushedFurther = (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, i) -
                                  CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, mostRecentPushDown)) >= OrderHelper::PipsToRange(mPushFurtherPips);

            bool largeBody = CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i) &&
                             CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i) &&
                             CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mLargeBodyPips);

            if (pushedFurther || largeBody)
            {
                mDecentPushAfterInnerStructure = true;
                break;
            }
        }

        if (!mDecentPushAfterInnerStructure)
        {
            return false;
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
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mLargeBodyPips))
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

void WickLiquidatedMB::PlaceOrders()
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
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<WickLiquidatedMB>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void WickLiquidatedMB::ManageCurrentPendingSetupTicket()
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

void WickLiquidatedMB::ManageCurrentActiveSetupTicket()
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
                        if (EAHelper::CloseIfPercentIntoStopLoss<WickLiquidatedMB>(this, mCurrentSetupTicket, 0.5))
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
                        if (EAHelper::CloseIfPercentIntoStopLoss<WickLiquidatedMB>(this, mCurrentSetupTicket, 0.5))
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<WickLiquidatedMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool WickLiquidatedMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<WickLiquidatedMB>(this, ticket);
}

void WickLiquidatedMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<WickLiquidatedMB>(this, mPreviousSetupTickets[ticketIndex]);
}

void WickLiquidatedMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickLiquidatedMB>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<WickLiquidatedMB>(this);
}

void WickLiquidatedMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickLiquidatedMB>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<WickLiquidatedMB>(this, ticketIndex);
}

void WickLiquidatedMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<WickLiquidatedMB>(this);
}

void WickLiquidatedMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickLiquidatedMB>(this, partialedTicket, newTicketNumber);
}

void WickLiquidatedMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<WickLiquidatedMB>(this, ticket, Period());
}

void WickLiquidatedMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<WickLiquidatedMB>(this, error, additionalInformation);
}

void WickLiquidatedMB::Reset()
{
}