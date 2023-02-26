//+------------------------------------------------------------------+
//|                                            DateRangeBreakout.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Constants\ConstantValues.mqh>
#include <WantaCapital\Framework\Helpers\DateTimeHelper.mqh>

class DateRangeBreakout
{
private:
    string mObjectNamePrefix;

    int mBarsCalculated;
    bool mWasReset;

    int mRangeDayStart;
    int mRangeMonthStart;
    int mRangeYearStart;

    int mRangeDayEnd;
    int mRangeMonthEnd;
    int mRangeYearEnd;

    datetime mRangeStartDateTime;
    datetime mRangeEndDateTime;

    bool mUpdateRangeStart;
    bool mUpdateRangeEnd;

    double mRangeHigh;
    double mRangeLow;

    bool mUpdateRangeHigh;
    bool mUpdateRangeLow;

    datetime mBrokeRangeHighDateTime;
    datetime mBrokeRangeLowDateTime;

    void Update();
    void Calculate(int barIndex);

    void Reset();

public:
    DateRangeBreakout(int rangeMonthStart, int rangeDayStart, int rangeYearStart, int rangeMonthEnd, int rangeDayEnd, int rangeYearEnd);
    ~DateRangeBreakout();

    datetime RangeStartTime() { return mRangeStartDateTime; }
    datetime RangeEndTime() { return mRangeEndDateTime; }

    double RangeHigh();
    double RangeLow();
    double RangeHeight() { return RangeHigh() - RangeLow(); }

    bool MostRecentCandleBrokeRangeHigh();
    bool MostRecentCandleBrokeRangeLow();

    void Draw();
    void IncrementYearAndReset();
};

DateRangeBreakout::DateRangeBreakout(int rangeMonthStart, int rangeDayStart, int rangeYearStart, int rangeMonthEnd, int rangeDayEnd, int rangeYearEnd)
{
    mObjectNamePrefix = "DateRangeBreakout";

    mBarsCalculated = 0;
    mWasReset = true;

    mRangeDayStart = rangeDayStart;
    mRangeMonthStart = rangeMonthStart;
    mRangeYearStart = rangeYearStart;

    mRangeDayEnd = rangeDayEnd;
    mRangeMonthEnd = rangeMonthEnd;
    mRangeYearEnd = rangeYearEnd;

    Reset();
    Update();
}

DateRangeBreakout::~DateRangeBreakout()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

double DateRangeBreakout::RangeHigh()
{
    Update();
    return mRangeHigh;
}

double DateRangeBreakout::RangeLow()
{
    Update();
    return mRangeLow;
}

bool DateRangeBreakout::MostRecentCandleBrokeRangeHigh()
{
    Update();

    if (mBrokeRangeHighDateTime <= 0)
    {
        return false;
    }

    return iBarShift(Symbol(), Period(), mBrokeRangeHighDateTime) == 0;
}

bool DateRangeBreakout::MostRecentCandleBrokeRangeLow()
{
    Update();

    if (mBrokeRangeLowDateTime <= 0)
    {
        return false;
    }

    return iBarShift(Symbol(), Period(), mBrokeRangeLowDateTime) == 0;
}

void DateRangeBreakout::Update()
{
    int totalBars = iBars(Symbol(), Period());
    int start = totalBars - mBarsCalculated;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void DateRangeBreakout::Calculate(int barIndex)
{
    datetime barTime = iTime(Symbol(), Period(), barIndex);
    if (barTime > mRangeStartDateTime && barTime < mRangeEndDateTime)
    {
        mWasReset = false;
        if (iHigh(Symbol(), Period(), barIndex) > mRangeHigh || mRangeHigh == ConstantValues::EmptyDouble)
        {
            mRangeHigh = iHigh(Symbol(), Period(), barIndex);
            mUpdateRangeHigh = true;
        }

        if (iLow(Symbol(), Period(), barIndex) < mRangeLow || mRangeLow == ConstantValues::EmptyDouble)
        {
            mRangeLow = iLow(Symbol(), Period(), barIndex);
            mUpdateRangeLow = true;
        }
    }
    else
    {
        if (mRangeHigh != ConstantValues::EmptyDouble && mRangeLow != ConstantValues::EmptyDouble)
        {
            MqlTick currentTick;
            if (!SymbolInfoTick(Symbol(), currentTick))
            {
                return;
            }

            double thisValue = barIndex == 0 ? currentTick.bid : iClose(Symbol(), Period(), barIndex);
            if (mBrokeRangeHighDateTime <= 0)
            {
                if (iClose(Symbol(), Period(), barIndex + 1) < mRangeHigh && thisValue >= mRangeHigh)
                {
                    mBrokeRangeHighDateTime = iTime(Symbol(), Period(), barIndex);
                }
            }

            if (mBrokeRangeLowDateTime <= 0)
            {
                if (iClose(Symbol(), Period(), barIndex + 1) > mRangeLow && thisValue <= mRangeLow)
                {
                    mBrokeRangeLowDateTime = iTime(Symbol(), Period(), barIndex);
                }
            }
        }
    }
}

void DateRangeBreakout::Reset()
{
    mRangeStartDateTime = DateTimeHelper::DayMonthYearToDateTime(mRangeDayStart, mRangeMonthStart, mRangeYearStart);
    mRangeEndDateTime = DateTimeHelper::DayMonthYearToDateTime(mRangeDayEnd, mRangeMonthEnd, mRangeYearEnd);

    Print("After Start Time: ", mRangeStartDateTime, ", End Time: ", mRangeEndDateTime);

    mUpdateRangeStart = true;
    mUpdateRangeEnd = true;

    mRangeHigh = ConstantValues::EmptyDouble;
    mRangeLow = ConstantValues::EmptyDouble;

    mUpdateRangeHigh = false;
    mUpdateRangeLow = false;

    mBrokeRangeHighDateTime = 0;
    mBrokeRangeLowDateTime = 0;
}

void DateRangeBreakout::IncrementYearAndReset()
{
    Print("Before Start Time: ", mRangeStartDateTime, ", End Time: ", mRangeEndDateTime);

    mRangeYearStart += 1;
    mRangeYearEnd += 1;

    Reset();
}

void DateRangeBreakout::Draw()
{
    Update();

    if (mUpdateRangeStart)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_start");

        ObjectCreate(NULL, mObjectNamePrefix + "_start", OBJ_VLINE, 0, mRangeStartDateTime, 0);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_start", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_start", OBJPROP_WIDTH, 2);

        mUpdateRangeStart = false;
    }

    if (mUpdateRangeEnd)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_end");

        ObjectCreate(NULL, mObjectNamePrefix + "_end", OBJ_VLINE, 0, mRangeEndDateTime, 0);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_end", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_end", OBJPROP_WIDTH, 2);

        mUpdateRangeEnd = false;
    }

    if (mRangeHigh > 0 && mUpdateRangeHigh)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_high");

        ObjectCreate(NULL, mObjectNamePrefix + "_high", OBJ_TREND, 0, mRangeStartDateTime, mRangeHigh, mRangeEndDateTime, mRangeHigh);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_high", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_high", OBJPROP_WIDTH, 2);

        mUpdateRangeHigh = false;
    }

    if (mRangeLow > 0 && mUpdateRangeLow)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_low");

        ObjectCreate(NULL, mObjectNamePrefix + "_low", OBJ_TREND, 0, mRangeStartDateTime, mRangeLow, mRangeEndDateTime, mRangeLow);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_low", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_low", OBJPROP_WIDTH, 2);

        mUpdateRangeLow = false;
    }
}