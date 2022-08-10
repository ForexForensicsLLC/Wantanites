//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\MBState.mqh>
#include <SummitCapital\Framework\Objects\Zone.mqh>

class MB : public MBState
{
    typedef bool (*TSelectZoneFunc)(Zone &zone);

private:
    void InternalCheckAddZones(int startingIndex, int endingIndex, bool allowZoneMitigation, bool calculatingOnCurrentCandle);

public:
    // --- Constructors / Destructors ----------
    MB(string symbol, int timeFrame, int number, int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones, bool allowZoneWickBreaks);
    ~MB();

    // --- Maintenance Methods ---
    void UpdateIndexes(int barIndex);

    // ---- Adding Zones -------------
    void CheckAddZones(bool allowZoneMitigation);
    void CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation);
    void AddZone(string description, int startIndex, double entryPrice, int endIndex, double exitPrice);
};
/*

              _            _                        _   _               _
   _ __  _ __(_)_   ____ _| |_ ___   _ __ ___   ___| |_| |__   ___   __| |___
  | '_ \| '__| \ \ / / _` | __/ _ \ | '_ ` _ \ / _ \ __| '_ \ / _ \ / _` / __|
  | |_) | |  | |\ V / (_| | ||  __/ | | | | | |  __/ |_| | | | (_) | (_| \__ \
  | .__/|_|  |_| \_/ \__,_|\__\___| |_| |_| |_|\___|\__|_| |_|\___/ \__,_|___/
  |_|

*/
// ------------- Helper Methods ---------------
// Checks for zones with imbalances after and adds them if they are not already added
// GOES LEFT TO RIGHT
void MB::InternalCheckAddZones(int startingIndex, int endingIndex, bool allowZoneMitigation, bool calculatingOnCurrentCandle)
{
    bool prevImbalance = false;
    bool currentImbalance = false;

    int runningZoneCount = 0;

    if (mType == OP_BUY)
    {
        if (calculatingOnCurrentCandle)
        {
            endingIndex += 1;
        }

        for (int i = startingIndex; i >= endingIndex; i--)
        {
            // TODO: Add restriction where index has to be within / lower than high of previous candle?
            currentImbalance = iHigh(mSymbol, mTimeFrame, i + 1) < iLow(mSymbol, mTimeFrame, i - 1);

            // TODO: Also add a restriction where the index + 1 candle has to be above the zone?
            // Does it make sense to have an imbalance that is within the zone? Not really since the candle after can drop down again, basically mitigating without
            // the zone becing "validated"
            if (currentImbalance)
            {
                int startIndex;
                double imbalanceEntry;
                double imbalanceExit;
                string description;
                int entryOffset;

                double indexOpen = iOpen(mSymbol, mTimeFrame, i);
                double indexClose = iClose(mSymbol, mTimeFrame, i);
                double indexHigh = iHigh(mSymbol, mTimeFrame, i);
                double indexLow = iLow(mSymbol, mTimeFrame, i);

                double previousIndexOpen = iOpen(mSymbol, mTimeFrame, i + 1);
                double previousIndexClose = iClose(mSymbol, mTimeFrame, i + 1);
                double previousIndexHigh = iHigh(mSymbol, mTimeFrame, i + 1);
                double previousIndexLow = iLow(mSymbol, mTimeFrame, i + 1);

                double candleTwoBeforeIndexHigh = iHigh(mSymbol, mTimeFrame, i + 2);
                double candleTwoBeforeIndexOpen = iOpen(mSymbol, mTimeFrame, i + 2);
                double candleTwoBeforeIndexLow = iLow(mSymbol, mTimeFrame, i + 2);
                double candleTwoBeforeIndexClose = iClose(mSymbol, mTimeFrame, i + 2);

                // Bullish or Bearish for a tick could be calcualted based on the previous candle
                bool indexIsBullish = indexOpen <= indexClose;
                bool previousIndexIsBullish = previousIndexOpen <= previousIndexClose;
                bool candleTwoBeforeIndexIsBullish = candleTwoBeforeIndexOpen <= candleTwoBeforeIndexClose;

                // This needs to be checked before the next ones since this is a subset of them
                // Equals. IndexClose can be equal to IndexOpen in the case of a doji.
                // Only count wick zones if they go below the previous candle body
                bool indexCandleWickZone = indexClose >= indexOpen && indexOpen >= previousIndexHigh &&
                                           ((previousIndexIsBullish && indexLow <= previousIndexOpen) || (!previousIndexIsBullish && indexLow <= previousIndexOpen));

                bool bullishIndexWithNoWickLowerThanPreviousZone = indexIsBullish && indexLow < previousIndexLow && indexOpen == indexLow;

                bool bullishIndexLowerThanPreviousWithUpperWick = indexIsBullish && indexLow < previousIndexLow && indexClose < indexHigh;
                bool bullishIndexLowerThanPreviuosWithUnderWick = indexIsBullish && indexLow < previousIndexLow && indexOpen > indexLow;

                bool bearishIndexLowerThanPreviousZone = !indexIsBullish && indexLow <= previousIndexLow;

                bool bearishIndexWithinPreviousZone = !indexIsBullish && indexLow < previousIndexHigh && indexLow >= previousIndexLow;

                // Not Equal. If its not below the high it doesn't count. If its equal to the close, the next check should be caught
                bool indexWithinPreviousBullishUpperWickZone = previousIndexIsBullish && indexLow < previousIndexHigh && indexLow > previousIndexClose;

                // Equal. If we are within the candle at all, minus the upper wick
                bool indexWithinPreviousBullishBodyZone = previousIndexIsBullish && indexLow <= previousIndexClose && indexLow >= previousIndexLow;

                // Equal. If the index is within the previous bearish candle at all, we should always use the previous bearish high
                bool indexWithinPreviousBearishZone = !previousIndexIsBullish && indexLow <= previousIndexHigh && indexLow >= previousIndexLow;

                // this should follow the same wick checks as above as well i.e. only wicks engulfing. else the next check should be caught

                bool indexAbovePreviousBullishWithWickBelowZone = candleTwoBeforeIndexHigh > previousIndexHigh &&
                                                                  previousIndexIsBullish &&
                                                                  indexLow >= previousIndexHigh &&
                                                                  previousIndexLow < previousIndexOpen;

                bool indexAbovePreviousBullishWithWickAboveZone = candleTwoBeforeIndexHigh > previousIndexHigh &&
                                                                  previousIndexIsBullish &&
                                                                  indexLow >= previousIndexHigh &&
                                                                  previousIndexHigh > previousIndexClose;

                bool indexAbovePreviousBullishWithoutWickZone = candleTwoBeforeIndexHigh > previousIndexHigh &&
                                                                previousIndexIsBullish &&
                                                                indexLow >= previousIndexHigh &&
                                                                previousIndexLow == previousIndexOpen;

                bool indexAbovePreviousBearishZone = !previousIndexIsBullish && indexLow >= previousIndexHigh;

                if (indexCandleWickZone)
                {
                    startIndex = i;
                    entryOffset = 0;
                    imbalanceEntry = indexOpen;
                    imbalanceExit = indexLow;
                    description = "Index Candle Wick";
                }
                else if (bullishIndexWithNoWickLowerThanPreviousZone)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = indexLow;
                    description = "Bullish Index Candle With No Wick Lower Than Preivous";
                }
                else if (bullishIndexLowerThanPreviousWithUpperWick)
                {
                    startIndex = i;
                    entryOffset = 0;
                    imbalanceEntry = indexHigh;
                    imbalanceExit = indexClose;
                    description = "Bullish Index Candle Lower Than Previuos With Upper Wick";
                }
                else if (bullishIndexLowerThanPreviuosWithUnderWick)
                {
                    // always go from high of prev bullish candle to low of index
                    if (previousIndexIsBullish)
                    {
                        startIndex = i + 1;
                        entryOffset = 1;
                        imbalanceEntry = previousIndexHigh;
                        imbalanceExit = indexLow;
                    }
                    else
                    {
                        // Check to see if we have a lower wick. If so, go from wick on prev to wick on index
                        if (previousIndexLow < previousIndexClose)
                        {
                            startIndex = i + 1;
                            entryOffset = 1;
                            imbalanceEntry = previousIndexClose;
                            imbalanceExit = indexLow;
                        }
                        // else go from body on prev to wick on index
                        else
                        {
                            startIndex = i + 1;
                            entryOffset = 1;
                            imbalanceEntry = previousIndexHigh;
                            // don't have to check if index is lower here since that is already done
                            imbalanceExit = indexLow;
                        }
                    }

                    description = "Bullish Index Candle Lower Than Previous With Under Wick";
                }
                else if (bearishIndexLowerThanPreviousZone)
                {
                    startIndex = i;
                    entryOffset = 0;
                    imbalanceEntry = indexHigh;
                    imbalanceExit = indexLow;
                    description = "Bearish Index Candle Lower Than Preivous";
                }
                else if (bearishIndexWithinPreviousZone)
                {
                    startIndex = i;
                    entryOffset = 0;
                    imbalanceEntry = indexHigh;
                    imbalanceExit = indexLow;
                    description = "Bearish Index Within Previous";
                }
                else if (indexWithinPreviousBullishUpperWickZone)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = previousIndexClose;
                    description = "Index Candle Within Previous Bullish Wick";
                }
                else if (indexWithinPreviousBullishBodyZone)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = indexLow;
                    description = "Index Candle Within Preivous Bullish Body";
                }
                else if (indexWithinPreviousBearishZone)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = previousIndexLow;
                    description = "Index Candle Within Preivous Bearish";
                }
                else if (indexAbovePreviousBullishWithWickBelowZone)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexOpen;
                    imbalanceExit = previousIndexLow;
                    description = "Index Candle Above Preivous Bullish With Lower Wick";
                }
                else if (indexAbovePreviousBullishWithWickAboveZone)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = previousIndexOpen;
                    description = "Index Candle Above Prevous Bullish With Upper Wick";
                }
                else if (indexAbovePreviousBullishWithoutWickZone)
                {
                    if (candleTwoBeforeIndexIsBullish)
                    {
                        // We just need to check if our index + 1 candle opened lower than it or if our index + 2 candle has a wick
                        if (candleTwoBeforeIndexHigh > previousIndexOpen)
                        {
                            startIndex = i + 2;
                            entryOffset = 2;
                            imbalanceEntry = candleTwoBeforeIndexHigh;
                            imbalanceExit = previousIndexLow;
                        }
                        else if (candleTwoBeforeIndexOpen > candleTwoBeforeIndexLow)
                        {
                            startIndex = i + 2;
                            entryOffset = 2;
                            imbalanceEntry = candleTwoBeforeIndexOpen;
                            imbalanceExit = candleTwoBeforeIndexLow;
                        }
                    }
                    else
                    {
                        startIndex = i + 2;
                        entryOffset = 2;
                        imbalanceEntry = candleTwoBeforeIndexHigh;

                        if (candleTwoBeforeIndexLow < previousIndexLow)
                        {
                            imbalanceExit = candleTwoBeforeIndexLow;
                        }
                        else
                        {
                            imbalanceExit = previousIndexLow;
                        }
                    }

                    description = "Index Candle Above Preivous Bullish Without Wick";
                }
                else if (indexAbovePreviousBearishZone)
                {
                    startIndex = i + 1;
                    entryOffset == 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = previousIndexLow;
                    description = "Index Candle Above Preivous Bearish";
                }
                else
                {
                    continue;
                }

                bool overlappingZones = false;
                for (int j = 1; j <= mMaxZones; j++)
                {
                    int zoneIndex = mMaxZones - j;
                    if (CheckPointer(mZones[zoneIndex]) != POINTER_INVALID)
                    {
                        if (startIndex >= mZones[zoneIndex].StartIndex() || imbalanceExit < mZones[zoneIndex].EntryPrice())
                        {
                            overlappingZones = true;
                        }
                    }
                }

                if (overlappingZones)
                {
                    continue;
                }

                if (imbalanceExit > iHigh(mSymbol, mTimeFrame, mStartIndex))
                {
                    continue;
                }

                double lowestPriceAfterIndex = 0.0;
                // Check to make sure we haven't gone below the zone within the MB. This can happen in large MBs when price bounces around a lot
                if (!MQLHelper::GetLowestLowBetween(mSymbol, mTimeFrame, startIndex - entryOffset, endingIndex, false, lowestPriceAfterIndex))
                {
                    continue;
                }

                if (lowestPriceAfterIndex < imbalanceExit)
                {
                    continue;
                }

                int firstIndexAboveZone = EMPTY;
                for (int j = startIndex - entryOffset; j >= 0; j--)
                {
                    if (iHigh(mSymbol, mTimeFrame, j) > imbalanceEntry)
                    {
                        firstIndexAboveZone = j;
                        break;
                    }
                }

                double lowestPriceAfterValidation = 0.0;
                if (!MQLHelper::GetLowestLowBetween(mSymbol, mTimeFrame, firstIndexAboveZone, endingIndex, false, lowestPriceAfterValidation))
                {
                    continue;
                }

                bool mitigatedZone = lowestPriceAfterValidation < imbalanceEntry;

                // only allow zones we haven't added yet, that follow the mitigation parameter, that arenen't single ticks, and occur after the start of the MB
                if ((allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit && startIndex <= mStartIndex)
                {
                    // account for zones after the validaiton of an mb
                    int endIndex = i >= mEndIndex ? mEndIndex : i;
                    AddZone(description, startIndex, imbalanceEntry, endIndex, imbalanceExit);
                }

                runningZoneCount += 1;
            }

            prevImbalance = currentImbalance;
        }
    }
    else if (mType == OP_SELL)
    {
        // only go from high -> current so that we only grab imbalances that are in the impulse taht broke sructure and not in the move up
        for (int i = startingIndex; i >= endingIndex; i--)
        {
            // can only calculate imbalances for candles that we have a candle before and after for.
            // If we're on the current candle, then we don't have one after and we have to do the calculation on the previous candle
            int index = calculatingOnCurrentCandle ? i + 1 : i;

            // make sure imbalance is in current mb. This allows for imbalances after the MB was validated
            currentImbalance = iLow(mSymbol, mTimeFrame, index + 1) > iHigh(mSymbol, mTimeFrame, index - 1);

            bool previousIsBullish = iOpen(mSymbol, mTimeFrame, index + 1) < iClose(mSymbol, mTimeFrame, index + 1);
            bool pushUp = iHigh(mSymbol, mTimeFrame, index) > iHigh(mSymbol, mTimeFrame, index + 1) ||
                          iOpen(mSymbol, mTimeFrame, index) > iClose(mSymbol, mTimeFrame, index + 1) ||
                          previousIsBullish;

            if (currentImbalance && prevImbalance && pushUp)
            {
                int startIndex;
                double imbalanceEntry;
                double imbalanceExit;

                double indexOpen = iOpen(mSymbol, mTimeFrame, index);
                double indexHigh = iHigh(mSymbol, mTimeFrame, index);

                double previousIndexHigh = iHigh(mSymbol, mTimeFrame, index + 1);
                double previousIndexLow = iLow(mSymbol, mTimeFrame, index + 1);

                // First Check for Wick Zones
                if (indexOpen < previousIndexLow && indexHigh > previousIndexHigh)
                {
                    startIndex = index;
                    imbalanceEntry = indexOpen;
                    imbalanceExit = indexHigh;
                }
                // Then Check For Tick / 1 Sec Special Zone
                else if (previousIndexHigh == previousIndexLow &&
                         previousIndexHigh > indexHigh &&
                         iLow(mSymbol, mTimeFrame, index + 2) < previousIndexLow &&
                         iHigh(mSymbol, mTimeFrame, index + 2) < previousIndexHigh)
                {
                    startIndex = index + 2;
                    imbalanceEntry = iHigh(mSymbol, mTimeFrame, index + 2);
                    imbalanceExit = previousIndexHigh;
                }
                // Else use Low of previous candle for entry and Highest Between the index and previous for exit
                else
                {
                    startIndex = index + 1;
                    imbalanceEntry = iLow(mSymbol, mTimeFrame, index + 1);
                    if (previousIsBullish)
                    {
                        if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, 1, index, true, imbalanceExit))
                        {
                            return;
                        }
                    }
                    else
                    {
                        imbalanceExit = indexHigh;
                    }
                }

                if (imbalanceExit < iLow(mSymbol, mTimeFrame, mStartIndex))
                {
                    continue;
                }

                /*
                if (imbalanceEntry == imbalanceExit)
                {
                    if (iLow(mSymbol, mTimeFrame, startIndex + 1) < imbalanceEntry && iHigh(mSymbol, mTimeFrame, startIndex + 1) < imbalanceExit)
                    {
                        startIndex += 1;
                        imbalanceEntry = iLow(mSymbol, mTimeFrame, startIndex);
                    }
                }
                */

                double highestPrice;
                if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, index - endingIndex, endingIndex, false, highestPrice))
                {
                    return;
                }

                bool mitigatedZone = highestPrice > imbalanceEntry;

                // only allow zones we haven't added yet, that follow the mitigation parameter, that arenen't single ticks, and occur after the start of the zone
                if (runningZoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit && startIndex <= mStartIndex)
                {
                    int endIndex = mEndIndex <= index ? mEndIndex : index;
                    AddZone("", startIndex, imbalanceEntry, endIndex, imbalanceExit);
                }

                runningZoneCount += 1;
            }

            prevImbalance = currentImbalance;
        }
    }
}
/*

               _     _ _                       _   _               _
   _ __  _   _| |__ | (_) ___   _ __ ___   ___| |_| |__   ___   __| |___
  | '_ \| | | | '_ \| | |/ __| | '_ ` _ \ / _ \ __| '_ \ / _ \ / _` / __|
  | |_) | |_| | |_) | | | (__  | | | | | |  __/ |_| | | | (_) | (_| \__ \
  | .__/ \__,_|_.__/|_|_|\___| |_| |_| |_|\___|\__|_| |_|\___/ \__,_|___/
  |_|

*/
// --------- Constructor / Destructor --------
MB::MB(string symbol, int timeFrame, int number, int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones, bool allowZoneWickBreaks)
{
    mSymbol = symbol;
    mTimeFrame = timeFrame;

    mNumber = number;
    mType = type;
    mStartIndex = startIndex;
    mEndIndex = endIndex;
    mHighIndex = highIndex;
    mLowIndex = lowIndex;

    mIsBroken = false;

    mMaxZones = maxZones;
    mZoneCount = 0;
    mUnretrievedZoneCount = 0;
    mAllowZoneWickBreaks = allowZoneWickBreaks;

    mName = "MB: " + IntegerToString(number);
    mDrawn = false;

    ArrayResize(mZones, maxZones);
}

MB::~MB()
{
    ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);

    for (int i = mMaxZones - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            break;
        }

        delete mZones[i];
    }
}

// ------------- Maintenance Methods ---------------
void MB::UpdateIndexes(int barIndex)
{
    mStartIndex = mStartIndex + barIndex;
    mEndIndex = mEndIndex + barIndex;
    mHighIndex = mHighIndex + barIndex;
    mLowIndex = mLowIndex + barIndex;

    for (int i = mMaxZones - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            break;
        }

        mZones[i].UpdateIndexes(barIndex);
    }
}
// --------------- Adding Zones -------------------
// Checks for zones that are within the MB
void MB::CheckAddZones(bool allowZoneMitigation)
{
    int startIndex = mType == OP_BUY ? mLowIndex : mHighIndex;
    InternalCheckAddZones(startIndex, mEndIndex, allowZoneMitigation, false);
}
// Checks for  zones that occur after the MB
void MB::CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation)
{
    // Add one to this since the candle the before the end index might not have been able to set its zone?
    InternalCheckAddZones(mEndIndex, barIndex, allowZoneMitigation, true);
}

// Add zones
void MB::AddZone(string description, int startIndex, double entryPrice, int endIndex, double exitPrice)
{
    if (mZoneCount < mMaxZones)
    {
        // So Zone Numbers Match the order they are placed in the array, from back to front with the furthest in the back
        int zoneNumber = mMaxZones - mZoneCount - 1;
        Zone *zone = new Zone(mSymbol, mTimeFrame, mNumber, zoneNumber, mType, description, startIndex, entryPrice, endIndex, exitPrice, mAllowZoneWickBreaks);

        mZones[zoneNumber] = zone;

        mZoneCount += 1;
        mUnretrievedZoneCount += 1;
    }
}