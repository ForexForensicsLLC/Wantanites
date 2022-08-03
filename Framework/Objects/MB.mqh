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

/*

       _           _                 _   _
    __| | ___  ___| | __ _ _ __ __ _| |_(_) ___  _ __
   / _` |/ _ \/ __| |/ _` | '__/ _` | __| |/ _ \| '_ \
  | (_| |  __/ (__| | (_| | | | (_| | |_| | (_) | | | |
   \__,_|\___|\___|_|\__,_|_|  \__,_|\__|_|\___/|_| |_|


*/
class MB : public MBState
{
private:
    void InternalCheckAddZones(int startingIndex, int endingIndex, bool allowZoneMitigation, bool calculatingOnCurrentCandle);

public:
    // --- Constructors / Destructors ----------
    MB(string symbol, int timeFrame, int number, int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones);
    ~MB();

    // --- Maintenance Methods ---
    void UpdateIndexes(int barIndex);

    // ---- Adding Zones -------------
    void CheckAddZones(bool allowZoneMitigation);
    void CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation);
    void AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice);
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
        // only go from low -> current so that we only grab imbalances that are in the imbpulse that broke structure and not in the move down
        for (int i = startingIndex; i >= endingIndex; i--)
        {
            // can only calculate imbalances for candles that we have a candle before and after for.
            // If we're on the current candle, then we don't have one after and we have to do the calculation on the previous candle
            int index = calculatingOnCurrentCandle ? i + 1 : i;

            double imbalanceExit = 0.0;
            if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, 1, index, true, imbalanceExit))
            {
                continue;
            }

            // make sure imbalance is in current mb. This allows for imbalances after the MB was valdiated
            currentImbalance = iHigh(mSymbol, mTimeFrame, index + 1) < iLow(mSymbol, mTimeFrame, index - 1) && imbalanceExit < iHigh(mSymbol, mTimeFrame, mStartIndex);

            if (currentImbalance && !prevImbalance)
            {
                double imbalanceEntry = iHigh(mSymbol, mTimeFrame, index + 1);

                double lowestPrice = 0.0;
                if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, index - endingIndex, endingIndex, false, lowestPrice))
                {
                    continue;
                }

                bool mitigatedZone = lowestPrice < imbalanceEntry;

                // only allow zones we haven't added yet, that follow the mitigation parameter, that arenen't single ticks, and occur after the start of the zone
                if (runningZoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit && index + 1 <= mStartIndex)
                {
                    // account for zones after the validaiton of an mb
                    int endIndex = mEndIndex <= index ? mEndIndex : index;
                    AddZone(index + 1, imbalanceEntry, endIndex, imbalanceExit);
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

            double imbalanceExit;
            if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, 1, index, true, imbalanceExit))
            {
                return;
            }

            // make sure imbalance is in current mb. This allows for imbalances after the MB was validated
            currentImbalance = iLow(mSymbol, mTimeFrame, index + 1) > iHigh(mSymbol, mTimeFrame, index - 1) && imbalanceExit > iLow(mSymbol, mTimeFrame, mStartIndex);

            if (currentImbalance && !prevImbalance)
            {
                double imbalanceEntry = iLow(mSymbol, mTimeFrame, index + 1);
                double highestPrice;
                if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, index - endingIndex, endingIndex, false, highestPrice))
                {
                    return;
                }

                bool mitigatedZone = highestPrice > imbalanceEntry;

                // only allow zones we haven't added yet, that follow the mitigation parameter, that arenen't single ticks, and occur after the start of the zone
                if (runningZoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit && index + 1 <= mStartIndex)
                {
                    int endIndex = mEndIndex <= index ? mEndIndex : index;
                    AddZone(index + 1, imbalanceEntry, endIndex, imbalanceExit);
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
MB::MB(string symbol, int timeFrame, int number, int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones)
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

    mName = "MB: " + IntegerToString(number);
    mDrawn = false;

    ArrayResize(mZones, maxZones);
}

MB::~MB()
{
    ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);

    for (int i = 0; i < mZoneCount; i++)
    {
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

    for (int i = 0; i < mZoneCount; i++)
    {
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
    InternalCheckAddZones(mEndIndex, barIndex, allowZoneMitigation, true);
}

// Add zones
void MB::AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice)
{
    if (mZoneCount < mMaxZones)
    {
        Zone *zone = new Zone(mSymbol, mTimeFrame, mNumber, mZoneCount, mType, entryIndex, entryPrice, exitIndex, exitPrice, false);

        mZones[mZoneCount] = zone;

        mZoneCount += 1;
        mUnretrievedZoneCount += 1;
    }
}