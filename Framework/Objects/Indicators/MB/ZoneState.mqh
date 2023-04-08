//+------------------------------------------------------------------+
//|                                                    ZoneState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\Indicators\MB\Types.mqh>
#include <Wantanites\Framework\Helpers\MQLHelper.mqh>
#include <Wantanites\Framework\Helpers\CandleStickHelper.mqh>

class ZoneState
{
protected:
    string mSymbol;
    int mTimeFrame;

    int mMBNumber;
    int mNumber;
    int mType;
    string mDescription;

    double mHeight;

    datetime mStartDateTime;
    datetime mEndDateTime;

    double mEntryPrice;
    double mExitPrice;

    int mEntryOffset;

    CandlePart mBrokenBy;
    // bool mAllowWickBreaks;
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

    int StartIndex() { return iBarShift(mSymbol, mTimeFrame, mStartDateTime); }
    int EndIndex() { return iBarShift(mSymbol, mTimeFrame, mEndDateTime); }

    double EntryPrice() { return mEntryPrice; }
    double ExitPrice() { return mExitPrice; }

    int EntryOffset() { return mEntryOffset; }
    bool WasRetrieved() { return mWasRetrieved; }

    double Height();
    double PercentOfZonePrice(double percent);

    bool CandleIsInZone(int index);

    // --- Computed Properties ---
    double Range() { return MathAbs(mEntryPrice - mExitPrice); }

    bool mFurthestPointWasSet;
    double mLowestConfirmationMBLowWithin;
    double mHighestConfirmationMBHighWithin;

    bool IsHolding(int barIndex);
    bool IsHoldingFromStart();
    bool IsBroken();
    bool BelowDemandZone(int barIndex);
    bool AboveSupplyZone(int barIndex);

    // --- Display Methods ---
    string ToString();
    string ToSingleLineString();
    void Draw();
};

double ZoneState::Height()
{
    if (mHeight == 0.0)
    {
        mHeight = NormalizeDouble(MathAbs(EntryPrice() - ExitPrice()), Digits);
    }

    return mHeight;
}

double ZoneState::PercentOfZonePrice(double percent)
{
    if (Type() == OP_BUY)
    {
        return EntryPrice() - (Height() * percent);
    }
    else if (Type() == OP_SELL)
    {
        return EntryPrice() + (Height() * percent);
    }

    return 0.0;
}

bool ZoneState::CandleIsInZone(int index)
{
    if (Type() == OP_BUY)
    {
        return iLow(Symbol(), TimeFrame(), index) <= EntryPrice() && !BelowDemandZone(index);
    }
    else if (Type() == OP_SELL)
    {
        return iHigh(Symbol(), TimeFrame(), index) >= EntryPrice() && !AboveSupplyZone(index);
    }

    return false;
}

/// @brief This will return true if you are caclculating on every tick and a wick breaks below the zone
bool ZoneState::BelowDemandZone(int barIndex)
{
    return (mBrokenBy == CandlePart::Body && CandleStickHelper::LowestBodyPart(mSymbol, mTimeFrame, barIndex) < mExitPrice) ||
           (mBrokenBy == CandlePart::Wick && iLow(mSymbol, mTimeFrame, barIndex) < mExitPrice);
}

/// @brief This will return true if you are caclculating on every tick and a wick breaks above the zone
bool ZoneState::AboveSupplyZone(int barIndex)
{
    return (mBrokenBy == CandlePart::Body && CandleStickHelper::HighestBodyPart(mSymbol, mTimeFrame, barIndex) > mExitPrice) ||
           (mBrokenBy == CandlePart::Wick && iHigh(mSymbol, mTimeFrame, barIndex) > mExitPrice);
}

// ----------------- Computed Properties ----------------------
// checks if price is or was  in the zone from the barIndex, and the zone hasn't been broken
bool ZoneState::IsHolding(int barIndex)
{
    if (mType == OP_BUY)
    {
        double low;
        if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, barIndex, 0, false, low))
        {
            return false;
        }

        return low <= mEntryPrice && !IsBroken();
    }
    else if (mType == OP_SELL)
    {
        double high;
        if (!MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, barIndex, 0, false, high))
        {
            return false;
        }

        return high >= mEntryPrice && !IsBroken();
    }

    return false;
}

bool ZoneState::IsHoldingFromStart()
{
    return IsHolding(StartIndex() - EntryOffset());
}

// checks if a zone was broken from its entry index to the current bar
bool ZoneState::IsBroken()
{
    double price = 0.0;
    if (mType == OP_BUY)
    {
        if (mBrokenBy == CandlePart::Body)
        {
            if (!MQLHelper::GetLowestBodyBetween(Symbol(), TimeFrame(), StartIndex(), 0, false, price))
            {
                return false;
            }
        }
        else if (mBrokenBy == CandlePart::Wick)
        {
            if (!MQLHelper::GetLowestLowBetween(Symbol(), TimeFrame(), StartIndex(), 0, false, price))
            {
                return false;
            }
        }

        return price <= ExitPrice();
    }
    else if (mType == OP_SELL)
    {
        if (mBrokenBy == CandlePart::Body)
        {
            if (!MQLHelper::GetHighestBodyBetween(Symbol(), TimeFrame(), StartIndex(), 0, false, price))
            {
                return false;
            }
        }
        else if (mBrokenBy == CandlePart::Wick)
        {
            if (!MQLHelper::GetHighestHighBetween(Symbol(), TimeFrame(), StartIndex(), 0, false, price))
            {
                return false;
            }
        }

        return price >= ExitPrice();
    }

    return false;
}

// ------------------- Display Methods ---------------------
// returns a string description about the zone
string ZoneState::ToString()
{
    return "Zone - TF: " + IntegerToString(mTimeFrame) +
           ", Entry: " + IntegerToString(StartIndex()) +
           ", Exit: " + IntegerToString(EndIndex());
}

string ZoneState::ToSingleLineString()
{
    double lowestAfter;
    double highestAfter;

    MQLHelper::GetLowestLow(mSymbol, mTimeFrame, StartIndex() - 1, 0, false, lowestAfter);
    MQLHelper::GetHighestHigh(mSymbol, mTimeFrame, StartIndex() - 1, 0, false, highestAfter);

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
void ZoneState::Draw()
{
    if (mDrawn)
    {
        return;
    }

    color clr = mType == OP_BUY ? clrGold : clrMediumVioletRed;

    if (!ObjectCreate(0, mName, OBJ_RECTANGLE, 0,
                      mStartDateTime, // Start
                      mEntryPrice,    // Entry
                      mEndDateTime,   // End
                      mExitPrice))    // Exit
    {
        Print("Zone Object Creation Failed: ", GetLastError());
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