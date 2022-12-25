//+------------------------------------------------------------------+
//|                                            TimeRangeBreakout.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\ConstantValues.mqh>
#include <SummitCapital\Framework\Helpers\DateTimeHelper.mqh>

class TimeRangeBreakout
{
private:
    string mObjectNamePrefix;

    int mBarsCalculated;
    int mLastDay;

    int mRangeHourStartTime;
    int mRangeMinuteStartTime;
    int mRangeHourEndTime;
    int mRangeMinuteEndTime;

    datetime mRangeStartTime;
    datetime mRangeEndTime;

    bool mUpdateRangeStart;
    bool mUpdateRangeEnd;

    double mRangeHigh;
    double mRangeLow;

    bool mUpdateRangeHigh;
    bool mUpdateRangeLow;

    bool mBrokeRangeHigh;
    bool mBrokeRangeLow;

    void Update();
    void Calculate(int barIndex);
    void Reset();

public:
    TimeRangeBreakout(int rangeHourStartTime, int rangeMinuteStartTime, int rangeHourEndTime, int rangeMinuteEndTime);
    ~TimeRangeBreakout();

    double RangeHigh();
    double RangeLow();
    double RangeWidth() { return RangeHigh() - RangeLow(); }

    bool BrokeRangeHigh();
    bool BrokeRangeLow();

    void Draw();
};

TimeRangeBreakout::TimeRangeBreakout(int rangeHourStartTime, int rangeMinuteStartTime, int rangeHourEndTime, int rangeMinuteEndTime)
{
    mObjectNamePrefix = "TimeRangeBreakout";

    mBarsCalculated = 0;
    mLastDay = Day();

    mRangeHourStartTime = rangeHourStartTime;
    mRangeMinuteStartTime = rangeMinuteStartTime;
    mRangeHourEndTime = rangeHourEndTime;
    mRangeMinuteEndTime = rangeMinuteEndTime;

    Reset();
    Update();
}

TimeRangeBreakout::~TimeRangeBreakout()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

double TimeRangeBreakout::RangeHigh()
{
    Update();
    return mRangeHigh;
}

double TimeRangeBreakout::RangeLow()
{
    Update();
    return mRangeLow;
}

bool TimeRangeBreakout::BrokeRangeHigh()
{
    Update();

    if (!mBrokeRangeHigh)
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            return false;
        }

        mBrokeRangeHigh = currentTick.time > mRangeEndTime && mRangeHigh != ConstantValues::EmptyDouble && currentTick.ask > mRangeHigh;
    }

    return mBrokeRangeHigh;
}

bool TimeRangeBreakout::BrokeRangeLow()
{
    Update();

    if (!mBrokeRangeLow)
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            return false;
        }

        mBrokeRangeLow = currentTick.time > mRangeStartTime && mRangeLow != ConstantValues::EmptyDouble && currentTick.bid < mRangeLow;
    }

    return mBrokeRangeLow;
}

void TimeRangeBreakout::Update()
{
    int totalBars = iBars(Symbol(), Period());
    int start = totalBars - mBarsCalculated;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void TimeRangeBreakout::Calculate(int barIndex)
{
    if (Day() != mLastDay)
    {
        Reset();
        mLastDay = Day();
    }

    datetime validTime = 0;
    if (barIndex == 0)
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            return;
        }

        validTime = currentTick.time;
    }
    else
    {
        validTime = iTime(Symbol(), Period(), barIndex);
    }

    if (validTime > mRangeStartTime && validTime < mRangeEndTime)
    {
        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            return;
        }

        if (currentTick.ask > mRangeHigh || mRangeHigh == ConstantValues::EmptyDouble)
        {
            mRangeHigh = currentTick.ask;
            mUpdateRangeHigh = true;
        }

        if (currentTick.bid < mRangeLow || mRangeLow == ConstantValues::EmptyDouble)
        {
            mRangeLow = currentTick.bid;
            mUpdateRangeLow = true;
        }
    }
}

void TimeRangeBreakout::Reset()
{
    mRangeStartTime = DateTimeHelper::HourMinuteToDateTime(mRangeHourStartTime, mRangeMinuteStartTime);
    mRangeEndTime = DateTimeHelper::HourMinuteToDateTime(mRangeHourEndTime, mRangeMinuteEndTime);

    mUpdateRangeStart = true;
    mUpdateRangeEnd = true;

    mRangeHigh = ConstantValues::EmptyDouble;
    mRangeLow = ConstantValues::EmptyDouble;

    mUpdateRangeHigh = false;
    mUpdateRangeLow = false;

    mBrokeRangeHigh = false;
    mBrokeRangeLow = false;
}

void TimeRangeBreakout::Draw()
{
    Update();

    if (mUpdateRangeStart)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_start");

        ObjectCreate(NULL, mObjectNamePrefix + "_start", OBJ_VLINE, 0, mRangeStartTime, 0);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_start", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_start", OBJPROP_WIDTH, 2);

        mUpdateRangeStart = false;
    }

    if (mUpdateRangeEnd)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_end");

        ObjectCreate(NULL, mObjectNamePrefix + "_end", OBJ_VLINE, 0, mRangeEndTime, 0);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_end", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_end", OBJPROP_WIDTH, 2);

        mUpdateRangeEnd = false;
    }

    if (mRangeHigh > 0 && mUpdateRangeHigh)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_high");

        ObjectCreate(NULL, mObjectNamePrefix + "_high", OBJ_TREND, 0, mRangeStartTime, mRangeHigh, mRangeEndTime, mRangeHigh);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_high", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_high", OBJPROP_WIDTH, 2);

        mUpdateRangeHigh = false;
    }

    if (mRangeLow > 0 && mUpdateRangeLow)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_low");

        ObjectCreate(NULL, mObjectNamePrefix + "_low", OBJ_TREND, 0, mRangeStartTime, mRangeLow, mRangeEndTime, mRangeLow);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_low", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_low", OBJPROP_WIDTH, 2);

        mUpdateRangeLow = false;
    }
}