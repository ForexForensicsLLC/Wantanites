//+------------------------------------------------------------------+
//|                                            TimeGridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\DateTimeHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class TimeGridTracker
{
private:
    string mObjectNamePrefix;

    int mBarsCalculated;
    int mLastDay;
    bool mDrawn;

    int mHourStart;
    int mMinuteStart;
    int mHourEnd;
    int mMinuteEnd;

    datetime mStartTime;
    datetime mEndTime;

    int mMaxLevels;
    double mLevelDistance;

    int mCurrentLevel;

    double mBasePrice;

    void Update();
    void Calculate(int barIndex);
    void Reset();

public:
    TimeGridTracker(int hourStart, int minuteStart, int hourEnd, int minuteEnd, int maxLevels, double levelPips);
    ~TimeGridTracker();

    int CurrentLevel();
    double LevelPrice(int level);
    void Draw();
};

TimeGridTracker::TimeGridTracker(int hourStart, int minuteStart, int hourEnd, int minuteEnd, int maxLevels, double levelPips)
{
    mObjectNamePrefix = "TimeGrid";

    mBarsCalculated = 0;
    mLastDay = Day();

    mHourStart = hourStart;
    mMinuteStart = minuteStart;
    mHourEnd = hourEnd;
    mMinuteEnd = minuteEnd;

    mMaxLevels = maxLevels;
    mLevelDistance = OrderHelper::PipsToRange(levelPips);

    Reset();
    Update();
}

TimeGridTracker::~TimeGridTracker()
{
    ObjectsDeleteAll(ChartID(), "TimeGridTracker");
}

int TimeGridTracker::CurrentLevel()
{
    Update();

    if (mBasePrice == 0.0)
    {
        Print("Base Price is 0.0");
        return 0;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        return 0;
    }

    double currentPlace = (currentTick.bid - mBasePrice) / mLevelDistance;
    if (currentPlace >= mCurrentLevel + 1)
    {
        mCurrentLevel += 1;
    }
    else if (currentPlace <= mCurrentLevel - 1)
    {
        mCurrentLevel -= 1;
    }

    if (mCurrentLevel > mMaxLevels)
    {
        return mMaxLevels;
    }
    else if (mCurrentLevel < -mMaxLevels)
    {
        return -mMaxLevels;
    }

    return mCurrentLevel;
}

double TimeGridTracker::LevelPrice(int level)
{
    Update();

    if (mBasePrice == 0.0)
    {
        Print("Base Price is 0.0");
        return 0.0;
    }

    return mBasePrice + (mLevelDistance * level);
}

void TimeGridTracker::Update()
{
    int totalBars = iBars(Symbol(), Period());
    int start = totalBars - mBarsCalculated;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void TimeGridTracker::Calculate(int barIndex)
{
    if (Day() != mLastDay)
    {
        Reset();
        mLastDay = Day();
    }

    if (mBasePrice == 0.0)
    {
        int startIndex = iBarShift(Symbol(), Period(), mStartTime);
        if (startIndex == 0)
        {
            mBasePrice = iOpen(Symbol(), Period(), 0);
        }
    }
}

void TimeGridTracker::Reset()
{
    mStartTime = DateTimeHelper::HourMinuteToDateTime(mHourStart, mMinuteStart);
    mEndTime = DateTimeHelper::HourMinuteToDateTime(mHourEnd, mMinuteEnd);

    mBasePrice = 0.0;
    mCurrentLevel = 0;

    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
    mDrawn = false;
}

void TimeGridTracker::Draw()
{
    if (mDrawn || mBasePrice == 0)
    {
        return;
    }

    double linePriceUpper = 0.0;
    double linePriceLower = 0.0;
    for (int i = 1; i <= mMaxLevels; i++)
    {
        linePriceUpper = mBasePrice + (mLevelDistance * i);
        linePriceLower = mBasePrice - (mLevelDistance * i);

        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(i), OBJ_TREND, 0, mStartTime, linePriceUpper, mEndTime, linePriceUpper);
        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(-i), OBJ_TREND, 0, mStartTime, linePriceLower, mEndTime, linePriceLower);
    }

    mDrawn = true;
}