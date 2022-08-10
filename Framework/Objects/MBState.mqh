//+------------------------------------------------------------------+
//|                                                      MBState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\Zone.mqh>
#include <SummitCapital\Framework\Helpers\MQLHelper.mqh>

class MBState
{
protected:
    string mSymbol;
    int mTimeFrame;

    int mNumber;
    int mType;
    int mStartIndex;
    int mEndIndex;
    int mHighIndex;
    int mLowIndex;

    bool mIsBroken;
    bool mDrawn;

    Zone *mZones[];
    int mMaxZones;
    int mZoneCount;
    int mUnretrievedZoneCount;
    bool mAllowZoneWickBreaks;

    string mName;

public:
    // ------------- Getters --------------
    string Symbol() { return mSymbol; }
    int TimeFrame() { return mTimeFrame; }
    int Number() { return mNumber; }
    int Type() { return mType; }
    int StartIndex() { return mStartIndex; }
    int EndIndex() { return mEndIndex; }
    int HighIndex() { return mHighIndex; }
    int LowIndex() { return mLowIndex; }

    bool CanUseLowIndexForILow(int &lowIndex);
    bool CanUseHighIndexForIHigh(int &highIndex);

    int ZoneCount() { return mZoneCount; }
    int UnretrievedZoneCount() { return mUnretrievedZoneCount; }

    // Tested
    bool IsBroken(int barIndex);

    bool GetUnretrievedZones(ZoneState *&zoneStates[]);
    bool GetClosestValidZone(ZoneState *&zoneStates);
    bool ClosestValidZoneIsHolding(int barIndex);

    // Tested
    bool GetShallowestZone(ZoneState *&zoneState);

    // --------- Display Methods ---------
    string ToString();
    string ToSingleLineString();
    void Draw(bool printErrors);
    void DrawZones(bool printErrors);
};

bool MBState::IsBroken(int barIndex)
{
    if (!mIsBroken)
    {
        if (mType == OP_BUY)
        {
            double low;
            // Should Be Inclusive for when we are checknig the break from the MB End Index. Its not likely but the
            // end index can confirm the MB and break it in the same candle
            if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, barIndex, 0, true, low))
            {
                return false;
            }

            mIsBroken = low < iLow(mSymbol, mTimeFrame, mLowIndex);
        }
        else if (mType == OP_SELL)
        {
            double high;
            // Should Be Inclusive for when we are checknig the break from the MB End Index. Its not likely but the
            // end index can confirm the MB and break it in the same candle
            if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, barIndex, 0, true, high))
            {
                return false;
            }

            mIsBroken = high > iHigh(mSymbol, mTimeFrame, mHighIndex);
        }
    }

    return mIsBroken;
}

bool MBState::GetUnretrievedZones(ZoneState *&zoneStates[])
{
    ArrayResize(zoneStates, 0);

    bool retrievedZones = false;
    for (int i = mMaxZones - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            break;
        }

        if (!mZones[i].WasRetrieved())
        {
            ArrayResize(zoneStates, ArraySize(zoneStates) + 1);

            mZones[i].WasRetrieved(true);
            zoneStates[i] = mZones[i];

            retrievedZones = true;
        }
    }

    mUnretrievedZoneCount = 0;
    return retrievedZones;
}

bool MBState::GetShallowestZone(ZoneState *&zoneState)
{
    for (int i = 0; i <= mMaxZones - 1; i++)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            continue;
        }

        zoneState = mZones[i];
        return true;
    }

    return false;
}

bool MBState::GetClosestValidZone(ZoneState *&zoneState)
{
    for (int i = 0; i <= mMaxZones - 1; i++)
    {
        if (CheckPointer(mZones[i]) != POINTER_INVALID && !mZones[i].IsBroken())
        {
            zoneState = mZones[i];
            return true;
        }
    }

    return false;
}

bool MBState::ClosestValidZoneIsHolding(int barIndex)
{
    if (barIndex == -1)
    {
        barIndex = mEndIndex;
    }

    ZoneState *tempZoneState;
    if (GetClosestValidZone(tempZoneState))
    {
        return tempZoneState.IsHolding(barIndex);
    }

    return false;
}

// ---------------- Display Methods -------------------
// returns a string description of the MB
string MBState::ToString()
{
    return "MB - TF: " + IntegerToString(mTimeFrame) + "\n" +
           ", Type: " + IntegerToString(mType) + "\n" +
           ", Start: " + IntegerToString(mStartIndex) + "\n" +
           ", End: " + IntegerToString(mEndIndex) + "\n" +
           ", High: " + IntegerToString(mHighIndex) + "\n" +
           ", Low: " + IntegerToString(mLowIndex) + "\n";
}

string MBState::ToSingleLineString()
{
    string mbString = "MB - TF: " + IntegerToString(mTimeFrame) +
                      " Type: " + IntegerToString(mType) +
                      " Start: " + IntegerToString(mStartIndex) +
                      " End: " + IntegerToString(mEndIndex) +
                      " High: " + IntegerToString(mHighIndex) +
                      " Low: " + IntegerToString(mLowIndex);

    for (int i = 1; i <= ZoneCount(); i++)
    {
        int index = mMaxZones - i;
        if (CheckPointer(mZones[index]) == POINTER_INVALID)
        {
            break;
        }

        mbString += mZones[index].ToSingleLineString();
    }

    return mbString;
}
// Draws the current MB if it hasn't been drawn before
void MBState::Draw(bool printErrors)
{
    if (mDrawn)
    {
        return;
    }

    color clr = mType == OP_BUY ? clrLimeGreen : clrRed;

    if (!ObjectCreate(0, mName, OBJ_RECTANGLE, 0,
                      iTime(mSymbol, mTimeFrame, mStartIndex), // Start
                      iHigh(mSymbol, mTimeFrame, mHighIndex),  // High
                      iTime(mSymbol, mTimeFrame, mEndIndex),   // End
                      iLow(mSymbol, mTimeFrame, mLowIndex)))   // Low
    {
        if (printErrors)
        {
            Print("MB Object Creation Failed: ", GetLastError());
        }

        return;
    }

    ObjectSetInteger(0, mName, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, mName, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, mName, OBJPROP_BACK, false);
    ObjectSetInteger(0, mName, OBJPROP_FILL, false);
    ObjectSetInteger(0, mName, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, mName, OBJPROP_SELECTABLE, false);

    mDrawn = true;
}

void MBState::DrawZones(bool printErrors)
{
    for (int i = mMaxZones - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            break;
        }

        mZones[i].Draw(printErrors);
    }
}
