//+------------------------------------------------------------------+
//|                                            TimeGridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\GridTracker.mqh>

#include <WantaCapital\Framework\Helpers\DateTimeHelper.mqh>
#include <WantaCapital\Framework\Helpers\OrderHelper.mqh>

class TimeGridTracker : public GridTracker
{
private:
    int mBarsCalculated;
    int mLastDay;

    int mHourStart;
    int mMinuteStart;
    int mHourEnd;
    int mMinuteEnd;

    datetime mStartTime;
    datetime mEndTime;

    void Update();
    void Calculate(int barIndex);

public:
    TimeGridTracker(int hourStart, int minuteStart, int hourEnd, int minuteEnd, int maxLevel, double levelPips);
    ~TimeGridTracker();

    virtual double BasePrice();
    virtual double LevelPrice(int level);
    virtual int CurrentLevel();
    virtual bool AtMaxLevel();
    virtual void Reset();
};

TimeGridTracker::TimeGridTracker(int hourStart, int minuteStart, int hourEnd, int minuteEnd, int maxLevel, double levelPips) : GridTracker(maxLevel, levelPips)
{
    mObjectNamePrefix = "TimeGrid";

    mBarsCalculated = 0;
    mLastDay = Day();

    mHourStart = hourStart;
    mMinuteStart = minuteStart;
    mHourEnd = hourEnd;
    mMinuteEnd = minuteEnd;

    Reset();
    Update();
}

TimeGridTracker::~TimeGridTracker()
{
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
        datetime currentTime = iTime(Symbol(), Period(), 0);

        // do this instead of checking if the indx of our mStarTime == 0 since that returns true for all values before the starting time
        if (TimeHour(mStartTime) == TimeHour(currentTime) && TimeMinute(mStartTime) == TimeMinute(currentTime))
        {
            mBasePrice = iOpen(Symbol(), Period(), 0);
        }
    }
}

double TimeGridTracker::BasePrice()
{
    Update();
    return GridTracker::BasePrice();
}

double TimeGridTracker::LevelPrice(int level)
{
    Update();
    return GridTracker::LevelPrice(level);
}

int TimeGridTracker::CurrentLevel()
{
    Update();
    return GridTracker::CurrentLevel();
}

bool TimeGridTracker::AtMaxLevel()
{
    Update();
    return GridTracker::AtMaxLevel();
}

void TimeGridTracker::Reset()
{
    mStartTime = DateTimeHelper::HourMinuteToDateTime(mHourStart, mMinuteStart);
    mEndTime = DateTimeHelper::HourMinuteToDateTime(mHourEnd, mMinuteEnd);

    GridTracker::Reset();
}