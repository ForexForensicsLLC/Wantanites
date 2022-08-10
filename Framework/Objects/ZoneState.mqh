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
    string mDescription;

    int mStartIndex;
    int mEndIndex;

    double mEntryPrice;
    double mExitPrice;

    bool mAllowWickBreaks;
    bool mWasRetrieved;
    bool mDrawn;
    string mName;

public:
    // --- Getters ---
    string Symbol() { return mSymbol; }
    int TimeFrame() { return mTimeFrame; }

    int Number() { return mNumber; }
    int MBNumber() { return mMBNumber; }
    int Type() { return mType; }
    string Description() { return mDescription; }

    int StartIndex() { return mStartIndex; }
    int EndIndex() { return mEndIndex; }

    double EntryPrice() { return mEntryPrice; }
    double ExitPrice() { return mExitPrice; }

    bool WasRetrieved() { return mWasRetrieved; }

    // --- Computed Properties ---
    double Range() { return MathAbs(mEntryPrice - mExitPrice); }

    // Tested
    bool IsHolding(int barIndex);

    // Tested
    bool IsBroken();

    // Tested
    bool BelowDemandZone(int barIndex);

    // Tested
    bool AboveSupplyZone(int barIndex);

    // --- Display Methods ---
    string ToString();
    string ToSingleLineString();
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
// checks if price is or was  in the zone from the barIndex, and the zone hasn't been broken
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

        return low <= mEntryPrice && !IsBroken();
    }
    else if (mType == OP_SELL)
    {
        // TODO: Still Needed? -> subtract 2 so that the imbalance candle can't count as having entered the zone
        double high;
        if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, barIndex, 0, false, high))
        {
            return false;
        }

        return high >= mEntryPrice && !IsBroken();
    }

    return false;
}

// checks if a zone was broken from its entry index to the current bar
bool ZoneState::IsBroken()
{
    if (mType == OP_BUY)
    {
        int lowestIndex;
        if (!MQLHelper::GetLowest(mSymbol, mTimeFrame, MODE_LOW, mStartIndex, 0, false, lowestIndex))
        {
            return false;
        }

        return BelowDemandZone(lowestIndex);
    }
    else if (mType == OP_SELL)
    {
        int highestIndex;
        if (!MQLHelper::GetHighest(mSymbol, mTimeFrame, MODE_HIGH, mStartIndex, 0, false, highestIndex))
        {
            return false;
        }

        return AboveSupplyZone(highestIndex);
    }

    return false;
}

// ------------------- Display Methods ---------------------
// returns a string description about the zone
string ZoneState::ToString()
{
    return "Zone - TF: " + IntegerToString(mTimeFrame) +
           ", Entry: " + IntegerToString(mStartIndex) +
           ", Exit: " + IntegerToString(mEndIndex);
}

string ZoneState::ToSingleLineString()
{
    double lowestAfter;
    double highestAfter;

    MQLHelper::GetLowestLow(mSymbol, mTimeFrame, mStartIndex - 1, 0, false, lowestAfter);
    MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, mStartIndex - 1, 0, false, highestAfter);

    return " Zone: " + IntegerToString(Number()) +
           " Description: " + Description() +
           " Entry Index: " + IntegerToString(StartIndex()) +
           " Exit Index: " + IntegerToString(EndIndex()) +
           " Entry Price: " + DoubleToString(EntryPrice(), _Digits) +
           " Exit Price: " + DoubleToString(ExitPrice(), _Digits) +
           " Lowest After: " + DoubleToString(lowestAfter, _Digits) +
           " Highest After: " + DoubleToString(highestAfter, _Digits);
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
                      iTime(mSymbol, mTimeFrame, mStartIndex), // Start
                      mEntryPrice,                             // Entry
                      iTime(mSymbol, mTimeFrame, mEndIndex),   // End
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