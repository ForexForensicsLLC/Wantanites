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
    WAS_CHECKED,
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

    int mWidth;
    double mHeight;
    double mHeightToWidthRatio;

    bool mGlobalStartIsBroken;
    // bool mGlobalEndIsBroken;

    bool mDrawn;

    Zone *mZones[];
    int mMaxZones;
    int mZoneCount;
    int mUnretrievedZoneCount;
    bool mAllowZoneWickBreaks;

    string mName;

    Status mHasImpulseValidation;

public:
    // ------------- Getters --------------
    string Symbol() { return mSymbol; }
    int TimeFrame() { return mTimeFrame; }
    int Number() { return mNumber; }
    int Type() { return mType; }

    int StartIndex() { return iBarShift(mSymbol, mTimeFrame, mStartDateTime); }
    int EndIndex() { return iBarShift(mSymbol, mTimeFrame, mEndDateTime); }
    int HighIndex() { return iBarShift(mSymbol, mTimeFrame, mHighDateTime); }
    int LowIndex() { return iBarShift(mSymbol, mTimeFrame, mLowDateTime); }

    int Width();
    double Height();
    double HeightToWidthRatio();

    double PercentOfMBPrice(double percent);

    bool mEndIsBroken;

    int mSetupZoneNumber;
    Status mInsideSetupZone;
    Status mPushedFurtherIntoSetupZone;

    int ZoneCount() { return mZoneCount; }
    int UnretrievedZoneCount() { return mUnretrievedZoneCount; }

    // Tested
    bool StartIsBrokenFromBarIndex(int barIndex);
    bool GlobalStartIsBroken();

    // bool EndIsBrokenFromBarIndex(int barIndex);
    // bool GlobalEndIsBroken();

    bool GetUnretrievedZones(ZoneState *&zoneStates[]);
    bool GetClosestValidZone(ZoneState *&zoneState);
    bool ClosestValidZoneIsHolding(int barIndex);

    // Tested
    bool GetShallowestZone(ZoneState *&zoneState);
    bool GetDeepestHoldingZone(ZoneState *&zoneState);

    bool HasImpulseValidation();

    // --------- Display Methods ---------
    string ToString();
    string ToSingleLineString();
    void Draw(bool printErrors);
    void DrawZones(bool printErrors);
};

int MBState::Width()
{
    if (mWidth == 0.0)
    {
        mWidth = StartIndex() - EndIndex();
    }

    return mWidth;
}

double MBState::Height()
{
    if (mHeight == 0.0)
    {
        mHeight = NormalizeDouble(iHigh(Symbol(), TimeFrame(), HighIndex()) - iLow(Symbol(), TimeFrame(), LowIndex()), Digits);
    }

    return mHeight;
}

double MBState::HeightToWidthRatio()
{
    if (mHeightToWidthRatio == 0.0)
    {
        double height = Height();
        if (height <= 0)
        {
            return 0.0;
        }

        mHeightToWidthRatio = Width() / height;
    }

    return mHeightToWidthRatio;
}

double MBState::PercentOfMBPrice(double percent)
{
    if (Type() == OP_BUY)
    {
        return iHigh(Symbol(), TimeFrame(), HighIndex()) - ((iHigh(Symbol(), TimeFrame(), HighIndex()) - iLow(Symbol(), TimeFrame(), LowIndex())) * percent);
    }
    else if (Type() == OP_SELL)
    {
        return iLow(Symbol(), TimeFrame(), LowIndex()) + ((iHigh(Symbol(), TimeFrame(), HighIndex()) - iLow(Symbol(), TimeFrame(), LowIndex())) * percent);
    }

    return 0.0;
}

bool MBState::StartIsBrokenFromBarIndex(int barIndex)
{
    if (mType == OP_BUY)
    {
        // This is for wick breaks
        // double low;
        // if (!MQLHelper::GetLowestLowBetween(mSymbol, mTimeFrame, LowIndex(), barIndex, false, low))
        // {
        //     return false;
        // }

        // return low < iLow(mSymbol, mTimeFrame, LowIndex());

        double lowestBody;
        if (!MQLHelper::GetLowestBodyBetween(mSymbol, mTimeFrame, LowIndex(), barIndex, false, lowestBody))
        {
            return false;
        }

        return lowestBody < iLow(mSymbol, mTimeFrame, LowIndex());
    }
    else if (mType == OP_SELL)
    {
        // This is for wick breaks
        // double high;
        // if (!MQLHelper::GetHighestHighBetween(mSymbol, mTimeFrame, HighIndex(), barIndex, false, high))
        // {
        //     return false;
        // }

        // return high > iHigh(mSymbol, mTimeFrame, HighIndex());

        double highestBody;
        if (!MQLHelper::GetHighestBodyBetween(mSymbol, mTimeFrame, HighIndex(), barIndex, false, highestBody))
        {
            return false;
        }

        return highestBody > iHigh(mSymbol, mTimeFrame, HighIndex());
    }

    return false;
}

// this will return true if you are running on every tick and price wicks the end of the mb
bool MBState::GlobalStartIsBroken()
{
    if (!mGlobalStartIsBroken)
    {
        mGlobalStartIsBroken = StartIsBrokenFromBarIndex(0);
    }

    return mGlobalStartIsBroken;
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

bool MBState::HasImpulseValidation()
{
    double minPercentChange = 0.1;

    if (mHasImpulseValidation == Status::NOT_CHECKED)
    {
        // don't know if we have an imbalance yet
        if (EndIndex() < 2)
        {
            return false;
        }

        if (mType == OP_BUY)
        {
            // don't have an imbalance break, don't need to check anything else
            if (iHigh(mSymbol, mTimeFrame, EndIndex() + 1) > iLow(mSymbol, mTimeFrame, EndIndex() - 1))
            {
                mHasImpulseValidation = Status::IS_FALSE;
            }
            else
            {
                double percentChange = MathAbs((iOpen(Symbol(), Period(), EndIndex()) - iClose(Symbol(), Period(), EndIndex())) / iOpen(Symbol(), Period(), EndIndex()));
                if (percentChange > (minPercentChange / 100))
                {
                    mHasImpulseValidation = Status::IS_TRUE;
                    ObjectCreate(ChartID(), mName + "imp", OBJ_VLINE, 0, mEndDateTime, Ask);
                    ObjectSetInteger(ChartID(), mName + "imp", OBJPROP_COLOR, clrAqua);
                }
                else
                {
                    // go backwards checking for imbalances and adding percent change if true
                    for (int i = EndIndex() + 1; i < LowIndex(); i++)
                    {
                        // end of impulse chain
                        if (iHigh(mSymbol, mTimeFrame, i + 1) > iLow(mSymbol, mTimeFrame, i - 1) || iClose(mSymbol, mTimeFrame, i) < iOpen(mSymbol, mTimeFrame, i))
                        {
                            break;
                        }

                        percentChange += MathAbs((iOpen(Symbol(), Period(), i) - iClose(Symbol(), Period(), i)) / iOpen(Symbol(), Period(), i));
                    }

                    if (percentChange > (minPercentChange / 100))
                    {
                        mHasImpulseValidation = Status::IS_TRUE;
                        ObjectCreate(ChartID(), mName + "imp", OBJ_VLINE, 0, mEndDateTime, Ask);
                        ObjectSetInteger(ChartID(), mName + "imp", OBJPROP_COLOR, clrAqua);
                    }
                    else
                    {
                        // go forwards checking for imbalances and adding percent change if true
                        for (int i = EndIndex() - 1; i > 1; i--)
                        {
                            if (iHigh(mSymbol, mTimeFrame, i + 1) > iLow(mSymbol, mTimeFrame, i - 1) || iClose(mSymbol, mTimeFrame, i) < iOpen(mSymbol, mTimeFrame, i))
                            {
                                break;
                            }

                            percentChange += MathAbs((iOpen(Symbol(), Period(), i) - iClose(Symbol(), Period(), i)) / iOpen(Symbol(), Period(), i));
                        }

                        if (percentChange > (minPercentChange / 100))
                        {
                            mHasImpulseValidation = Status::IS_TRUE;
                            ObjectCreate(ChartID(), mName + "imp", OBJ_VLINE, 0, mEndDateTime, Ask);
                            ObjectSetInteger(ChartID(), mName + "imp", OBJPROP_COLOR, clrAqua);
                        }
                        else
                        {
                            mHasImpulseValidation = Status::IS_FALSE;
                        }
                    }
                }
            }
        }
        else if (mType == OP_SELL)
        {
            // don't have an imbalance break, don't need to check anything else
            if (iLow(mSymbol, mTimeFrame, EndIndex() + 1) < iHigh(mSymbol, mTimeFrame, EndIndex() - 1))
            {
                mHasImpulseValidation = Status::IS_FALSE;
            }
            else
            {
                double percentChange = MathAbs((iOpen(Symbol(), Period(), EndIndex()) - iClose(Symbol(), Period(), EndIndex())) / iOpen(Symbol(), Period(), EndIndex()));
                if (percentChange > (minPercentChange / 100))
                {
                    mHasImpulseValidation = Status::IS_TRUE;
                    ObjectCreate(ChartID(), mName + "imp", OBJ_VLINE, 0, mEndDateTime, Ask);
                    ObjectSetInteger(ChartID(), mName + "imp", OBJPROP_COLOR, clrAqua);
                }
                else
                {
                    // go backwards checking for imbalances and adding percent change if true
                    for (int i = EndIndex() + 1; i < LowIndex(); i++)
                    {
                        // end of impulse chain
                        if (iLow(mSymbol, mTimeFrame, i + 1) < iHigh(mSymbol, mTimeFrame, i - 1) || iClose(mSymbol, mTimeFrame, i) > iOpen(mSymbol, mTimeFrame, i))
                        {
                            break;
                        }

                        percentChange += MathAbs((iOpen(Symbol(), Period(), i) - iClose(Symbol(), Period(), i)) / iOpen(Symbol(), Period(), i));
                    }

                    if (percentChange > (minPercentChange / 100))
                    {
                        mHasImpulseValidation = Status::IS_TRUE;
                        ObjectCreate(ChartID(), mName + "imp", OBJ_VLINE, 0, mEndDateTime, Ask);
                        ObjectSetInteger(ChartID(), mName + "imp", OBJPROP_COLOR, clrAqua);
                    }
                    else
                    {
                        // go forwards checking for imbalances and adding percent change if true
                        for (int i = EndIndex() - 1; i > 1; i--)
                        {
                            if (iLow(mSymbol, mTimeFrame, i + 1) > iHigh(mSymbol, mTimeFrame, i - 1) || iClose(mSymbol, mTimeFrame, i) > iOpen(mSymbol, mTimeFrame, i))
                            {
                                break;
                            }

                            percentChange += MathAbs((iOpen(Symbol(), Period(), i) - iClose(Symbol(), Period(), i)) / iOpen(Symbol(), Period(), i));
                        }

                        if (percentChange > (minPercentChange / 100))
                        {
                            mHasImpulseValidation = Status::IS_TRUE;
                            ObjectCreate(ChartID(), mName + "imp", OBJ_VLINE, 0, mEndDateTime, Ask);
                            ObjectSetInteger(ChartID(), mName + "imp", OBJPROP_COLOR, clrAqua);
                        }
                        else
                        {
                            mHasImpulseValidation = Status::IS_FALSE;
                        }
                    }
                }
            }
        }
    }

    return mHasImpulseValidation == Status::IS_TRUE;
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
    // if (mType == OP_BUY)
    // {
    //     if (iHigh(mSymbol, mTimeFrame, EndIndex() + 1) < iLow(mSymbol, mTimeFrame, EndIndex() - 1))
    //     {
    //         clr = clrLimeGreen;
    //     }
    //     else
    //     {
    //         clr = clrBlack;
    //     }
    // }
    // else if (mType == OP_SELL)
    // {
    //     if (iLow(mSymbol, mTimeFrame, EndIndex() + 1) > iHigh(mSymbol, mTimeFrame, EndIndex() - 1))
    //     {
    //         clr = clrRed;
    //     }
    //     else
    //     {
    //         clr = clrBlack;
    //     }
    // }

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

    // double hlinePrice = 0.0;
    // if (mType == OP_BUY)
    // {
    //     hlinePrice = iHigh(mSymbol, mTimeFrame, HighIndex()) - ((iHigh(mSymbol, mTimeFrame, HighIndex()) - iLow(mSymbol, mTimeFrame, LowIndex())) * 0.3);
    //     ObjectCreate(0, "Threshold" + Number(), OBJ_RECTANGLE, 0,
    //                  mStartDateTime,
    //                  iHigh(mSymbol, mTimeFrame, HighIndex()),
    //                  mEndDateTime,
    //                  hlinePrice);
    //     ObjectSetInteger(0, "Threshold" + Number(), OBJPROP_FILL, true);
    // }
    // else if (mType == OP_SELL)
    // {
    //     hlinePrice = iHigh(mSymbol, mTimeFrame, HighIndex()) - ((iHigh(mSymbol, mTimeFrame, HighIndex()) - iLow(mSymbol, mTimeFrame, LowIndex())) * 0.7);
    //     ObjectCreate(0, "Threshold" + Number(), OBJ_RECTANGLE, 0,
    //                  mStartDateTime,
    //                  iLow(mSymbol, mTimeFrame, LowIndex()),
    //                  mEndDateTime,
    //                  hlinePrice);
    //     ObjectSetInteger(0, "Threshold" + Number(), OBJPROP_FILL, true);
    // }

    // ObjectSetInteger(0, "Threshold" + Number(), OBJPROP_COLOR, clr);

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
