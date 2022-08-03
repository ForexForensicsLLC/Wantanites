//+------------------------------------------------------------------+
//|                                                    ZoneState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\MQLHelper.mqh>

class ZoneState
{
protected:
    string mSymbol;
    int mTimeFrame;

    int mMBNumber;
    int mNumber;
    int mType;

    int mEntryIndex;
    int mExitIndex;

    double mEntryPrice;
    double mExitPrice;

    bool mAllowWickBreaks;
    bool mIsBroken;
    bool mWasRetrieved;
    bool mDrawn;
    string mName;

    bool BelowDemandZone(int barIndex);
    bool AboveSupplyZone(int barIndex);

public:
    // --- Getters ---
    string Symbol() { return mSymbol; }
    int TimeFrame() { return mTimeFrame; }

    int Number() { return mNumber; }
    int MBNumber() { return mMBNumber; }
    int Type() { return mType; }

    int EntryIndex() { return mEntryIndex; }
    int ExitIndex() { return mExitIndex; }

    double EntryPrice() { return mEntryPrice; }
    double ExitPrice() { return mExitPrice; }

    bool WasRetrieved() { return mWasRetrieved; }

    // --- Computed Properties ---
    double Range() { return MathAbs(mEntryPrice - mExitPrice); }
    bool IsHolding(int barIndex);
    bool IsBroken(int barIndex);

    // --- Display Methods ---
    string ToString();
    void Draw(bool printErrors);
};
bool ZoneState::BelowDemandZone(int barIndex)
{
    return (mAllowWickBreaks && MathMin(iOpen(mSymbol, mTimeFrame, barIndex), iClose(mSymbol, mTimeFrame, barIndex)) < mExitPrice) || (!mAllowWickBreaks && iLow(mSymbol, mTimeFrame, barIndex) < mExitPrice);
}

bool ZoneState::AboveSupplyZone(int barIndex)
{
    return (mAllowWickBreaks && MathMax(iOpen(mSymbol, mTimeFrame, barIndex), iClose(mSymbol, mTimeFrame, barIndex)) > mExitPrice) || (!mAllowWickBreaks && iHigh(mSymbol, mTimeFrame, barIndex) > mExitPrice);
}
// ----------------- Computed Properties ----------------------
// checks if price is  currenlty in the zone, and the zone is holding
bool ZoneState::IsHolding(int barIndex)
{
    if (mType == OP_BUY)
    {
        // TODO: Sill Needed? -> Subtract 2 so that the imbalance candle can't count as having entered the zone
        double low;
        if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, barIndex, 0, false, low))
        {
            return false;
        }

        return low <= mEntryPrice && !BelowDemandZone(0);
    }
    else if (mType == OP_SELL)
    {
        // TODO: Still Needed? -> subtract 2 so that the imbalance candle can't count as having entered the zone
        double high;
        if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, barIndex, 0, false, high))
        {
            return false;
        }

        return high >= mEntryPrice && !AboveSupplyZone(0);
    }

    return false;
}

// checks if a zone was broken from its entry index to barIndex
bool ZoneState::IsBroken(int barIndex)
{
    if (!mIsBroken)
    {
        if (mType == OP_BUY)
        {
            int lowestIndex;
            if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, mEntryIndex - barIndex, barIndex, false, lowestIndex))
            {
                return false;
            }

            mIsBroken = BelowDemandZone(lowestIndex);
        }
        else if (mType == OP_SELL)
        {
            int highestIndex;
            if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, mEntryIndex - barIndex, barIndex, false, highestIndex))
            {
                return false;
            }

            mIsBroken = AboveSupplyZone(highestIndex);
        }
    }

    return mIsBroken;
}

// ------------------- Display Methods ---------------------
// returns a string description about the zone
string ZoneState::ToString()
{
    return "Zone - TF: " + IntegerToString(mTimeFrame) +
           ", Entry: " + IntegerToString(mEntryIndex) +
           ", Exit: " + IntegerToString(mExitIndex);
}
// Draws the zone on the chart if it hasn't been drawn before
void ZoneState::Draw(bool printErrors)
{
    if (mDrawn)
    {
        return;
    }

    color clr = mType == OP_BUY ? clrGold : clrMediumVioletRed;

    if (!ObjectCreate(0, mName, OBJ_RECTANGLE, 0,
                      iTime(mSymbol, mTimeFrame, mEntryIndex), // Start
                      mEntryPrice,                             // Entry
                      iTime(mSymbol, mTimeFrame, mExitIndex),  // End
                      mExitPrice))                             // Exit
    {
        if (printErrors)
        {
            Print("Zone Object Creation Failed: ", GetLastError());
        }

        return;
    }

    ObjectSetInteger(0, mName, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, mName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, mName, OBJPROP_BACK, false);
    ObjectSetInteger(0, mName, OBJPROP_FILL, true);
    ObjectSetInteger(0, mName, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, mName, OBJPROP_SELECTABLE, false);

    mDrawn = true;
}