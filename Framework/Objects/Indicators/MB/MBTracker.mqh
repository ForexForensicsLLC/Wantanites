//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>
#include <Wantanites\Framework\Objects\Indicators\MB\MB.mqh>
#include <Wantanites\Framework\Helpers\CandleStickHelper.mqh>

#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>

class MBTracker
{
private:
    // --- Operation Variables ---
    bool mCalculateOnTick; // Needs to be true when on the 1 second chart or else we'll miss values
    int mTimeFrame;
    string mSymbol;
    int mPrevCalculated;
    datetime mFirstBarTime;
    bool mInitialLoad;

    // --- MB Counting / Tracking---
    int mMBsToTrack;
    int mMinMBWidth;
    CandlePart mMBsValidatedBy;
    CandlePart mMBsBrokenBy;
    bool mShowPendingMBs;

    int mCurrentMBs; // Used for tracking when to start cleaning up MBs
    int mMBsCreated; // Used for MBNumber

    int mCurrentBullishRetracementIndex;
    int mCurrentBearishRetracementIndex;

    bool mHasPendingBullishMB;
    bool mHasPendingBearishMB;

    int mPendingBullishMBLowIndex;
    int mPendingBearishMBHighIndex;

    // --- Zone Counting / Tracking---
    int mMaxZonesInMB;
    bool mAllowZonesAfterMBValidation;
    CandlePart mZonesBrokenBy;
    ZonePartInMB mRequiredZonePartInMB;
    bool mAllowMitigatedZones;
    bool mAllowOverlappingZones;

    bool mShowPendingZones;
    CandlePart mPendingZonesBrokenBy;
    bool mAllowPendingMitigatedZones;
    bool mAllowPendingOverlappingZones;

    // --- Colors ---
    color mBullishMBColor;
    color mBearishMBColor;
    color mDemandZoneColor;
    color mSupplyZoneColor;
    color mPendingDemandZoneColor;
    color mPendingSupplyZoneColor;

    MB *mMBs[];
    MB *mPendingBullishMB;
    MB *mPendingBearishMB;

    // --- Tracking Methods ---
    void Update();
    int MostRecentMBIndex() { return mMBsToTrack - mCurrentMBs; }

    // --- MB Creation Methods ---
    bool PendingMBIsValidated(int type, int barIndex);
    void CheckMostRecentMBIsBroken(int barIndex);
    void CalculateMB(int barIndex);
    bool IsEngulfingCandle(int mbType, int index);
    void CheckSetRetracement(int startingIndex, int mbType, int prevMBType);
    void CheckSetPendingMB(int startingIndex, int mbType);
    void CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex);
    void UpdatePendingMB(int type, int barIndex, bool matchesMostRecentMBType);
    void ResetTracking();

    // --------- Helper Methods ----------------
    bool InternalHasNMostRecentConsecutiveMBs(int nMBs);
    bool InternalNthMostRecentMBIsOpposite(int nthMB);

public:
    //  --- Getters ---
    string Symbol() { return mSymbol; }
    int TimeFrame() { return mTimeFrame; }
    int CurrentMBs() { return mCurrentMBs; }
    int MBsCreated() { return mMBsCreated; }
    bool HasPendingBullishMB() { return mHasPendingBullishMB; }
    bool HasPendingBearishMB() { return mHasPendingBearishMB; }

    // --- Constructors / Destructors ---
    MBTracker(bool calculatedOnTick, string symbol, int timeFrame, int mbsToTrack, int minCandlesInMB, CandlePart mbsValidatedBy, CandlePart mbsBrokenBy,
              bool showPendingMBs, int maxZonesInMB, bool allowZonesAfterMBValidation, CandlePart zonesBrokenBy, ZonePartInMB requiredZonePartInMB,
              bool allowMitigatedZones, bool allowOverlappingZones, bool showPendingZones, CandlePart pendingZonesBrokenBy, bool allowPendingMitigatedZones,
              bool allowPendingOverlappingZones, color bullishMBColor, color bearishMBColor, color demandZoneColor, color supplyZoneColor, color pendingDemandZoneColor,
              color pendingSupplyZoneColor);
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
    int GetNthMostRecentMBsType(int nthMB);

    bool HasNMostRecentConsecutiveMBs(int nMBs);
    bool HasNMostRecentConsecutiveMBs(int nMBs, MBState *&mbStates[]);

    bool NthMostRecentMBIsOpposite(int nthMB);
    bool NthMostRecentMBIsOpposite(int nthMB, MBState *&mbState);
    bool MBIsOpposite(int mbNumber);

    int NumberOfConsecutiveMBsBeforeNthMostRecent(int nthMB);
    int NumberOfConsecutiveMBsBeforeMB(int mbNumber);

    bool MBIsMostRecent(int mbNumber);
    bool MBIsMostRecent(int mbNumber, MBState *&mbState);

    int MBStartIsBroken(int mbNumber, bool &brokeRangeStart);
    int MBEndIsBroken(int mbNumber, bool &brokeRangeEnd);

    string ToString(int mbsToPrint);
    string ToSingleLineString(int mbsToPrint);

    // --- MB Display Methods ---
    void PrintNMostRecentMBs(int nMBs);
    void DrawNMostRecentMBs(int nMBs);

    // --- Zone Retrieval Methods ---
    bool GetNthMostRecentMBsClosestValidZone(int nthMB, ZoneState *&zoneState);

    bool NthMostRecentMBsClosestValidZoneIsHolding(int nthMB, ZoneState *&zoneState, int barIndex);
    bool MBsClosestValidZoneIsHolding(int mbNumber, int barIndex);

    // -- Zone Display Methods --
    void DrawZonesForNMostRecentMBs(int nMBs);

    void Clear();
};

// ##############################################################
// ####################### Private Methods ######################
// ##############################################################

//----------------------- Tracking Methods ----------------------
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

    // this was added so that MBs are invalidated without having to wait for the candle to close, no matter what
    // this is needed in liquidation setups where the liquidation mb can tap into the zone on the same candle that
    // breaks the second. If this wasn't there, we would have to wait for that candle to close, potentially missing
    // setups and getting inaccurate results from that point on
    // TODO: test without this since I Don't think this is needed anymore with the change to only breaking on bodies
    // if (!mInitialLoad && mMBsCreated > 0)
    // {
    //     CheckMostRecentMBIsBroken(limit);
    // }

    // Calcualte on every tick
    if (!mInitialLoad && mCalculateOnTick)
    {
        CalculateMB(limit);
    }
    // only calculate when a new bar gets created. Will calcualte on the previous bar
    else
    {
        for (int i = limit; i > 0; i--)
        {
            // This is added so that the inital load of MBs still functions as usual
            if (/*mInitialLoad &&*/ mCurrentMBs > 0)
            {
                CheckMostRecentMBIsBroken(i);
            }

            CalculateMB(i);
        }
    }

    // Calcualte MBs for each bar we have left
    // removed -1 from limit here, i don't think it should be there

    mPrevCalculated = bars;
    mInitialLoad = false;
}

void MBTracker::CheckMostRecentMBIsBroken(int barIndex)
{
    if (mMBs[MostRecentMBIndex()].CandleBrokeMB(barIndex))
    {
        if (mMBs[MostRecentMBIndex()].Type() == OP_BUY)
        {
            int highestIndex;
            if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBs[MostRecentMBIndex()].EndIndex() - barIndex, barIndex, true, highestIndex))
            {
                return;
            }

            CreateMB(OP_SELL, mMBs[MostRecentMBIndex()].LowIndex(), barIndex, highestIndex, mMBs[MostRecentMBIndex()].LowIndex());
            ResetTracking();
        }
        else if (mMBs[MostRecentMBIndex()].Type() == OP_SELL)
        {
            int lowestIndex = 0;
            if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, mMBs[MostRecentMBIndex()].EndIndex() - barIndex, barIndex, true, lowestIndex))
            {
                return;
            }

            CreateMB(OP_BUY, mMBs[MostRecentMBIndex()].HighIndex(), barIndex, mMBs[MostRecentMBIndex()].HighIndex(), lowestIndex);
            ResetTracking();
        }
    }
}

bool MBTracker::PendingMBIsValidated(int type, int barIndex)
{
    if (type == OP_BUY)
    {
        double high = 0.0;
        if (mMBsValidatedBy == CandlePart::Body)
        {
            high = CandleStickHelper::HighestBodyPart(mSymbol, mTimeFrame, barIndex);
        }
        else if (mMBsValidatedBy == CandlePart::Wick)
        {
            high = iHigh(mSymbol, mTimeFrame, barIndex);
        }

        return high > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex);
    }
    else if (type == OP_SELL)
    {
        double low = 0.0;
        if (mMBsValidatedBy == CandlePart::Body)
        {
            low = CandleStickHelper::LowestBodyPart(mSymbol, mTimeFrame, barIndex);
        }
        else if (mMBsValidatedBy == CandlePart::Wick)
        {
            low = iLow(mSymbol, mTimeFrame, barIndex);
        }

        return low < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex);
    }

    return false;
}

void MBTracker::CalculateMB(int barIndex)
{
    if (CheckPointer(mMBs[mMBsToTrack - 1]) == POINTER_INVALID)
    {
        CheckSetRetracement(barIndex, OP_BUY, -1);
        CheckSetPendingMB(barIndex, OP_BUY);

        CheckSetRetracement(barIndex, OP_SELL, -1);
        CheckSetPendingMB(barIndex, OP_SELL);

        // validated Bullish MB
        if (mHasPendingBullishMB && PendingMBIsValidated(OP_BUY, barIndex))
        {
            CreateMB(OP_BUY, mCurrentBullishRetracementIndex, barIndex, mCurrentBullishRetracementIndex, mPendingBullishMBLowIndex);
            ResetTracking();
            return;
        }
        // validated Bearish MB
        else if (mHasPendingBearishMB && PendingMBIsValidated(OP_SELL, barIndex))
        {
            CreateMB(OP_SELL, mCurrentBearishRetracementIndex, barIndex, mPendingBearishMBHighIndex, mCurrentBearishRetracementIndex);
            ResetTracking();
            return;
        }
    }
    // prev mb was bullish
    else if (mMBs[MostRecentMBIndex()].Type() == OP_BUY)
    {
        // check pending first so that a single candle can trigger the pending flag and confirm an MB else retracement will get reset in CheckSetRetracement()
        CheckSetPendingMB(barIndex, OP_BUY);
        CheckSetRetracement(barIndex, OP_BUY, OP_BUY);
        // recheck for a pending mb again incase we set the retracment flag or else we may not have a pending mb until the candle after we actually do
        CheckSetPendingMB(barIndex, OP_BUY);

        if (mHasPendingBullishMB)
        {
            // new bullish mb has been validated
            if (PendingMBIsValidated(OP_BUY, barIndex))
            {
                int bullishRetracementIndex = -1;
                if (CurrentBullishRetracementIndexIsValid(bullishRetracementIndex, barIndex))
                {
                    CreateMB(OP_BUY, bullishRetracementIndex, barIndex, bullishRetracementIndex, mPendingBullishMBLowIndex);
                }

                ResetTracking();
            }
            else if (mShowPendingMBs)
            {
                UpdatePendingMB(OP_BUY, barIndex, true);
            }
        }
        // only allow the most recent MB to have zones after it has been validated if there is no pending MB
        else if (mAllowZonesAfterMBValidation)
        {
            mMBs[MostRecentMBIndex()].CheckAddZonesAfterMBValidation(barIndex);
        }

        if (mShowPendingMBs)
        {
            UpdatePendingMB(OP_SELL, barIndex, false);
        }
    }
    // prev mb was bearish
    else if (mMBs[MostRecentMBIndex()].Type() == OP_SELL)
    {
        // check pending first so that a single candle can trigger the pending flag and confirm an MB else retracement will get reset in CheckSetRetracement()
        CheckSetPendingMB(barIndex, OP_SELL);
        CheckSetRetracement(barIndex, OP_SELL, OP_SELL);
        // recheck for a pending mb again incase we set the retracment flag or else we may not have a pending mb until the candle after we actually do
        CheckSetPendingMB(barIndex, OP_SELL);

        if (mHasPendingBearishMB)
        {
            // new bearish mb has been validated
            if (PendingMBIsValidated(OP_SELL, barIndex))
            {
                int bearishRetracementIndex = -1;
                if (CurrentBearishRetracementIndexIsValid(bearishRetracementIndex, barIndex))
                {
                    CreateMB(OP_SELL, bearishRetracementIndex, barIndex, mPendingBearishMBHighIndex, bearishRetracementIndex);
                }

                ResetTracking();
            }
            else if (mShowPendingMBs)
            {
                UpdatePendingMB(OP_SELL, barIndex, true);
            }
        }
        // only allow the most recent MB to have zones after it has been validated if there is no pending MB
        else if (mAllowZonesAfterMBValidation)
        {
            mMBs[MostRecentMBIndex()].CheckAddZonesAfterMBValidation(barIndex);
        }

        if (mShowPendingMBs)
        {
            UpdatePendingMB(OP_BUY, barIndex, false);
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
            if (!mHasPendingBullishMB && iHigh(mSymbol, mTimeFrame, startingIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
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
            if (!mHasPendingBearishMB && iLow(mSymbol, mTimeFrame, startingIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
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
        if (mHasPendingBullishMB)
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
                        mHasPendingBullishMB = mCurrentMBs == 0 || (mCurrentMBs > 0 && j != mMBs[MostRecentMBIndex()].EndIndex());
                        break;
                    }
                }

                // can break out if we found one
                if (mHasPendingBullishMB)
                {
                    break;
                }
            }
            // find index of lowest candle within pending mb
            if (mHasPendingBullishMB)
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
        if (mHasPendingBearishMB)
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
                        mHasPendingBearishMB = mCurrentMBs == 0 || (mCurrentMBs > 0 && j != mMBs[MostRecentMBIndex()].EndIndex());
                    }
                }

                // can break out if we found one
                if (mHasPendingBearishMB)
                {
                    break;
                }
            }
            // find index of highest candle within pending mb
            if (mHasPendingBearishMB)
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
    delete mPendingBullishMB;
    delete mPendingBearishMB;

    color mbColor;
    color zoneColor;

    if (mbType == OP_BUY)
    {
        mbColor = mBullishMBColor;
        zoneColor = mDemandZoneColor;
    }
    else if (mbType == OP_SELL)
    {
        mbColor = mBearishMBColor;
        zoneColor = mSupplyZoneColor;
    }

    if (mCurrentMBs == mMBsToTrack)
    {
        delete mMBs[mMBsToTrack - 1];
        ArrayCopy(mMBs, mMBs, 1, 0, mMBsToTrack - 1);

        MB *mb = new MB(false, mSymbol, mTimeFrame, mMBsCreated, mbType, mMBsBrokenBy, iTime(mSymbol, mTimeFrame, startIndex), iTime(mSymbol, mTimeFrame, endIndex),
                        iTime(mSymbol, mTimeFrame, highIndex), iTime(mSymbol, mTimeFrame, lowIndex), mMaxZonesInMB, mZonesBrokenBy, mRequiredZonePartInMB,
                        mAllowMitigatedZones, mAllowOverlappingZones, mbColor, zoneColor);
        mb.CheckAddZones();
        mMBs[0] = mb;
    }
    else
    {
        MB *mb = new MB(false, mSymbol, mTimeFrame, mMBsCreated, mbType, mMBsBrokenBy, iTime(mSymbol, mTimeFrame, startIndex), iTime(mSymbol, mTimeFrame, endIndex),
                        iTime(mSymbol, mTimeFrame, highIndex), iTime(mSymbol, mTimeFrame, lowIndex), mMaxZonesInMB, mZonesBrokenBy, mRequiredZonePartInMB,
                        mAllowMitigatedZones, mAllowOverlappingZones, mbColor, zoneColor);
        mb.CheckAddZones();
        mMBs[(mMBsToTrack - 1) - mCurrentMBs] = mb;

        mCurrentMBs += 1;
    }

    mMBsCreated += 1;
}

void MBTracker::UpdatePendingMB(int type, int barIndex, bool matchesMostRecentMBsType)
{
    if (type == OP_BUY)
    {
        if (matchesMostRecentMBsType)
        {
            int bullishRetracementIndex = -1;
            if (CurrentBullishRetracementIndexIsValid(bullishRetracementIndex, barIndex))
            {
                // we delete the old pending mb after an mb has been validated, need to create a new one then
                if (CheckPointer(mPendingBullishMB) == POINTER_INVALID)
                {
                    mPendingBullishMB = new MB(true, mSymbol, mTimeFrame, mMBsCreated, OP_BUY, mMBsBrokenBy, iTime(mSymbol, mTimeFrame, bullishRetracementIndex),
                                               iTime(mSymbol, mTimeFrame, barIndex), iTime(mSymbol, mTimeFrame, bullishRetracementIndex),
                                               iTime(mSymbol, mTimeFrame, mPendingBullishMBLowIndex), mMaxZonesInMB, mPendingZonesBrokenBy, mRequiredZonePartInMB,
                                               mAllowPendingMitigatedZones, mAllowPendingOverlappingZones, mBullishMBColor, mPendingDemandZoneColor);
                }
                // already have a pending mb, just need to update it
                else
                {
                    mPendingBullishMB.StartTime(iTime(mSymbol, mTimeFrame, bullishRetracementIndex));
                    mPendingBullishMB.EndTime(iTime(mSymbol, mTimeFrame, barIndex));
                    mPendingBullishMB.HighTime(iTime(mSymbol, mTimeFrame, bullishRetracementIndex));
                    mPendingBullishMB.LowTime(iTime(mSymbol, mTimeFrame, mPendingBullishMBLowIndex));
                }
            }
        }
        else
        {
            int lowestIndex = 0;
            if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, mMBs[MostRecentMBIndex()].EndIndex() - barIndex, barIndex, true, lowestIndex))
            {
                return;
            }

            // we delete the old pending mb after an mb has been validated, need to create a new one then
            if (CheckPointer(mPendingBullishMB) == POINTER_INVALID)
            {

                mPendingBullishMB = new MB(true, mSymbol, mTimeFrame, mMBsCreated, OP_BUY, mMBsBrokenBy, iTime(mSymbol, mTimeFrame, mMBs[MostRecentMBIndex()].HighIndex()),
                                           iTime(mSymbol, mTimeFrame, barIndex), iTime(mSymbol, mTimeFrame, mMBs[MostRecentMBIndex()].HighIndex()),
                                           iTime(mSymbol, mTimeFrame, lowestIndex), mMaxZonesInMB, mPendingZonesBrokenBy, mRequiredZonePartInMB, mAllowPendingMitigatedZones,
                                           mAllowPendingOverlappingZones, mBullishMBColor, mPendingDemandZoneColor);
            }
            // already have a pending mb, just need to update it
            else
            {
                // high and start index will never change, only the end and low index
                mPendingBullishMB.EndTime(iTime(mSymbol, mTimeFrame, barIndex));
                mPendingBullishMB.LowTime(iTime(mSymbol, mTimeFrame, lowestIndex));
            }
        }

        // need to recheck since we can not have a pending mb if we haven't set hasPendingMB yet
        if (CheckPointer(mPendingBullishMB) == POINTER_DYNAMIC)
        {
            mPendingBullishMB.UpdateDrawnObject();

            if (mShowPendingZones)
            {
                mPendingBullishMB.CheckPendingZones(barIndex);
                mPendingBullishMB.CheckAddZones();
            }
        }
    }
    else if (type == OP_SELL)
    {
        if (matchesMostRecentMBsType)
        {
            int bearishRetracementIndex = -1;
            if (CurrentBearishRetracementIndexIsValid(bearishRetracementIndex, barIndex))
            {
                // we delete the old pending mb after an mb has been validated, need to create a new one then
                if (CheckPointer(mPendingBearishMB) == POINTER_INVALID)
                {
                    mPendingBearishMB = new MB(true, mSymbol, mTimeFrame, mMBsCreated, OP_SELL, mMBsBrokenBy, iTime(mSymbol, mTimeFrame, bearishRetracementIndex),
                                               iTime(mSymbol, mTimeFrame, barIndex), iTime(mSymbol, mTimeFrame, mPendingBearishMBHighIndex),
                                               iTime(mSymbol, mTimeFrame, bearishRetracementIndex), mMaxZonesInMB, mPendingZonesBrokenBy, mRequiredZonePartInMB,
                                               mAllowPendingMitigatedZones, mAllowPendingOverlappingZones, mBearishMBColor, mPendingSupplyZoneColor);
                }
                // already have a pending mb, just need to update it
                else
                {
                    mPendingBearishMB.StartTime(iTime(mSymbol, mTimeFrame, bearishRetracementIndex));
                    mPendingBearishMB.EndTime(iTime(mSymbol, mTimeFrame, barIndex));
                    mPendingBearishMB.HighTime(iTime(mSymbol, mTimeFrame, mPendingBearishMBHighIndex));
                    mPendingBearishMB.LowTime(iTime(mSymbol, mTimeFrame, bearishRetracementIndex));
                }
            }
        }
        else
        {
            int highestIndex;
            if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBs[MostRecentMBIndex()].EndIndex() - barIndex, barIndex, true, highestIndex))
            {
                return;
            }

            // we delete the old pending mb after an mb has been validated, need to create a new one then
            if (CheckPointer(mPendingBearishMB) == POINTER_INVALID)
            {
                mPendingBearishMB = new MB(true, mSymbol, mTimeFrame, mMBsCreated, OP_SELL, mMBsBrokenBy, iTime(mSymbol, mTimeFrame, mMBs[MostRecentMBIndex()].LowIndex()),
                                           iTime(mSymbol, mTimeFrame, barIndex), highestIndex, iTime(mSymbol, mTimeFrame, mMBs[MostRecentMBIndex()].LowIndex()),
                                           mMaxZonesInMB, mPendingZonesBrokenBy, mRequiredZonePartInMB, mAllowPendingMitigatedZones, mAllowPendingOverlappingZones,
                                           mBearishMBColor, mPendingSupplyZoneColor);
            }
            // already have a pending mb, just need to update it
            else
            {
                // low and start index will never change, only the end and high index
                mPendingBearishMB.EndTime(iTime(mSymbol, mTimeFrame, barIndex));
                mPendingBearishMB.HighTime(iTime(mSymbol, mTimeFrame, highestIndex));
            }
        }

        // need to recheck since we can not have a pending mb if we haven't set hasPendingMB yet
        if (CheckPointer(mPendingBearishMB) == POINTER_DYNAMIC)
        {
            mPendingBearishMB.UpdateDrawnObject();

            if (mShowPendingZones)
            {
                mPendingBearishMB.CheckPendingZones(barIndex);
                mPendingBearishMB.CheckAddZones();
            }
        }
    }
}

// method that resets all tracking
void MBTracker::ResetTracking()
{
    mHasPendingBullishMB = false;
    mHasPendingBearishMB = false;

    delete mPendingBullishMB;
    delete mPendingBearishMB;

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
MBTracker::MBTracker(bool calculateOnTick, string symbol, int timeFrame, int mbsToTrack, int minCandlesInMB, CandlePart mbsValidatedBy, CandlePart mbsBrokenBy,
                     bool showPendingMBs, int maxZonesInMB, bool allowZonesAfterMBValidation, CandlePart zonesBrokenBy, ZonePartInMB requiredZonePartInMB,
                     bool allowMitigatedZones, bool allowOverlappingZones, bool showPendingZones, CandlePart pendingZonesBrokenBy, bool allowPendingMitigatedZones,
                     bool allowPendingOverlappingZones, color bullishMBColor = clrLimeGreen, color bearishMBColor = clrRed, color demandZoneColor = clrGold,
                     color supplyZoneColor = clrMediumVioletRed, color pendingDemandZoneColor = clrYellow, color pendingSupplyZoneColor = clrAqua)
{
    mCalculateOnTick = calculateOnTick;
    mSymbol = symbol;
    mTimeFrame = timeFrame;
    mPrevCalculated = 0;
    mFirstBarTime = 0;
    mInitialLoad = true;

    mMBsToTrack = mbsToTrack;
    mMinMBWidth = minCandlesInMB;
    mMBsValidatedBy = mbsValidatedBy;
    mMBsBrokenBy = mbsBrokenBy;
    mShowPendingMBs = showPendingMBs;

    mMaxZonesInMB = maxZonesInMB;
    mAllowZonesAfterMBValidation = allowZonesAfterMBValidation;
    mZonesBrokenBy = zonesBrokenBy;
    mRequiredZonePartInMB = requiredZonePartInMB;
    mAllowMitigatedZones = allowMitigatedZones;
    mAllowOverlappingZones = allowOverlappingZones;

    mShowPendingZones = showPendingZones;
    mPendingZonesBrokenBy = pendingZonesBrokenBy;
    mAllowPendingMitigatedZones = allowPendingMitigatedZones;
    mAllowPendingOverlappingZones = allowPendingOverlappingZones;

    mBullishMBColor = bullishMBColor;
    mBearishMBColor = bearishMBColor;
    mDemandZoneColor = demandZoneColor;
    mSupplyZoneColor = supplyZoneColor;
    mPendingDemandZoneColor = pendingDemandZoneColor;
    mPendingSupplyZoneColor = pendingSupplyZoneColor;

    mMBsCreated = 0;
    mCurrentBullishRetracementIndex = -1;
    mCurrentBearishRetracementIndex = -1;

    ArrayResize(mMBs, mbsToTrack);

    // don't update right away since we don't want to do any calculations in OnInit() functions, only OnTick()
    // Update();
}

MBTracker::~MBTracker()
{
    for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
    {
        delete mMBs[i];
    }

    delete mPendingBullishMB;
    delete mPendingBearishMB;
}

// -------------- Maintenance Methods --------------------------
void MBTracker::UpdateIndexes(int barIndex)
{
    mCurrentBullishRetracementIndex = mCurrentBullishRetracementIndex > -1 ? mCurrentBullishRetracementIndex + barIndex : -1;
    mCurrentBearishRetracementIndex = mCurrentBearishRetracementIndex > -1 ? mCurrentBearishRetracementIndex + barIndex : -1;

    mPendingBullishMBLowIndex = mPendingBullishMBLowIndex > -1 ? mPendingBullishMBLowIndex + barIndex : -1;
    mPendingBearishMBHighIndex = mPendingBearishMBHighIndex > -1 ? mPendingBearishMBHighIndex + barIndex : -1;
}
// ---------------- Computed Properties -----------------------
bool MBTracker::CurrentBullishRetracementIndexIsValid(out int &currentBullishRetracementIndex, int barIndex = 0)
{
    // Has to be more than 1 candle
    if ((mCurrentBullishRetracementIndex - barIndex) < mMinMBWidth)
    {
        return false;
    }

    currentBullishRetracementIndex = mCurrentBullishRetracementIndex;
    return true;
}

bool MBTracker::CurrentBearishRetracementIndexIsValid(out int &currentBearishRetracementIndex, int barIndex = 0)
{
    // has to be more than 1 candle
    if ((mCurrentBearishRetracementIndex - barIndex) < mMinMBWidth)
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

    if (nthMB >= mCurrentMBs)
    {
        // Print("Nth MB, ", nthMB, ", is further than current MBs, ", mCurrentMBs);
        return false;
    }

    mbState = mMBs[MostRecentMBIndex() + nthMB];
    return true;
}

bool MBTracker::GetMB(int mbNumber, MBState *&mbState)
{
    Update();

    // just in case
    if (mbNumber < 0)
    {
        return false;
    }

    // mb is too old, doesn't exist anymore
    if (mbNumber < (mMBsCreated - mMBsToTrack))
    {
        return false;
    }

    // mb doesn't exist yet, return false
    // can happen when calling GetSubsequentMB()
    if (mbNumber >= mMBsCreated)
    {
        return false;
    }

    int index;
    if (mMBsCreated < mMBsToTrack)
    {
        // MBs are stored from the back of the array to the front. Since we haven't filled the array yet we can just use mMBsToTrack
        // EX: track 10 looking for 6, 10 - 6 - 1 = 3. Since they are stored from front to back, index 3 would be our most recent
        index = mMBsToTrack - mbNumber - 1;
    }
    else
    {
        // can just subtract them to find the nth most recent one that we are looking for
        // ex: looking for 99, created 100. 100 - 99 - 1 = 0 which would be the most recently created MB (mMBsCreated is incremented after creation of MB)
        index = mMBsCreated - mbNumber - 1;
    }

    if (mMBs[index].Number() == mbNumber)
    {
        mbState = mMBs[index];
        return true;
    }

    Print("Not Able To Find MB:", mbNumber, ", MBsCreated: ", mMBsCreated, ", MBs To Track: ", mMBsToTrack, ", Index: ", index);

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

int MBTracker::GetNthMostRecentMBsType(int nthMB)
{
    Update();

    if (nthMB >= mCurrentMBs)
    {
        // Print("Nth MB, ", nthMB, ", is further than current MBs, ", mCurrentMBs);
        return false;
    }

    return mMBs[MostRecentMBIndex() + nthMB].Type();
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

bool MBTracker::NthMostRecentMBIsOpposite(int nthMB, MBState *&mbState)
{
    if (InternalNthMostRecentMBIsOpposite(nthMB))
    {
        mbState = mMBs[MostRecentMBIndex() + nthMB];
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

int MBTracker::NumberOfConsecutiveMBsBeforeMB(int mbNumber)
{
    int nthMB = mMBsCreated - mbNumber - 1;
    return NumberOfConsecutiveMBsBeforeNthMostRecent(nthMB);
}

bool MBTracker::MBIsMostRecent(int mbNumber)
{
    Update();

    if (mCurrentMBs <= 0)
    {
        return false;
    }

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

int MBTracker::MBStartIsBroken(int mbNumber, bool &brokeRangeStart)
{
    MBState *tempMBState;
    if (!GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    brokeRangeStart = tempMBState.GlobalStartIsBroken();
    return ERR_NO_ERROR;
}

int MBTracker::MBEndIsBroken(int mbNumber, bool &brokeRangeEnd)
{
    // don't calcualte unless we put in a new mb past the one we are checking
    if (mMBs[MostRecentMBIndex()].Number() <= mbNumber)
    {
        brokeRangeEnd = false;
        return ERR_NO_ERROR;
    }

    MBState *tempMBState;
    if (!GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!tempMBState.mEndIsBroken)
    {
        if (tempMBState.Type() == OP_BUY)
        {
            double high;
            if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, tempMBState.HighIndex(), 0, false, high))
            {
                return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
            }

            tempMBState.mEndIsBroken = high > iHigh(mSymbol, mTimeFrame, tempMBState.HighIndex());
        }
        else if (tempMBState.Type() == OP_SELL)
        {
            double low;
            if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, tempMBState.LowIndex(), 0, false, low))
            {
                return ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
            }

            tempMBState.mEndIsBroken = low < iLow(mSymbol, mTimeFrame, tempMBState.LowIndex());
        }
    }

    brokeRangeEnd = tempMBState.mEndIsBroken;
    return ERR_NO_ERROR;
}

string MBTracker::ToString(int mbsToPrint = 3)
{
    string mbtString = "Current MB Number: " + IntegerToString(mMBs[MostRecentMBIndex()].Number()) + "\n" +
                       "Current MB Type: " + IntegerToString(mMBs[MostRecentMBIndex()].Type()) + "\n" +
                       "Current Bullish Retracement Index: " + IntegerToString(mCurrentBullishRetracementIndex) + "\n" +
                       "Current Bearish Retracmentt Index: " + IntegerToString(mCurrentBearishRetracementIndex) + "\n" +
                       "Pending Bullish MB: " + IntegerToString(mHasPendingBullishMB) + "\n" +
                       "Pending Bearish MB: " + IntegerToString(mHasPendingBearishMB) + "\n" +
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
                       " Pending Bullish MB: " + IntegerToString(mHasPendingBullishMB) +
                       " Pending Bearish MB: " + IntegerToString(mHasPendingBearishMB) +
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
        mMBs[i].Draw();
    }
}

// ------------- Zone Retrieval ----------------
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
        mMBs[i].DrawZones();
    }
}

void MBTracker::Clear()
{
    for (int i = MostRecentMBIndex(); i < mMBsToTrack; i++)
    {
        delete mMBs[i];
    }

    mCurrentMBs = 0;
    mMBsCreated = 0;

    ResetTracking();
}