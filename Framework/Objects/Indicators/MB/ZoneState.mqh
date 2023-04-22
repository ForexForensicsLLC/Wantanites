//+------------------------------------------------------------------+
//|                                                    ZoneState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\CandleStickHelper.mqh>
#include <Wantanites\Framework\Objects\Indicators\MB\Types.mqh>
#include <Wantanites\Framework\Types\SignalTypes.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\MQLHelper\MQLHelper.mqh>

class ZoneState
{
protected:
    bool mIsPending;
    string mSymbol;
    ENUM_TIMEFRAMES mTimeFrame;

    int mMBNumber;
    int mNumber;
    SignalType mType;
    string mDescription;

    double mHeight;

    datetime mStartDateTime;
    datetime mEndDateTime;

    double mEntryPrice;
    double mExitPrice;

    int mEntryOffset;

    CandlePart mBrokenBy;
    bool mDrawn;
    string mName;
    color mZoneColor;

public:
    // --- Getters ---
    string DisplayName() { return "Zone"; }
    string Symbol() { return mSymbol; }
    ENUM_TIMEFRAMES TimeFrame() { return mTimeFrame; }

    int Number() { return mNumber; }
    int MBNumber() { return mMBNumber; }
    SignalType Type() { return mType; }
    string Description() { return mDescription; }

    int StartIndex() { return iBarShift(mSymbol, mTimeFrame, mStartDateTime); }
    int EndIndex() { return iBarShift(mSymbol, mTimeFrame, mEndDateTime); }

    double EntryPrice() { return mEntryPrice; }
    double ExitPrice() { return mExitPrice; }

    int EntryOffset() { return mEntryOffset; }

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
        mHeight = NormalizeDouble(MathAbs(EntryPrice() - ExitPrice()), Digits());
    }

    return mHeight;
}

double ZoneState::PercentOfZonePrice(double percent)
{
    if (Type() == SignalType::Bullish)
    {
        return EntryPrice() - (Height() * percent);
    }
    else if (Type() == SignalType::Bearish)
    {
        return EntryPrice() + (Height() * percent);
    }

    return 0.0;
}

bool ZoneState::CandleIsInZone(int index)
{
    if (Type() == SignalType::Bullish)
    {
        return iLow(Symbol(), TimeFrame(), index) <= EntryPrice() && !BelowDemandZone(index);
    }
    else if (Type() == SignalType::Bearish)
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
    if (mType == SignalType::Bullish)
    {
        double low;
        if (!MQLHelper::GetLowestLow(mSymbol, mTimeFrame, barIndex, 0, false, low))
        {
            return false;
        }

        return low <= mEntryPrice && !IsBroken();
    }
    else if (mType == SignalType::Bearish)
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
    if (mType == SignalType::Bullish)
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
    else if (mType == SignalType::Bearish)
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

    if (!ObjectCreate(ChartID(), mName, OBJ_RECTANGLE, 0,
                      mStartDateTime, // Start
                      mEntryPrice,    // Entry
                      mEndDateTime,   // End
                      mExitPrice))    // Exit
    {
        Print("Zone Object Creation Failed: ", GetLastError());
        return;
    }

    ObjectSetInteger(ChartID(), mName, OBJPROP_COLOR, mZoneColor);
    ObjectSetInteger(ChartID(), mName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(ChartID(), mName, OBJPROP_BACK, false);
    ObjectSetInteger(ChartID(), mName, OBJPROP_FILL, !mIsPending);
    ObjectSetInteger(ChartID(), mName, OBJPROP_SELECTED, false);
    ObjectSetInteger(ChartID(), mName, OBJPROP_SELECTABLE, false);

    if (mIsPending)
    {
        ObjectSetInteger(ChartID(), mName, OBJPROP_STYLE, STYLE_DOT);
    }

    mDrawn = true;
}