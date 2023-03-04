//+------------------------------------------------------------------+
//|                                                    ReversalInnerBreak.mqh |
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

class ReversalInnerBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    int mFirstMBInSetupNumber;

    int mBarCount;
    int mEntryTimeFrame;
    string mEntrySymbol;

    double mMinDistanceFromPreviousMBRun;

    double mEntryPaddingPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;
    double mLargeBodyPips;
    double mPushFurtherPips;

    int mLastEntryMB;
    datetime mEntryCandleTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    ReversalInnerBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ReversalInnerBreak();

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

ReversalInnerBreak::ReversalInnerBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mBarCount = 0;
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mMinDistanceFromPreviousMBRun = 0.0;

    mEntryPaddingPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;
    mLargeBodyPips = 0.0;
    mPushFurtherPips = 0.0;

    mEntryCandleTime = 0;
    mLastEntryMB = EMPTY;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ReversalInnerBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ReversalInnerBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ReversalInnerBreak, SingleTimeFrameEntryTradeRecord>(this);
}

ReversalInnerBreak::~ReversalInnerBreak()
{
}

double ReversalInnerBreak::RiskPercent()
{
    return mRiskPercent;
}

void ReversalInnerBreak::Run()
{
    EAHelper::RunDrawMBT<ReversalInnerBreak>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ReversalInnerBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<ReversalInnerBreak>(this) && EAHelper::WithinTradingSession<ReversalInnerBreak>(this) &&
           mLastEntryMB < mSetupMBT.MBsCreated() - 1;
}

void ReversalInnerBreak::CheckSetSetup()
{
    // looking for opposite MB
    int setupType = mSetupType == OP_BUY ? OP_SELL : OP_BUY;
    if (EAHelper::CheckSetSingleMBSetup<ReversalInnerBreak>(this, mSetupMBT, mFirstMBInSetupNumber, setupType))
    {
        mHasSetup = true;
    }
}

void ReversalInnerBreak::CheckInvalidateSetup()
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

void ReversalInnerBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ReversalInnerBreak>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
}

bool ReversalInnerBreak::Confirmation()
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

    int pendingMBStart = EMPTY;

    int fractalCandleIndex = EMPTY;
    int oppositeCandleIndex = EMPTY;
    int mostRecentInnerStructure = EMPTY;
    double closestsPointToMB = EMPTY;
    int breakInnerStructureIndex = EMPTY;
    bool imbalanceAfterInnerStructure = false;

    if (mSetupType == OP_BUY)
    {
        // need opposite retracement
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        // ned to run x pips after the previous mb
        if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) <
            OrderHelper::PipsToRange(mMinDistanceFromPreviousMBRun))
        {
            return false;
        }

        for (int i = pendingMBStart + 1; i <= tempMBState.EndIndex(); i++)
        {
            if (oppositeCandleIndex == EMPTY && iClose(mEntrySymbol, mEntryTimeFrame, i) > iOpen(mEntrySymbol, mEntryTimeFrame, i))
            {
                oppositeCandleIndex = i;
            }

            if (fractalCandleIndex == EMPTY &&
                iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i - 1))
            {
                fractalCandleIndex = i;
            }

            if (oppositeCandleIndex != EMPTY && fractalCandleIndex != EMPTY)
            {
                break;
            }
        }

        if (oppositeCandleIndex == EMPTY && fractalCandleIndex == EMPTY)
        {
            return false;
        }

        if (fractalCandleIndex > oppositeCandleIndex)
        {
            mostRecentInnerStructure = oppositeCandleIndex;
        }
        else if (iHigh(mEntrySymbol, mEntryTimeFrame, oppositeCandleIndex) > iHigh(mEntrySymbol, mEntryTimeFrame, fractalCandleIndex))
        {
            mostRecentInnerStructure = oppositeCandleIndex;
        }
        else
        {
            mostRecentInnerStructure = fractalCandleIndex;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, mostRecentInnerStructure, 0, true, closestsPointToMB))
        {
            return false;
        }

        // ignore the setup if we pushed back into the previuos mb
        if (closestsPointToMB > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        {
            return false;
        }

        // need to have a decent push after the inner structure for it to be valid
        if (iLow(mEntrySymbol, mEntryTimeFrame, mostRecentInnerStructure) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) <
            OrderHelper::PipsToRange(mPushFurtherPips))
        {
            return false;
        }

        for (int i = mostRecentInnerStructure; i >= pendingMBStart; i--)
        {
            if (CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i))
            {
                imbalanceAfterInnerStructure = true;
                break;
            }
        }

        if (!imbalanceAfterInnerStructure)
        {
            return false;
        }

        // find first break above
        for (int i = mostRecentInnerStructure - 1; i >= 1; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, mostRecentInnerStructure))
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
                    breakInnerStructureIndex = i;
                    break;
                }
                else
                {
                    return hasTicket;
                }
            }
        }

        if (breakInnerStructureIndex == EMPTY)
        {
            return false;
        }

        int bearishCandleCount = 0;
        for (int i = breakInnerStructureIndex - 1; i >= 1; i--)
        {
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mLargeBodyPips))
                {
                    return false;
                }

                bearishCandleCount += 1;
            }

            if (bearishCandleCount > 1 || (bearishCandleCount == 1 && breakInnerStructureIndex > 5))
            {
                return false;
            }
        }

        // Big Dipper Entry
        bool twoPreviousIsBullish = iOpen(mEntrySymbol, mEntryTimeFrame, 2) < iClose(mEntrySymbol, mEntryTimeFrame, 2);
        bool previousIsBearish = iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iClose(mEntrySymbol, mEntryTimeFrame, 1);
        // bool previousDoesNotBreakBelowTwoPrevious = iClose(mEntrySymbol, mEntryTimeFrame, 1) >= iLow(mEntrySymbol, mEntryTimeFrame, 2);

        if (!twoPreviousIsBullish || !previousIsBearish /*|| !previousDoesNotBreakBelowTwoPrevious*/)
        {
            return hasTicket;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // need opposite retracement
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        // ned to run x pips after the previous mb
        if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) <
            OrderHelper::PipsToRange(mMinDistanceFromPreviousMBRun))
        {
            return false;
        }

        // find closests structure point
        for (int i = pendingMBStart + 1; i <= tempMBState.EndIndex(); i++)
        {
            if (oppositeCandleIndex == EMPTY && iClose(mEntrySymbol, mEntryTimeFrame, i) < iOpen(mEntrySymbol, mEntryTimeFrame, i))
            {
                oppositeCandleIndex = i;
            }

            if (fractalCandleIndex == EMPTY &&
                iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i - 1))
            {
                fractalCandleIndex = i;
            }

            if (oppositeCandleIndex != EMPTY && fractalCandleIndex != EMPTY)
            {
                break;
            }
        }

        if (oppositeCandleIndex == EMPTY && fractalCandleIndex == EMPTY)
        {
            return false;
        }

        // find the closests structure point
        if (fractalCandleIndex > oppositeCandleIndex)
        {
            mostRecentInnerStructure = oppositeCandleIndex;
        }
        else if (iLow(mEntrySymbol, mEntryTimeFrame, oppositeCandleIndex) < iLow(mEntrySymbol, mEntryTimeFrame, fractalCandleIndex))
        {
            mostRecentInnerStructure = oppositeCandleIndex;
        }
        else
        {
            mostRecentInnerStructure = fractalCandleIndex;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, mostRecentInnerStructure, 0, true, closestsPointToMB))
        {
            return false;
        }

        if (closestsPointToMB < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        {
            return false;
        }

        // need to have a decent push after the inner structure for it to be valid
        if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iHigh(mEntrySymbol, mEntryTimeFrame, mostRecentInnerStructure) <
            OrderHelper::PipsToRange(mPushFurtherPips))
        {
            return false;
        }

        for (int i = mostRecentInnerStructure; i >= pendingMBStart; i--)
        {
            if (CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i))
            {
                imbalanceAfterInnerStructure = true;
                break;
            }
        }

        if (!imbalanceAfterInnerStructure)
        {
            return false;
        }

        // wait to break above
        for (int i = mostRecentInnerStructure; i >= 1; i--)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, mostRecentInnerStructure))
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
                    breakInnerStructureIndex = i;
                    break;
                }
                else
                {
                    return hasTicket;
                }
            }
        }

        if (breakInnerStructureIndex == EMPTY)
        {
            return false;
        }

        int bullishCandleCount = 0;
        for (int i = breakInnerStructureIndex - 1; i >= 1; i--)
        {
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                if (CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, i) > OrderHelper::PipsToRange(mLargeBodyPips))
                {
                    return false;
                }

                bullishCandleCount += 1;
            }

            if (bullishCandleCount > 1 || (bullishCandleCount == 1 && breakInnerStructureIndex > 5))
            {
                return false;
            }
        }

        // Big Dipper Entry
        // Need Bullish -> Bearish - > Bullish after inner break
        bool twoPreviousIsBearish = iOpen(mEntrySymbol, mEntryTimeFrame, 2) > iClose(mEntrySymbol, mEntryTimeFrame, 2);
        bool previousIsBullish = iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iClose(mEntrySymbol, mEntryTimeFrame, 1);
        // bool previousDoesNotBreakAboveTwoPrevious = iClose(mEntrySymbol, mEntryTimeFrame, 1) <= iHigh(mEntrySymbol, mEntryTimeFrame, 2);

        if (!twoPreviousIsBearish || !previousIsBullish /*|| !previousDoesNotBreakAboveTwoPrevious*/)
        {
            return hasTicket;
        }
    }

    return true;
}

void ReversalInnerBreak::PlaceOrders()
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

    EAHelper::PlaceStopOrder<ReversalInnerBreak>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ReversalInnerBreak::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void ReversalInnerBreak::ManageCurrentActiveSetupTicket()
{
    if (!mLastEntryMB != mFirstMBInSetupNumber)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
    }

    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // if (EAHelper::CloseIfPercentIntoStopLoss<ReversalInnerBreak>(this, mCurrentSetupTicket, 0.5))
    // {
    //     return;
    // }

    // int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    // if (TerminalErrors::IsTerminalError(selectError))
    // {
    //     RecordError(selectError);
    //     return;
    // }

    // MqlTick currentTick;
    // if (!SymbolInfoTick(Symbol(), currentTick))
    // {
    //     RecordError(GetLastError());
    //     return;
    // }

    // int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    // bool movedPips = false;

    // if (mSetupType == OP_BUY)
    // {
    //     movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    // }

    // if (movedPips)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<ReversalInnerBreak>(this, mBEAdditionalPip);
    // }

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
                        if (EAHelper::CloseIfPercentIntoStopLoss<ReversalInnerBreak>(this, mCurrentSetupTicket, 0.5))
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
                        if (EAHelper::CloseIfPercentIntoStopLoss<ReversalInnerBreak>(this, mCurrentSetupTicket, 0.5))
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ReversalInnerBreak>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool ReversalInnerBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ReversalInnerBreak>(this, ticket);
}

void ReversalInnerBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<ReversalInnerBreak>(this, mPreviousSetupTickets[ticketIndex]);
}

void ReversalInnerBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ReversalInnerBreak>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ReversalInnerBreak>(this);
}

void ReversalInnerBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ReversalInnerBreak>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ReversalInnerBreak>(this, ticketIndex);
}

void ReversalInnerBreak::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ReversalInnerBreak>(this);
}

void ReversalInnerBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ReversalInnerBreak>(this, partialedTicket, newTicketNumber);
}

void ReversalInnerBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ReversalInnerBreak>(this, ticket, Period());
}

void ReversalInnerBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ReversalInnerBreak>(this, error, additionalInformation);
}

void ReversalInnerBreak::Reset()
{
}