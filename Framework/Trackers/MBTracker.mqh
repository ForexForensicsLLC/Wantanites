//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>
#include <SummitCapital\Framework\Objects\MB.mqh>

class MBTracker
{
private:
    // --- Operation Variables ---
    int mTimeFrame;
    string mSymbol;
    int mPrevCalculated;
    datetime mFirstBarTime;
    bool mInitialLoad;
    bool mPrintErrors;     // used to prevent printing errors on obj creation. Should be used on 1 second chart to save resources
    bool mCalculateOnTick; // Needs to be true when on the 1 second chart or else we'll miss values

    // --- MB Counting / Tracking---
    int mMBsToTrack;
    int mCurrentMBs;
    int mMBsCreated;

    int mCurrentBullishRetracementIndex;
    int mCurrentBearishRetracementIndex;

    bool mPendingBullishMB;
    bool mPendingBearishMB;

    int mPendingBullishMBLowIndex;
    int mPendingBearishMBHighIndex;

    // --- Zone Counting / Tracking---
    int mMaxZonesInMB;
    bool mAllowZoneMitigation;
    bool mAllowZonesAfterMBValidation;
    bool mAllowZoneWickBreaks;

    MB *mMBs[];

    // --- Tracking Methods ---
    void init(string symbol, int timeFrame,
              int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool allowZoneWickBreaks, bool printErrors, bool calculateOnTick);
    void Update();
    int MostRecentMBIndex() { return mMBsToTrack - mCurrentMBs; }

    // --- MB Creation Methods ---
    // Tested
    void CalculateMB(int barIndex);

    bool IsEngulfingCandle(int mbType, int index);

    // Tested
    void CheckSetRetracement(int startingIndex, int mbType, int prevMBType);

    // Tested
    void CheckSetPendingMB(int startingIndex, int mbType);

    // Tested
    void CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex);
    void ResetTracking();

    // --------- Helper Methods ----------------
    bool InternalHasNMostRecentConsecutiveMBs(int nMBs);
    bool InternalNthMostRecentMBIsOpposite(int nthMB);

public:
    //  --- Getters ---
    string Symbol() { return mSymbol; }
    int TimeFrame() { return mTimeFrame; }

    // --- Constructors / Destructors ---
    MBTracker(string symbol, int timeFrame,
              int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool allowZoneWickBreaks, bool printErrors, bool calculateOnTick);
    ~MBTracker();

    // --- Maintenance Methods ---
    void UpdateIndexes(int barIndex);

    // --- Computer Properties
    bool CurrentBullishRetracementIndexIsValid(out int &currentBullishRetracementIndex, int barIndex);
    bool CurrentBearishRetracementIndexIsValid(out int &currentBearishRetracementIndex, int barIndex);

    bool MBExists(int mbNumber);
    bool GetNthMostRecentMB(int nthMB, MBState *&mbState);
    bool GetNMostRecentMBs(int nMostRecent, MBState *&mbStates[]);
    bool GetMB(int mbNumber, MBState *&mbState);
    bool GetPreviousMB(int mbNumber, MBState *&mbState);
    bool GetSubsequentMB(int mbNumber, MBState *&mbState);

    bool HasNMostRecentConsecutiveMBs(int nMBs);
    bool HasNMostRecentConsecutiveMBs(int nMBs, MBState *&mbStates[]);

    bool NthMostRecentMBIsOpposite(int nthMB);
    bool NthMostRecentMBIsOpposite(int nthMB, MBState *&mbState[]);
    bool MBIsOpposite(int mbNumber);

    int NumberOfConsecutiveMBsBeforeNthMostRecent(int nthMB);

    bool MBIsMostRecent(int mbNumber);
    bool MBIsMostRecent(int mbNumber, MBState *&mbState);

    string ToString(int mbsToPrint);
    string ToSingleLineString(int mbsToPrint);

    // --- MB Display Methods ---
    void PrintNMostRecentMBs(int nMBs);
    void DrawNMostRecentMBs(int nMBs);

    // --- Zone Retrieval Methods ---
    bool GetNthMostRecentMBsUnretrievedZones(int nthMB, ZoneState *&zoneState[]);
    bool GetNMostRecentMBsUnretrievedZones(int nMBs, ZoneState *&zoneStates[]);
    bool GetNthMostRecentMBsClosestValidZone(int nthMB, ZoneState *&zoneState);

    bool NthMostRecentMBsClosestValidZoneIsHolding(int nthMB, ZoneState *&zoneState, int barIndex);
    bool MBsClosestValidZoneIsHolding(int mbNumber, int barIndex);

    // -- Zone Display Methods --
    void DrawZonesForNMostRecentMBs(int nMBs);
};

// ##############################################################
// ####################### Private Methods ######################
// ##############################################################

//----------------------- Tracking Methods ----------------------
void MBTracker::init(string symbol, int timeFrame,
                     int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool allowZoneWickBreaks, bool printErrors, bool calculateOnTick)
{
    mSymbol = symbol;
    mTimeFrame = timeFrame;
    mPrevCalculated = 0;
    mFirstBarTime = 0;
    mInitialLoad = true;
    mPrintErrors = printErrors;
    mCalculateOnTick = calculateOnTick;

    mMBsToTrack = mbsToTrack;
    mMaxZonesInMB = maxZonesInMB;
    mMBsCreated = 0;
    mAllowZoneMitigation = allowZoneMitigation;
    mAllowZonesAfterMBValidation = allowZonesAfterMBValidation;
    mAllowZoneWickBreaks = allowZoneWickBreaks;

    mCurrentBullishRetracementIndex = -1;
    mCurrentBearishRetracementIndex = -1;

    ArrayResize(mMBs, mbsToTrack);

    Update();
}

void MBTracker::Update()
{
    // how many bars are available to calcualte
    int bars = iBars(mSymbol, mTimeFrame);
    datetime firstBarTime = iTime(mSymbol, mTimeFrame, bars - 1);

    // how many bars to calculate
    int limit = bars - mPrevCalculated;

    if (!mInitialLoad && limit == 1)
    {
        UpdateIndexes(limit);
    }

    if (mFirstBarTime != firstBarTime)
    {
        limit = bars;
        mFirstBarTime = firstBarTime;
    }

    if (mCalculateOnTick && limit == 0)
    {
        limit += 1;
    }

    // Calcualte MBs for each bar we have left
    for (int i = limit - 1; i >= 0; i--)
    {
        CalculateMB(i);
    }

    mPrevCalculated = bars;
    mInitialLoad = false;
}

//----------------------- MB Creation Methods ----------------------------
void MBTracker::CalculateMB(int barIndex)
{
    if (CheckPointer(mMBs[mMBsToTrack - 1]) == POINTER_INVALID)
    {
        CheckSetRetracement(barIndex, OP_BUY, -1);
        CheckSetPendingMB(barIndex, OP_BUY);

        CheckSetRetracement(barIndex, OP_SELL, -1);
        CheckSetPendingMB(barIndex, OP_SELL);

        // validated Bullish MB
        if (mPendingBullishMB && iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
        {
            CreateMB(OP_BUY, mCurrentBullishRetracementIndex, barIndex, mCurrentBullishRetracementIndex, mPendingBullishMBLowIndex);
            ResetTracking();
            return;
        }
        // validated Bearish MB
        else if (mPendingBearishMB && iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
        {
            CreateMB(OP_SELL, mCurrentBearishRetracementIndex, barIndex, mPendingBearishMBHighIndex, mCurrentBearishRetracementIndex);
            ResetTracking();
            return;
        }
    }
    // prev mb was bullish
    else if (mMBs[MostRecentMBIndex()].Type() == OP_BUY)
    {
        // first check to make sure we didn't break our previous MB
        if (iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mMBs[MostRecentMBIndex()].LowIndex()))
        {
            int highestIndex;
            if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBs[MostRecentMBIndex()].StartIndex() - barIndex, barIndex, false, highestIndex))
            {
                return;
            }

            CreateMB(OP_SELL, mMBs[MostRecentMBIndex()].LowIndex(), barIndex, highestIndex, mMBs[MostRecentMBIndex()].LowIndex());
            ResetTracking();

            return;
        }

        // check pending first so that a single candle can trigger the pending flag and confirm an MB else retracement will get reset in CheckSetRetracement()
        CheckSetPendingMB(barIndex, OP_BUY);
        CheckSetRetracement(barIndex, OP_BUY, OP_BUY);

        if (mPendingBullishMB)
        {
            // new bullish mb has been validated
            if (iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
            {
                // only create the mb if it is longer than 1 candle
                int bullishRetracementIndex = -1;
                if (CurrentBullishRetracementIndexIsValid(bullishRetracementIndex, barIndex))
                {
                    CreateMB(OP_BUY, bullishRetracementIndex, barIndex, bullishRetracementIndex, mPendingBullishMBLowIndex);
                }

                ResetTracking();
            }
        }
        // only allow the most recent MB to have zones after it has been validated if there is no pending MB
        else if (mAllowZonesAfterMBValidation)
        {
            mMBs[MostRecentMBIndex()].CheckAddZonesAfterMBValidation(barIndex, mAllowZoneMitigation);
        }
    }
    // prev mb was bearish
    else if (mMBs[MostRecentMBIndex()].Type() == OP_SELL)
    {
        // first check to make sure we didn't break our previous mb
        if (iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mMBs[MostRecentMBIndex()].HighIndex()))
        {
            int lowestIndex = 0;
            if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, mMBs[MostRecentMBIndex()].StartIndex() - barIndex, barIndex, false, lowestIndex))
            {
                return;
            }

            CreateMB(OP_BUY, mMBs[MostRecentMBIndex()].HighIndex(), barIndex, mMBs[MostRecentMBIndex()].HighIndex(), lowestIndex);
            ResetTracking();

            return;
        }

        // check pending first so that a single candle can trigger the pending flag and confirm an MB else retracement will get reset in CheckSetRetracement()
        CheckSetPendingMB(barIndex, OP_SELL);
        CheckSetRetracement(barIndex, OP_SELL, OP_SELL);

        if (mPendingBearishMB)
        {
            // new bearish mb has been validated
            if (iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
            {
                int bearishRetracementIndex = -1;
                if (CurrentBearishRetracementIndexIsValid(bearishRetracementIndex, barIndex))
                {
                    CreateMB(OP_SELL, bearishRetracementIndex, barIndex, mPendingBearishMBHighIndex, bearishRetracementIndex);
                }

                ResetTracking();
            }
        }
        // only allow the most recent MB to have zones after it has been validated if there is no pending MB
        else if (mAllowZonesAfterMBValidation)
        {
            mMBs[MostRecentMBIndex()].CheckAddZonesAfterMBValidation(barIndex, mAllowZoneMitigation);
        }
    }
}

bool MBTracker::IsEngulfingCandle(int mbType, int index)
{
    if (mbType == OP_BUY)
    {
        double retracementOpen = iOpen(mSymbol, mTimeFrame, index);
        double retracementClose = iClose(mSymbol, mTimeFrame, index);
        double retracementHigh = iHigh(mSymbol, mTimeFrame, index);
        double retracementLow = iLow(mSymbol, mTimeFrame, index);

        double candleBeforeRetracementLow = iLow(mSymbol, mTimeFrame, index + 1);
        double candelBeforeRetracementHigh = iHigh(mSymbol, mTimeFrame, index + 1);

        // check if the retracement candle is a bullish candle that started and validated an MB on its own. This won't get checked in other logic
        // if there are a few candles after the retracment that don't break it
        if (retracementOpen < retracementClose && retracementLow < candleBeforeRetracementLow && retracementHigh > candelBeforeRetracementHigh)
        {
            return true;
        }
    }
    else if (mbType == OP_SELL)
    {
        double retracementOpen = iOpen(mSymbol, mTimeFrame, index);
        double retracementClose = iClose(mSymbol, mTimeFrame, index);
        double retracementHigh = iHigh(mSymbol, mTimeFrame, index);
        double retracementLow = iLow(mSymbol, mTimeFrame, index);

        double candleBeforeRetracementLow = iLow(mSymbol, mTimeFrame, index + 1);
        double candelBeforeRetracementHigh = iHigh(mSymbol, mTimeFrame, index + 1);

        // check if the retracement candle is a bearish candle that started and validated an MB on its own. This won't get checked in other logic
        // if there are a few candles after the retracment that don't break it
        if (retracementOpen > retracementClose && retracementLow < candleBeforeRetracementLow && retracementHigh > candelBeforeRetracementHigh)
        {
            return true;
        }
    }

    return false;
}

// Method that Checks for retracements
// Will set mCurrentBullishRetracementIndex or mCurrentBearishRetracementIndex if one is found
// Will reset mCurrentBullishRetracementIndex or mCurrentBearishRetracementIndex if they are invalidated
void MBTracker::CheckSetRetracement(int startingIndex, int mbType, int prevMBType)
{
    if (mbType == OP_BUY)
    {
        // Already have a retracement
        if (mCurrentBullishRetracementIndex != EMPTY)
        {
            // broke further than a retracmeent index without starting an MB. The retracement becomes invalidated
            if (!mPendingBullishMB && iHigh(mSymbol, mTimeFrame, startingIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
            {
                mCurrentBullishRetracementIndex = EMPTY;
            }

            return;
        }

        // candle that has a high that is lower than the one before it, bullish retracement started
        if ((iHigh(mSymbol, mTimeFrame, startingIndex) < iHigh(mSymbol, mTimeFrame, startingIndex + 1) ||
             iLow(mSymbol, mTimeFrame, startingIndex) < iLow(mSymbol, mTimeFrame, startingIndex + 1)) &&
            !IsEngulfingCandle(OP_BUY, startingIndex))
        {
            if (prevMBType == OP_BUY)
            {
                // Inclusive in case the highest candle of the next mb is the ending index of the previous
                int highestIndex;
                if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBs[MostRecentMBIndex()].EndIndex() - startingIndex, startingIndex, true, highestIndex))
                {
                    return;
                }

                mCurrentBullishRetracementIndex = highestIndex;

                // if we had equal Highs, iHighest will return the one that came first. This can cause issues if its equal highs with a huge impulsivie candles as the mb will be considered the whole impulse and
                // not the actual retracement. We'll just set the retracement to the next candle since they are equal highs anyways
                if (mCurrentBullishRetracementIndex > 0 &&
                    iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex) == iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex - 1) &&
                    iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex + 1))
                {
                    mCurrentBullishRetracementIndex -= 1;
                }
            }
            else
            {
                mCurrentBullishRetracementIndex = startingIndex;
            }
        }
    }
    else if (mbType == OP_SELL)
    {
        if (mCurrentBearishRetracementIndex > EMPTY)
        {
            // broke further than a retracmeent index without starting an MB. The retracement becomes invalidated
            if (!mPendingBearishMB && iLow(mSymbol, mTimeFrame, startingIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
            {
                mCurrentBearishRetracementIndex = EMPTY;
            }

            return;
        }

        // candle that has a low that is higher than the one before it, bearish retraceemnt started
        if ((iLow(mSymbol, mTimeFrame, startingIndex) > iLow(mSymbol, mTimeFrame, startingIndex + 1) ||
             iHigh(mSymbol, mTimeFrame, startingIndex) > iHigh(mSymbol, mTimeFrame, startingIndex + 1)) &&
            !IsEngulfingCandle(OP_SELL, startingIndex))
        {
            if (prevMBType == OP_SELL)
            {
                // Add one to this in case the low of the next mb is the ending index of the previous
                int lowestIndex;
                if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, mMBs[MostRecentMBIndex()].EndIndex() - startingIndex + 1, startingIndex, false, lowestIndex))
                {
                    return;
                }

                mCurrentBearishRetracementIndex = lowestIndex;

                // if we had equal Lows, iLowest will return the one that came first. This can cause issues if its equal lows with a huge impulsivie candles as the mb will be considered the whole impulse and
                // not the actual retracement. We'll just set the retracement to the next candle since they are equal lows anyways
                if (mCurrentBearishRetracementIndex > 0 &&
                    iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex) == iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex - 1) &&
                    iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex + 1))
                {
                    mCurrentBearishRetracementIndex -= 1;
                }
            }
            else
            {
                mCurrentBearishRetracementIndex = startingIndex;
            }
        }
    }
}

// method that checks if the current retracement turns into a pending mb
void MBTracker::CheckSetPendingMB(int startingIndex, int mbType)
{
    if (mbType == OP_BUY && mCurrentBullishRetracementIndex > -1)
    {
        // if we already have a pending bullish mb, we just need to find the index of the lowest candle within it
        if (mPendingBullishMB)
        {
            // Only add 1 to the count if our current bar index isn't the same as the previous ending index.
            // Basically don't want the impulses that just broke and started the retacement to be considered
            int count = mCurrentBullishRetracementIndex - startingIndex;
            count = mCurrentMBs == 0 ||
                            (mCurrentMBs > 0 &&
                             startingIndex != mMBs[MostRecentMBIndex()].EndIndex() &&
                             iOpen(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex) > iClose(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
                        ? count + 1
                        : count;

            int lowestIndex = -1;
            if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, count, startingIndex, false, lowestIndex))
            {
                return;
            }

            mPendingBullishMBLowIndex = lowestIndex;
        }
        else
        {
            // loop through each bar and check every bar before it up to the retracement start and see if there is one with a body further than our current
            // Add 1 so that the retracmeent candle can start the pending MB i.e. in case the retracement candle has a body lower but no candles after it do
            for (int j = startingIndex; j <= mCurrentBullishRetracementIndex + 1; j++)
            {
                for (int k = j; k <= mCurrentBullishRetracementIndex + 1; k++)
                {
                    if (MathMin(iOpen(mSymbol, mTimeFrame, j), iClose(mSymbol, mTimeFrame, j)) < iLow(mSymbol, mTimeFrame, k))
                    {
                        // pending MBs can't be the same as the ending index of the previous MB because it can lead to false positives
                        // not having any mbs bypasses this
                        mPendingBullishMB = mCurrentMBs == 0 || (mCurrentMBs > 0 && j != mMBs[MostRecentMBIndex()].EndIndex());
                        break;
                    }
                }

                // can break out if we found one
                if (mPendingBullishMB)
                {
                    break;
                }
            }
            // find index of lowest candle within pending mb
            if (mPendingBullishMB)
            {
                // Only add 1 to the count if our current bar index isn't the same as the previous ending index.
                // Basically don't want the impulses that just broke and started the retacement to be considered
                int count = mCurrentBullishRetracementIndex - startingIndex;
                count = mCurrentMBs == 0 ||
                                (mCurrentMBs > 0 &&
                                 startingIndex != mMBs[MostRecentMBIndex()].EndIndex() &&
                                 iOpen(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex) > iClose(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
                            ? count + 1
                            : count;

                int lowestIndex = 0;
                if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, count, startingIndex, false, lowestIndex))
                {
                    return;
                }

                mPendingBullishMBLowIndex = lowestIndex;
            }
        }
    }
    else if (mbType == OP_SELL && mCurrentBearishRetracementIndex > -1)
    {
        // if we already have a pending bearish mb, we just need to find the index of the highest candle within it
        if (mPendingBearishMB)
        {
            // Only add 1 to the count if our current bar index isn't the same as the previous ending index.
            // Basically don't want the impulses that just broke and started the retacement to be considered
            int count = mCurrentBearishRetracementIndex - startingIndex;

            // TODO: Only allow retracement candle to be the high if it it a bullish candle aka started lower than the one before it and then broke higher
            count = mCurrentMBs == 0 ||
                            (mCurrentMBs > 0 &&
                             startingIndex != mMBs[MostRecentMBIndex()].EndIndex() &&
                             iOpen(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex) < iClose(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
                        ? count + 1
                        : count;

            int highestIndex;
            if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, count, startingIndex, false, highestIndex))
            {
                return;
            }

            mPendingBearishMBHighIndex = highestIndex;
        }
        else
        {
            // loop through each bar and check every bar before it up to the retracement start and see if there is one with a body further than our current
            // Add one so that the retracement candle can start the pending MB i.e. in case the retracement candle has a body higher but no candles after it do
            for (int j = startingIndex; j <= mCurrentBearishRetracementIndex + 1; j++)
            {
                for (int k = j; k <= mCurrentBearishRetracementIndex + 1; k++)
                {
                    if (MathMax(iOpen(mSymbol, mTimeFrame, j), iClose(mSymbol, mTimeFrame, j)) > iHigh(mSymbol, mTimeFrame, k))
                    {
                        // pending MBs can't be the same as the ending index of the previous MB because it can lead to false positives
                        // not having any mbs bypasses this
                        mPendingBearishMB = mCurrentMBs == 0 || (mCurrentMBs > 0 && j != mMBs[MostRecentMBIndex()].EndIndex());
                    }
                }

                // can break out if we found one
                if (mPendingBearishMB)
                {
                    break;
                }
            }
            // find index of highest candle within pending mb
            if (mPendingBearishMB)
            {
                // Only add 1 to the count if our current bar index isn't the same as the previous ending index.
                // Basically don't want the impulses that just broke and started the retacement to be considered
                int count = mCurrentBearishRetracementIndex - startingIndex;
                count = mCurrentMBs == 0 ||
                                (mCurrentMBs > 0 &&
                                 startingIndex != mMBs[MostRecentMBIndex()].EndIndex() &&
                                 iOpen(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex) < iClose(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
                            ? count + 1
                            : count;

                int highestIndex;
                if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, count, startingIndex, false, highestIndex))
                {
                    return;
                }

                mPendingBearishMBHighIndex = highestIndex;
            }
        }
    }
}

// method that create an mb
void MBTracker::CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex)
{
    if (mCurrentMBs == mMBsToTrack)
    {
        delete mMBs[mMBsToTrack - 1];
        ArrayCopy(mMBs, mMBs, 1, 0, mMBsToTrack - 1);

        MB *mb = new MB(mSymbol, mTimeFrame, mMBsCreated, mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB, mAllowZoneWickBreaks);
        mb.CheckAddZones(mAllowZoneMitigation);
        mMBs[0] = mb;
    }
    else
    {
        MB *mb = new MB(mSymbol, mTimeFrame, mMBsCreated, mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB, mAllowZoneWickBreaks);
        mb.CheckAddZones(mAllowZoneMitigation);
        mMBs[(mMBsToTrack - 1) - mCurrentMBs] = mb;

        mCurrentMBs += 1;
    }

    mMBsCreated += 1;
}

// method that resets all tracking
void MBTracker::ResetTracking(void)
{
    mPendingBullishMB = false;
    mPendingBearishMB = false;

    mCurrentBullishRetracementIndex = -1;
    mCurrentBearishRetracementIndex = -1;

    mPendingBearishMBHighIndex = -1;
    mPendingBullishMBLowIndex = -1;
}

// --------------- Helper Methods ------------------------
bool MBTracker::InternalHasNMostRecentConsecutiveMBs(int nMBs)
{
    Update();

    if (nMBs > mCurrentMBs)
    {
        Print("Looking for more consecutive MBs, ", nMBs, ", than there are MBs, ", mCurrentMBs);
        return false;
    }

    int mbType = -1;
    for (int i = 0; i < nMBs; i++)
    {
        if (i == 0)
        {
            mbType = mMBs[MostRecentMBIndex() + i].Type();
        }
        else if (mbType != mMBs[MostRecentMBIndex() + i].Type())
        {
            return false;
        }
    }

    return true;
}

// Checks if the nthMB is a differnt type than the one before it
bool MBTracker::InternalNthMostRecentMBIsOpposite(int nthMB)
{
    Update();

    if (nthMB >= mCurrentMBs - 1)
    {
        Print("Can't check MB before, ", nthMB, " MB. Total MBs, ", mMBsToTrack - 1);
        return false;
    }

    int i = MostRecentMBIndex() + nthMB;
    return mMBs[i].Type() != mMBs[i + 1].Type();
}
// ##############################################################
// ######################## Public Methods ######################
// ##############################################################

// -------------- Constructors / Destructors --------------------
MBTracker::MBTracker(string symbol, int timeFrame,
                     int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool allowZoneWickBreaks, bool printErrors, bool calculateOnTick)
{
    init(symbol, timeFrame, mbsToTrack, maxZonesInMB, allowZoneMitigation, allowZonesAfterMBValidation, allowZoneWickBreaks, printErrors, calculateOnTick);
}

MBTracker::~MBTracker()
{
    Print("Deint MBTracker");
    for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
    {
        delete mMBs[i];
    }
}

// -------------- Maintenance Methods --------------------------
void MBTracker::UpdateIndexes(int barIndex)
{
    mCurrentBullishRetracementIndex = mCurrentBullishRetracementIndex > -1 ? mCurrentBullishRetracementIndex + barIndex : -1;
    mCurrentBearishRetracementIndex = mCurrentBearishRetracementIndex > -1 ? mCurrentBearishRetracementIndex + barIndex : -1;

    mPendingBullishMBLowIndex = mPendingBullishMBLowIndex > -1 ? mPendingBullishMBLowIndex + barIndex : -1;
    mPendingBearishMBHighIndex = mPendingBearishMBHighIndex > -1 ? mPendingBearishMBHighIndex + barIndex : -1;

    for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
    {
        mMBs[i].UpdateIndexes(barIndex);
    }
}
// ---------------- Computer Properties -----------------------
bool MBTracker::CurrentBullishRetracementIndexIsValid(out int &currentBullishRetracementIndex, int barIndex = 0)
{
    // Has to be more than 1 candle
    if ((mCurrentBullishRetracementIndex - barIndex) < 2)
    {
        return false;
    }

    currentBullishRetracementIndex = mCurrentBullishRetracementIndex;
    return true;
}

bool MBTracker::CurrentBearishRetracementIndexIsValid(out int &currentBearishRetracementIndex, int barIndex = 0)
{
    // has to be more than 1 candle
    if ((mCurrentBearishRetracementIndex - barIndex) < 2)
    {
        return false;
    }

    currentBearishRetracementIndex = mCurrentBearishRetracementIndex;
    return true;
}

// -------------- MB Schematic Mehthods ---------------
bool MBTracker::MBExists(int mbNumber)
{
    if (mbNumber == EMPTY)
    {
        return false;
    }

    if (mMBsCreated <= mMBsToTrack)
    {
        return true;
    }

    return mbNumber >= (mMBsCreated - mMBsToTrack) && mbNumber <= (mMBsCreated - 1);
}

bool MBTracker::GetNthMostRecentMB(int nthMB, MBState *&mbState)
{
    Update();

    if (nthMB > mCurrentMBs)
    {
        Print("Nth MB, ", nthMB, ", is further than current MBs, ", mCurrentMBs);
        return false;
    }

    mbState = mMBs[MostRecentMBIndex() + nthMB];
    return true;
}

bool MBTracker::GetMB(int mbNumber, MBState *&mbState)
{
    Update();

    for (int i = 0; i <= mCurrentMBs - 1; i++)
    {
        if (mMBs[MostRecentMBIndex() + i].Number() == mbNumber)
        {
            mbState = mMBs[MostRecentMBIndex() + i];
            return true;
        }
    }

    return false;
}

bool MBTracker::GetPreviousMB(int mbNumber, MBState *&mbState)
{
    // subtract 1 since MB Number is the number of MB that was created
    return GetMB(mbNumber - 1, mbState);
}

bool MBTracker::GetSubsequentMB(int mbNumber, MBState *&mbState)
{
    // Add 1 since MB Number is the number of MB that was created
    return GetMB(mbNumber + 1, mbState);
}

bool MBTracker::GetNMostRecentMBs(int nMostRecent, MBState *&mbStates[])
{
    if (nMostRecent > mCurrentMBs)
    {
        Print("Can't Retrieve More MBs than there are");
        return false;
    }

    ArrayResize(mbStates, nMostRecent);

    for (int i = 0; i < nMostRecent; i++)
    {
        mbStates[i] = mMBs[MostRecentMBIndex() + i];
    }

    return true;
}

bool MBTracker::HasNMostRecentConsecutiveMBs(int nMBs)
{
    return InternalHasNMostRecentConsecutiveMBs(nMBs);
}

bool MBTracker::HasNMostRecentConsecutiveMBs(int nMBs, MBState *&mbStates[])
{
    if (nMBs < ArraySize(mbStates))
    {
        Print("Trying to retrieve more consecutive MBs, ", nMBs, ", than array can hold, ", ArraySize(mbStates));
        return false;
    }

    if (InternalHasNMostRecentConsecutiveMBs(nMBs))
    {
        for (int i = 0; i < nMBs; i++)
        {
            mbStates[i] = mMBs[MostRecentMBIndex() + i];
        }

        return true;
    }

    return false;
}

bool MBTracker::NthMostRecentMBIsOpposite(int nthMB)
{
    return InternalNthMostRecentMBIsOpposite(nthMB);
}

bool MBTracker::NthMostRecentMBIsOpposite(int nthMB, MBState *&mbState[])
{
    if (InternalNthMostRecentMBIsOpposite(nthMB))
    {
        mbState[0] = mMBs[MostRecentMBIndex() + nthMB];
        return true;
    }

    return false;
}

bool MBTracker::MBIsOpposite(int mbNumber)
{
    Update();

    // subtract one here since the first MB can't be opposite
    for (int i = 0; i < mMBsCreated - 1; i++)
    {
        if (mMBs[MostRecentMBIndex() + i].Number() == mbNumber)
        {
            return mMBs[MostRecentMBIndex() + i].Type() != mMBs[MostRecentMBIndex() + i + 1].Type();
        }
    }

    return false;
}
// Counts how many consecutive MBs of the same type occurred before the nthMB
// <Param> nthMB: The index of the MB to start; exclusive <Param>
int MBTracker::NumberOfConsecutiveMBsBeforeNthMostRecent(int nthMB)
{
    if (nthMB > mCurrentMBs)
    {
        Print("Can't check ", nthMB, " MBs Back. Current MBs ", mCurrentMBs);
        return 0;
    }

    Update();

    int count = 0;
    int type = -1;
    int startingIndex = MostRecentMBIndex() + nthMB + 1;

    for (int i = startingIndex; i <= mMBsToTrack - 1; i++)
    {
        if (i == startingIndex)
        {
            type = mMBs[i].Type();
        }
        else
        {
            if (type != mMBs[i].Type())
            {
                return count;
            }
        }

        count += 1;
    }

    return count;
}

bool MBTracker::MBIsMostRecent(int mbNumber)
{
    Update();

    return mMBs[MostRecentMBIndex()].Number() == mbNumber;
}

bool MBTracker::MBIsMostRecent(int mbNumber, MBState *&mbState)
{
    if (MBIsMostRecent(mbNumber))
    {
        return GetMB(mbNumber, mbState);
    }

    return false;
}

string MBTracker::ToString(int mbsToPrint = 3)
{
    string mbtString = "Current MB Number: " + IntegerToString(mMBs[MostRecentMBIndex()].Number()) + "\n" +
                       "Current MB Type: " + IntegerToString(mMBs[MostRecentMBIndex()].Type()) + "\n" +
                       "Current Bullish Retracement Index: " + IntegerToString(mCurrentBullishRetracementIndex) + "\n" +
                       "Current Bearish Retracmentt Index: " + IntegerToString(mCurrentBearishRetracementIndex) + "\n" +
                       "Pending Bullish MB: " + IntegerToString(mPendingBullishMB) + "\n" +
                       "Pending Bearish MB: " + IntegerToString(mPendingBearishMB) + "\n" +
                       "Pending Bullis MB Low Index: " + IntegerToString(mPendingBullishMBLowIndex) + "\n" +
                       "Pending Bearish MB High Index: " + IntegerToString(mPendingBearishMBHighIndex) + "\n";

    mbsToPrint = MathMin(mbsToPrint, mMBsCreated);

    for (int i = 0; i < mbsToPrint; i++)
    {
        mbtString += mMBs[MostRecentMBIndex() + i].ToString();
    }

    return mbtString;
}

string MBTracker::ToSingleLineString(int mbsToPrint = 3)
{
    string mbtString = "Current MB Number: " + IntegerToString(mMBs[MostRecentMBIndex()].Number()) +
                       " Current MB Type: " + IntegerToString(mMBs[MostRecentMBIndex()].Type()) +
                       " Current Bullish Retracement Index: " + IntegerToString(mCurrentBullishRetracementIndex) +
                       " Current Bearish Retracmentt Index: " + IntegerToString(mCurrentBearishRetracementIndex) +
                       " Pending Bullish MB: " + IntegerToString(mPendingBullishMB) +
                       " Pending Bearish MB: " + IntegerToString(mPendingBearishMB) +
                       " Pending Bullis MB Low Index: " + IntegerToString(mPendingBullishMBLowIndex) +
                       " Pending Bearish MB High Index: " + IntegerToString(mPendingBearishMBHighIndex);

    mbsToPrint = MathMin(mbsToPrint, mMBsCreated);

    for (int i = 0; i < mbsToPrint; i++)
    {
        mbtString += mMBs[MostRecentMBIndex() + i].ToSingleLineString();
    }

    return mbtString;
}

// ---------------- MB Display Methods --------------
void MBTracker::PrintNMostRecentMBs(int n)
{
    Update();

    if (n == -1 || n > mCurrentMBs)
    {
        n = mCurrentMBs;
    }

    for (int i = (mMBsToTrack - n); i < MostRecentMBIndex() + n; i++)
    {
        Print(mMBs[i].ToString());
    }
}

void MBTracker::DrawNMostRecentMBs(int n)
{
    Update();

    if (n == -1 || n > mCurrentMBs)
    {
        n = mCurrentMBs;
    }

    for (int i = MostRecentMBIndex(); i < MostRecentMBIndex() + n; i++)
    {
        mMBs[i].Draw(mPrintErrors);
    }
}

// ------------- Zone Retrieval ----------------
// Gets all unretrieved zones from the nth most recent MB
// will place them in the index at which they occured in the MB
bool MBTracker::GetNthMostRecentMBsUnretrievedZones(int nthMB, ZoneState *&zoneStates[])
{
    Update();

    if (nthMB >= mCurrentMBs)
    {
        Print("Can't get zones for MB: ", nthMB, ", Total MBs: ", mCurrentMBs);
        return false;
    }

    int i = MostRecentMBIndex() + nthMB - 1;

    if (mMBs[MostRecentMBIndex() + nthMB].UnretrievedZoneCount() > 0)
    {
        return mMBs[MostRecentMBIndex() + nthMB].GetUnretrievedZones(zoneStates);
    }

    return false;
}

// Gets the n most recent mbs unretrieved zones
// the first 0 -> mMaxZonesInMB zones will be for the first MB,
// then mMaxZonesInMB -> 2 * mMaxZonesInMB zones will be for the second MB,
// so on and so on
// TODO: Not usable right now and will probaly remove
bool MBTracker::GetNMostRecentMBsUnretrievedZones(int nMBs, ZoneState *&zoneStates[])
{
    Update();

    if (nMBs > mCurrentMBs)
    {
        Print("Can't get ", nMBs, " MBs when there is only ", mCurrentMBs);
        return false;
    }

    if (ArraySize(zoneStates) < nMBs * mMaxZonesInMB)
    {
        Print("ZoneStates is not large enough to hold all possible zones");
        return false;
    }
    bool retrievedZones = false;
    for (int i = 0; i < nMBs; i++)
    {
        if (mMBs[MostRecentMBIndex() + i].UnretrievedZoneCount() > 0)
        {
            // retrievedZones = mMBs[MostRecentMBIndex() + i].GetUnretrievedZones(i * mMaxZonesInMB, zoneStates);
        }
    }

    return retrievedZones;
}

bool MBTracker::GetNthMostRecentMBsClosestValidZone(int nthMB, ZoneState *&zoneState)
{
    Update();

    if (nthMB >= mCurrentMBs)
    {
        Print("Can't get zone for MB: ", nthMB, ", Total MBs: ", mCurrentMBs);
        return false;
    }

    return mMBs[MostRecentMBIndex() + nthMB].GetClosestValidZone(zoneState);
}

bool MBTracker::NthMostRecentMBsClosestValidZoneIsHolding(int nthMB, ZoneState *&zoneState, int barIndex = -1)
{
    if (GetNthMostRecentMBsClosestValidZone(nthMB, zoneState))
    {
        return mMBs[MostRecentMBIndex() + nthMB].ClosestValidZoneIsHolding(barIndex);
    }

    return false;
}

bool MBTracker::MBsClosestValidZoneIsHolding(int mbNumber, int barIndex = -1)
{
    MBState *tempMBState;
    if (GetMB(mbNumber, tempMBState))
    {
        return tempMBState.ClosestValidZoneIsHolding(barIndex);
    }

    return false;
}

// ------------- Zone Display -----------------
void MBTracker::DrawZonesForNMostRecentMBs(int nMBs)
{
    Update();

    if (nMBs == -1 || nMBs > mCurrentMBs)
    {
        nMBs = mCurrentMBs;
    }

    for (int i = MostRecentMBIndex(); i < MostRecentMBIndex() + nMBs; i++)
    {
        mMBs[i].DrawZones(mPrintErrors);
    }
}