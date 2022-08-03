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

    bool IsBroken(int barIndex);

    bool GetUnretrievedZones(int mbOffset, ZoneState *&zoneStates[]);
    bool GetClosestValidZone(ZoneState *&zoneStates);
    bool ClosestValidZoneIsHolding(int barIndex);

    // --------- Display Methods ---------
    string ToString();
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
            if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, barIndex, 0, false, low))
            {
                return false;
            }

            mIsBroken = low < iLow(mSymbol, mTimeFrame, mLowIndex);
        }
        else if (mType == OP_SELL)
        {
            double high;
            if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, barIndex, 0, false, high))
            {
                return false;
            }

            mIsBroken = high > iHigh(mSymbol, mTimeFrame, mHighIndex);
        }
    }

    return mIsBroken;
}

bool MBState::GetUnretrievedZones(int mbOffset, ZoneState *&zoneStates[])
{
    bool retrievedZones = false;
    for (int i = (mZoneCount - mUnretrievedZoneCount); i < mZoneCount; i++)
    {
        if (!mZones[i].WasRetrieved())
        {
            mZones[i].WasRetrieved(true);
            zoneStates[i + mbOffset] = mZones[i];

            retrievedZones = true;
        }
    }

    mUnretrievedZoneCount = 0;
    return retrievedZones;
}

bool MBState::GetClosestValidZone(ZoneState *&zoneState)
{
    for (int i = mZoneCount - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) != POINTER_INVALID && !mZones[i].IsBroken(0))
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
    return "MB - TF: " + IntegerToString(mTimeFrame) +
           ", Type: " + IntegerToString(mType) +
           ", Start: " + IntegerToString(mStartIndex) +
           ", End: " + IntegerToString(mEndIndex) +
           ", High: " + IntegerToString(mHighIndex) +
           ", Low: " + IntegerToString(mLowIndex);
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
    for (int i = 0; i < mZoneCount; i++)
    {
        mZones[i].Draw(printErrors);
    }
}
