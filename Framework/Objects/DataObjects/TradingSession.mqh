//+------------------------------------------------------------------+
//|                                               TradingSession.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataStructures\List.mqh>

enum DayOfWeekEnum
{
    Sunday = 0,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday
};

class TradingSession
{
private:
    int mHourStart;
    int mMinuteStart;
    int mExclusiveHourEnd;
    int mExclusiveMinuteEnd;

    List<int> *mExcludedDays;

public:
    TradingSession(int hourStart, int minuteStart, int exclusiveHourEnd, int exclusiveMinuteEnd);
    TradingSession(TradingSession &ts);
    ~TradingSession();

    int HourStart() { return mHourStart; }
    int MinuteStart() { return mMinuteStart; }
    int ExclusiveHourEnd() { return mExclusiveHourEnd; }
    int ExclusiveMinuteEnd() { return mExclusiveMinuteEnd; }

    void ExcludeDay(DayOfWeekEnum day);

    int StartIndex(string symbol, int timeFrame);

    bool CurrentlyWithinSession();
};

TradingSession::TradingSession(int hourStart, int minuteStart, int exclusiveHourEnd, int exclusiveMinuteEnd)
{
    mHourStart = hourStart;
    mMinuteStart = minuteStart;
    mExclusiveHourEnd = exclusiveHourEnd;
    mExclusiveMinuteEnd = exclusiveMinuteEnd;

    mExcludedDays = new List<int>();
    mExcludedDays.Add(DayOfWeekEnum::Sunday);
    mExcludedDays.Add(DayOfWeekEnum::Saturday);
}

TradingSession::TradingSession(TradingSession &ts)
{
    mHourStart = ts.HourStart();
    mMinuteStart = ts.MinuteStart();
    mExclusiveHourEnd = ts.ExclusiveHourEnd();
    mExclusiveMinuteEnd = ts.ExclusiveMinuteEnd();

    mExcludedDays = new List<int>();
    for (int i = 0; i < ts.mExcludedDays.Size(); i++)
    {
        mExcludedDays.Add(ts.mExcludedDays[i]);
    }
}

TradingSession::~TradingSession()
{
    delete mExcludedDays;
}

void TradingSession::ExcludeDay(DayOfWeekEnum dayOfWeek)
{
    if (!mExcludedDays.Contains(dayOfWeek))
    {
        mExcludedDays.Add(dayOfWeek);
    }
}

int TradingSession::StartIndex(string symbol, int timeFrame)
{
    datetime startTime = StringToTime(HourStart() + ":" + MinuteStart());
    return iBarShift(symbol, timeFrame, startTime);
}

bool TradingSession::CurrentlyWithinSession()
{
    if (mExcludedDays.Contains(DayOfWeek()))
    {
        return false;
    }

    int currentTime = (Hour() * 59) + Minute();
    int startTime = (mHourStart * 59) + mMinuteStart;
    int endTime = (mExclusiveHourEnd * 59) + mExclusiveMinuteEnd;

    return currentTime >= startTime && currentTime < endTime;
}