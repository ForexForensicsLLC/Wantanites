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
private:
    // Tested
    void InternalCheckAddZones(int startingIndex, int endingIndex, bool allowZoneMitigation, bool calculatingOnCurrentCandle);

    // Tested
    bool PendingZoneIsOverlappingOtherZone(int type, int startIndex, double imbalanceExit);

    // Tested
    bool PendingDemandZoneWasMitigated(int startIndex, int endingIndex, int entryOffset, double imbalanceEntry);

    // Tested
    bool PendingSupplyZoneWasMitigated(int startIndex, int endingIndex, int entryOffset, double imbalanceEntry);

public:
    // --- Constructors / Destructors ----------
    MB(string symbol, int timeFrame, int number, int type, datetime startDateTime, datetime endDateTime, datetime highDateTime, datetime lowDateTime,
       int maxZones, bool allowZoneWickBreaks);
    ~MB();

    // --- Maintenance Methods ---
    void UpdateIndexes(int barIndex);

    // ---- Adding Zones -------------
    // Tested
    void CheckAddZones(bool allowZoneMitigation);

    // Tested
    void CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation);

    // Tested
    void AddZone(string description, int startIndex, double entryPrice, int endIndex, double exitPrice, int entryOffset);
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
    if (mType == OP_BUY)
    {
        if (calculatingOnCurrentCandle)
        {
            endingIndex += 1;
        }

        for (int i = startingIndex; i >= endingIndex; i--)
        {
            // don't calculate if our next candle is the most recent bar since we don't know if the imabalance will still be there when the candle closes
            bool currentImbalance = (i - 1) > 0 && iHigh(mSymbol, mTimeFrame, i + 1) < iLow(mSymbol, mTimeFrame, i - 1);
            if (currentImbalance)
            {
                // Zone variables that get set depending on the zone
                int startIndex = EMPTY;
                double imbalanceEntry = -1.0;
                double imbalanceExit = -1.0;
                string description = "";
                int entryOffset = EMPTY;

                // Open, Close, High, Low of the previous 3 bars
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

                // Bullish Flags
                bool indexIsBullish = indexOpen <= indexClose;
                bool previousIndexIsBullish = previousIndexOpen <= previousIndexClose;
                bool candleTwoBeforeIndexIsBullish = candleTwoBeforeIndexOpen <= candleTwoBeforeIndexClose;

                // Wick Flags
                bool indexWickLowerThanPreviousBody = (previousIndexIsBullish && indexOpen >= previousIndexOpen && indexLow <= previousIndexOpen) ||
                                                      (!previousIndexIsBullish && indexOpen >= previousIndexClose && indexLow <= previousIndexClose);
                bool bullishIndexWickLongerThanPreviousCandle = indexIsBullish && (indexOpen - indexLow) >= (previousIndexHigh - previousIndexLow);

                // Zones
                bool bullishIndexCandleWickLowerAndLongerThanPreviousCandle = indexIsBullish && indexWickLowerThanPreviousBody && bullishIndexWickLongerThanPreviousCandle;
                bool previousIndexIsBearishEngulfing = !previousIndexIsBullish && previousIndexHigh >= indexHigh && previousIndexLow <= indexLow;

                // Add previousIndexIsBullish so that a bearish candle before the imbalance will get caught as a default zone on the next candle
                bool candleTwoBeforeIndexIsBearishEngulfing = previousIndexIsBullish &&
                                                              !candleTwoBeforeIndexIsBullish &&
                                                              candleTwoBeforeIndexHigh >= previousIndexHigh &&
                                                              candleTwoBeforeIndexLow <= previousIndexLow;

                bool setDefault = true;
                // Wick Zone
                if (bullishIndexCandleWickLowerAndLongerThanPreviousCandle)
                {
                    startIndex = i;
                    entryOffset = 0;
                    imbalanceEntry = indexOpen;
                    imbalanceExit = indexLow;
                    description = "Bullish Index Candle Wick Lower And Longer Than Previous Candle";

                    setDefault = false;
                }
                // Engulfing Zones
                else if (previousIndexIsBearishEngulfing)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexHigh;
                    imbalanceExit = MathMin(indexLow, previousIndexLow);
                    description = "Previous index Is Bearish Engulfing";

                    setDefault = false;
                }
                else if (candleTwoBeforeIndexIsBearishEngulfing)
                {
                    startIndex = i + 2;
                    entryOffset = 2;
                    imbalanceEntry = candleTwoBeforeIndexHigh;
                    imbalanceExit = MathMin(indexLow, candleTwoBeforeIndexLow);
                    description = "Candle Two Before Index Is Bearish Engulfing";

                    // if the bearish engulfing 2 candles before has been mititgated, try and use a default zone within it
                    setDefault = PendingDemandZoneWasMitigated(startIndex, endingIndex, entryOffset, imbalanceEntry);
                }
                // Default Zones
                if (setDefault)
                {
                    // don't allow zones if 3 consecutive candles are above each other. Mainly a 1 sec thing
                    if (candleTwoBeforeIndexHigh <= previousIndexLow && previousIndexHigh <= indexLow)
                    {
                        continue;
                    }

                    // specifically for ticks on the 1 second chart
                    // if there is a candle above the tick that is before the imbalance, go from that candle to the tick
                    if (previousIndexLow <= indexLow && previousIndexHigh == previousIndexLow && candleTwoBeforeIndexHigh > previousIndexHigh)
                    {
                        startIndex = i + 2;
                        entryOffset = 2;
                        imbalanceEntry = MathMax(candleTwoBeforeIndexLow, candleTwoBeforeIndexClose);
                        imbalanceExit = previousIndexLow;
                        description = "Default Tick Candle Before";
                    }
                    else
                    {
                        startIndex = i + 1;
                        entryOffset = 1;
                        imbalanceEntry = previousIndexHigh;
                        imbalanceExit = MathMin(indexLow, previousIndexLow);
                        description = "Default Candle Before";
                    }
                }

                // don't create a zone on our previosu candle if there is an imbalance on it. If there should be a zone there it should have
                // been caught within the previous i check
                if (previousIndexIsBullish && candleTwoBeforeIndexHigh < indexLow && startIndex <= i + 1)
                {
                    continue;
                }

                if (PendingZoneIsOverlappingOtherZone(OP_BUY, startIndex, imbalanceExit))
                {
                    continue;
                }

                // Don't create zones that are higher than the MB
                if (imbalanceExit > iHigh(mSymbol, mTimeFrame, StartIndex()))
                {
                    continue;
                }

                // if we have an imbalance on our last index, we can't be mitigating or below it
                bool mitigatedZone = false;
                if (startIndex - entryOffset != endingIndex)
                {
                    double lowestPriceAfterIndex = 0.0;
                    if (!MQLHelper::GetLowestLowBetween(mSymbol, mTimeFrame, startIndex - entryOffset, endingIndex, false, lowestPriceAfterIndex))
                    {
                        continue;
                    }

                    // Check to make sure we havne't gone below the zone. This can happen if we have large mbs and price bounces around a lot.
                    // Also want to prevent huge zones that aren't technically mitigated but are basically the whole mb
                    if (lowestPriceAfterIndex < imbalanceEntry)
                    {
                        continue;
                    }

                    mitigatedZone = PendingDemandZoneWasMitigated(startIndex, endingIndex, entryOffset, imbalanceEntry);
                }

                // only allow zones that follow the mitigation parameter, that arenen't single ticks, and occur after the start of the MB
                if ((allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit && startIndex <= StartIndex())
                {
                    int endIndex = EndIndex();
                    if (startIndex == endIndex)
                    {
                        // move over 1 to the right if zone is right on the end or else I won't be able to see it
                        endIndex = i - 1;
                    }
                    else
                    {
                        // Account for zones after the validation of the mb
                        endIndex = endIndex <= i ? endIndex : i;
                    }
                    AddZone(description, startIndex, imbalanceEntry, endIndex, imbalanceExit, entryOffset);
                }
            }
        }
    }
    else if (mType == OP_SELL)
    {
        if (calculatingOnCurrentCandle)
        {
            endingIndex += 1;
        }

        // only go from high -> current so that we only grab imbalances that are in the impulse that broke sructure and not in the move up
        for (int i = startingIndex; i >= endingIndex; i--)
        {
            // don't calculate if our next candle is the most recent bar since we don't know if the imabalance will still be there when the candle closes
            bool currentImbalance = (i - 1) > 0 && iLow(mSymbol, mTimeFrame, i + 1) > iHigh(mSymbol, mTimeFrame, i - 1);
            if (currentImbalance)
            {
                // Zone variables that get set depending on the zone
                int startIndex = EMPTY;
                double imbalanceEntry = -1.0;
                double imbalanceExit = -1.0;
                string description = "";
                int entryOffset = EMPTY;

                // Open, Close, High, Low of the previous 3 bars
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

                // Bearish Flags
                bool indexIsBearish = indexOpen >= indexClose;
                bool previousIndexIsBearish = previousIndexOpen >= previousIndexClose;
                bool candleTwoBeforeIndexIsBearish = candleTwoBeforeIndexOpen >= candleTwoBeforeIndexClose;

                // Wick Flags
                bool indexWickHigherThanPreviousBody = (previousIndexIsBearish && indexOpen <= previousIndexOpen && indexHigh >= previousIndexOpen) ||
                                                       (!previousIndexIsBearish && indexOpen <= previousIndexClose && indexHigh >= previousIndexClose);
                bool bearishIndexWickLongerThanPreviousCandle = indexIsBearish && (indexHigh - indexOpen) >= (previousIndexHigh - previousIndexLow);

                // Zones
                bool bearishIndexCandleWickHigherAndLongerThanPreviousCandle = indexIsBearish && indexWickHigherThanPreviousBody && bearishIndexWickLongerThanPreviousCandle;
                bool previousIndexIsBullishEngulfing = !previousIndexIsBearish && previousIndexHigh >= indexHigh && previousIndexLow <= indexLow;

                // Add previousIndexIsBearish so that a bullish candle before the imbalance will get caught as a default zone on the next candle
                bool candleTwoBeforeIndexIsBullishEngulfing = previousIndexIsBearish &&
                                                              !candleTwoBeforeIndexIsBearish &&
                                                              candleTwoBeforeIndexHigh >= previousIndexHigh &&
                                                              candleTwoBeforeIndexLow <= previousIndexLow;

                bool setDefault = true;

                // Wick Zone
                if (bearishIndexCandleWickHigherAndLongerThanPreviousCandle)
                {
                    startIndex = i;
                    entryOffset = 0;
                    imbalanceEntry = indexOpen;
                    imbalanceExit = indexHigh;
                    description = "Bearish Index Candle Wick High And Longer Than Previous Candle Zone";

                    setDefault = false;
                }
                else if (previousIndexIsBullishEngulfing)
                {
                    startIndex = i + 1;
                    entryOffset = 1;
                    imbalanceEntry = previousIndexLow;
                    imbalanceExit = MathMax(indexHigh, previousIndexHigh);
                    description = "Previous Index Bullish Engulfing Zone";

                    setDefault = false;
                }
                else if (candleTwoBeforeIndexIsBullishEngulfing)
                {
                    startIndex = i + 2;
                    entryOffset = 2;
                    imbalanceEntry = candleTwoBeforeIndexLow;
                    imbalanceExit = MathMax(indexHigh, candleTwoBeforeIndexHigh);
                    description = "Two Before Index Bullish Engulfing Zone";

                    setDefault = true;
                }

                // Default Zone
                if (setDefault)
                {
                    if (candleTwoBeforeIndexLow >= previousIndexHigh && previousIndexLow >= indexHigh)
                    {
                        continue;
                    }

                    // specifically for ticks on the 1 second chart
                    // if there is a candle below the tick that is above and before the imbalance, go from thtat candle to the tick
                    if (previousIndexHigh >= indexHigh && previousIndexHigh == previousIndexLow && candleTwoBeforeIndexLow <= previousIndexLow)
                    {
                        startIndex = i + 2;
                        entryOffset = 2;
                        imbalanceEntry = MathMin(candleTwoBeforeIndexHigh, candleTwoBeforeIndexClose);
                        imbalanceExit = previousIndexHigh;
                        description = "Default Tick Zone";
                    }
                    else
                    {
                        startIndex = i + 1;
                        entryOffset = 1;
                        imbalanceEntry = previousIndexLow;
                        imbalanceExit = MathMax(indexHigh, previousIndexHigh);
                        description = "Default Zone";
                    }
                }

                // don't create a zone on the previous candle if it is bearish there is an imbalance on it. If there should be a zone there it should have been
                // caught within the previous check
                if (previousIndexIsBearish && candleTwoBeforeIndexLow > indexHigh && startIndex <= i + 1)
                {
                    continue;
                }

                if (PendingZoneIsOverlappingOtherZone(OP_SELL, startIndex, imbalanceExit))
                {
                    continue;
                }

                // don't create zones that are lower than the MB
                if (imbalanceExit < iLow(mSymbol, mTimeFrame, StartIndex()))
                {
                    continue;
                }

                // if we have an imbalance on our last index, we can't be mitigating or below it
                bool mitigatedZone = false;
                if (startIndex - entryOffset != endingIndex)
                {
                    double highestPriceAfterIndex = 0.0;
                    if (!MQLHelper::GetHighestHighBetween(mSymbol, mTimeFrame, startIndex - entryOffset, endingIndex, false, highestPriceAfterIndex))
                    {
                        continue;
                    }

                    // Check to make sure we havne't gone above the zone. This can happen if we have large mbs and price bounces around a lot.
                    // Also want to prevent huge zones that aren't technically mitigated but are basically the whole mb
                    if (highestPriceAfterIndex > imbalanceEntry)
                    {
                        continue;
                    }

                    mitigatedZone = PendingSupplyZoneWasMitigated(startIndex, endingIndex, entryOffset, imbalanceEntry);
                }

                // that follow the mitigation parameter, that arenen't single ticks, and occur after the start of the zone
                if ((allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit && startIndex <= StartIndex())
                {
                    int endIndex = EndIndex();
                    if (startIndex == endIndex)
                    {
                        // move over 1 to the right if zone is right on the end or else I won't be able to see it
                        endIndex = i - 1;
                    }
                    else
                    {
                        // Account for zones after the validation of the mb
                        endIndex = endIndex <= i ? endIndex : i;
                    }

                    AddZone(description, startIndex, imbalanceEntry, endIndex, imbalanceExit, entryOffset);
                }
            }
        }
    }
}

bool MB::PendingDemandZoneWasMitigated(int startIndex, int endingIndex, int entryOffset, double imbalanceEntry)
{
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
        return false;
    }

    return lowestPriceAfterValidation < imbalanceEntry;
}

bool MB::PendingSupplyZoneWasMitigated(int startIndex, int endingIndex, int entryOffset, double imbalanceEntry)
{
    int firstIndexAboveZone = EMPTY;
    for (int j = startIndex - entryOffset; j >= 0; j--)
    {
        if (iLow(mSymbol, mTimeFrame, j) < imbalanceEntry)
        {
            firstIndexAboveZone = j;
            break;
        }
    }

    double highestPriceAfterValidation = 0.0;
    if (!MQLHelper::GetHighestHighBetween(mSymbol, mTimeFrame, firstIndexAboveZone, endingIndex, false, highestPriceAfterValidation))
    {
        return false;
    }

    return highestPriceAfterValidation > imbalanceEntry;
}

bool MB::PendingZoneIsOverlappingOtherZone(int type, int startIndex, double imbalanceExit)
{
    bool overlappingZones = false;
    for (int j = 1; j <= mMaxZones; j++)
    {
        int zoneIndex = mMaxZones - j;
        if (CheckPointer(mZones[zoneIndex]) != POINTER_INVALID)
        {
            // Add one to this to prevent consecutive zones from forming
            if (startIndex + 1 >= mZones[zoneIndex].StartIndex() ||
                (type == OP_BUY && imbalanceExit < mZones[zoneIndex].EntryPrice()) ||
                (type == OP_SELL && imbalanceExit > mZones[zoneIndex].EntryPrice()))
            {
                return true;
            }
        }
    }

    return false;
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
MB::MB(string symbol, int timeFrame, int number, int type, datetime startDateTime, datetime endDateTime, datetime highDateTime, datetime lowDateTime,
       int maxZones, bool allowZoneWickBreaks)
{
    mSymbol = symbol;
    mTimeFrame = timeFrame;

    mNumber = number;
    mType = type;

    mStartDateTime = startDateTime;
    mEndDateTime = endDateTime;
    mHighDateTime = highDateTime;
    mLowDateTime = lowDateTime;

    mGlobalStartIsBroken = false;
    // mEndIsBroken = false;

    mSetupZoneNumber = EMPTY;
    mInsideSetupZone = Status::NOT_CHECKED;
    mPushedFurtherIntoSetupZone = Status::NOT_CHECKED;

    mMaxZones = maxZones;
    mZoneCount = 0;
    mUnretrievedZoneCount = 0;
    mAllowZoneWickBreaks = allowZoneWickBreaks;

    mName = "MB: " + IntegerToString(timeFrame) + "_" + IntegerToString(number);
    mDrawn = false;

    mHasImpulseValidation = Status::NOT_CHECKED;

    ArrayResize(mZones, maxZones);
}

MB::~MB()
{
    ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);
    ObjectsDeleteAll(ChartID(), mName + "imp");

    for (int i = mMaxZones - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            break;
        }

        delete mZones[i];
    }
}
// --------------- Adding Zones -------------------
// Checks for zones that are within the MB
void MB::CheckAddZones(bool allowZoneMitigation)
{
    int startIndex = mType == OP_BUY ? LowIndex() : HighIndex();
    InternalCheckAddZones(startIndex, EndIndex(), allowZoneMitigation, false);
}
// Checks for  zones that occur after the MB
void MB::CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation)
{
    // add one to this after the updates to allow an MB to break on tick since we can't calaculate the zone during that candel anymore, since the
    // imbalance might not be there when the candle closes.
    // Adding one to this allows us to safely check it after it has closed
    InternalCheckAddZones(EndIndex() + 1, barIndex, allowZoneMitigation, true);
}

// Add zones
void MB::AddZone(string description, int startIndex, double entryPrice, int endIndex, double exitPrice, int entryOffset)
{
    if (mZoneCount < mMaxZones)
    {
        // So Zone Numbers Match the order they are placed in the array, from back to front with the furthest in the back
        int zoneNumber = mMaxZones - mZoneCount - 1;
        Zone *zone = new Zone(mSymbol, mTimeFrame, mNumber, zoneNumber, mType, description, iTime(mSymbol, mTimeFrame, startIndex), entryPrice,
                              iTime(mSymbol, mTimeFrame, endIndex), exitPrice, entryOffset, mAllowZoneWickBreaks);

        mZones[zoneNumber] = zone;

        mZoneCount += 1;
        mUnretrievedZoneCount += 1;
    }
}