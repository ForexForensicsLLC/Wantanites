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

enum Status
{
    NOT_CHECKED,
    IS_TRUE,
    IS_FALSE
};

class MBState
{
protected:
    string mSymbol;
    int mTimeFrame;

    int mNumber;
    int mType;

    datetime mStartDateTime;
    datetime mEndDateTime;
    datetime mHighDateTime;
    datetime mLowDateTime;

    bool mStartIsBroken;

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
    /*
    int StartIndex() { return mStartIndex; }
    int EndIndex() { return mEndIndex; }
    int HighIndex() { return mHighIndex; }
    int LowIndex() { return mLowIndex; }
    */
    int StartIndex() { return iBarShift(mSymbol, mTimeFrame, mStartDateTime); }
    int EndIndex() { return iBarShift(mSymbol, mTimeFrame, mEndDateTime); }
    int HighIndex() { return iBarShift(mSymbol, mTimeFrame, mHighDateTime); }
    int LowIndex() { return iBarShift(mSymbol, mTimeFrame, mLowDateTime); }

    bool mEndIsBroken;

    int mSetupZoneNumber;
    Status mInsideSetupZone;

    bool CanUseLowIndexForILow(int &lowIndex);
    bool CanUseHighIndexForIHigh(int &highIndex);

    int ZoneCount() { return mZoneCount; }
    int UnretrievedZoneCount() { return mUnretrievedZoneCount; }

    // Tested
    bool StartIsBroken();
    bool EndIsBroken();

    bool GetUnretrievedZones(ZoneState *&zoneStates[]);
    bool GetClosestValidZone(ZoneState *&zoneStates);
    bool ClosestValidZoneIsHolding(int barIndex);

    // Tested
    bool GetShallowestZone(ZoneState *&zoneState);
    bool GetDeepestHoldingZone(ZoneState *&zoneState);

    // --------- Display Methods ---------
    string ToString();
    string ToSingleLineString();
    void Draw(bool printErrors);
    void DrawZones(bool printErrors);
};

bool MBState::StartIsBroken()
{
    if (!mStartIsBroken)
    {
        if (mType == OP_BUY)
        {
            double low;
            if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, LowIndex(), 0, false, low))
            {
                return false;
            }

            mStartIsBroken = low < iLow(mSymbol, mTimeFrame, LowIndex());
        }
        else if (mType == OP_SELL)
        {
            double high;
            if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, HighIndex(), 0, false, high))
            {
                return false;
            }

            mStartIsBroken = high > iHigh(mSymbol, mTimeFrame, HighIndex());
        }
    }

    return mStartIsBroken;
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

bool MBState::GetDeepestHoldingZone(ZoneState *&zoneState)
{
    for (int i = mMaxZones - 1; i >= 0; i--)
    {
        if (CheckPointer(mZones[i]) == POINTER_INVALID)
        {
            break;
        }

        if (mZones[i].IsHoldingFromStart())
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
        barIndex = EndIndex();
    }

    ZoneState *tempZoneState;
    if (GetClosestValidZone(tempZoneState))
    {
        if (barIndex > tempZoneState.EndIndex())
        {
            barIndex = tempZoneState.EndIndex();
        }

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
           ", Start: " + IntegerToString(StartIndex()) + "\n" +
           ", End: " + IntegerToString(EndIndex()) + "\n" +
           ", High: " + IntegerToString(HighIndex()) + "\n" +
           ", Low: " + IntegerToString(LowIndex()) + "\n";
}

string MBState::ToSingleLineString()
{
    string mbString = "MB - TF: " + IntegerToString(mTimeFrame) +
                      " Type: " + IntegerToString(mType) +
                      " Start: " + IntegerToString(StartIndex()) +
                      " End: " + IntegerToString(EndIndex()) +
                      " High: " + IntegerToString(HighIndex()) +
                      " Low: " + IntegerToString(LowIndex());

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
                      mStartDateTime,                          // Start
                      iHigh(mSymbol, mTimeFrame, HighIndex()), // High
                      mEndDateTime,                            // End
                      iLow(mSymbol, mTimeFrame, LowIndex())))  // Low
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
