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
    bool mTradeAllDay;

    int mHourStart;
    int mMinuteStart;
    int mDayStart;
    int mMonthStart;

    int mExclusiveHourEnd;
    int mExclusiveMinuteEnd;
    int mExclusiveDayEnd;
    int mExclusiveMonthEnd;

    List<int> *mExcludedDays;

    bool WithinDayMonthYear();
    bool WithinHourMinute();

public:
    TradingSession();
    TradingSession(TradingSession &ts);
    ~TradingSession();

    void AddMonthDaySession(int monthStart, int dayStart, int exclusiveMonthEnd, int exclusiveDayEnd);
    void AddHourMinuteSession(int hourStart, int minuteStart, int exclusiveHourEnd, int exclusiveMinuteEnd);

    int TradeAllDay() { return mTradeAllDay; }

    int HourStart() { return mHourStart; }
    int MinuteStart() { return mMinuteStart; }
    int DayStart() { return mDayStart; }
    int MonthStart() { return mMonthStart; }

    int ExclusiveHourEnd() { return mExclusiveHourEnd; }
    int ExclusiveMinuteEnd() { return mExclusiveMinuteEnd; }
    int ExclusiveDayEnd() { return mExclusiveDayEnd; }
    int ExclusiveMonthEnd() { return mExclusiveMonthEnd; }

    void ExcludeDay(DayOfWeekEnum day);

    int StartIndex(string symbol, int timeFrame);

    bool CurrentlyWithinSession();
};

TradingSession::TradingSession()
{
    mTradeAllDay = true;

    AddHourMinuteSession(EMPTY, EMPTY, EMPTY, EMPTY);
    AddMonthDaySession(EMPTY, EMPTY, EMPTY, EMPTY);

    mExcludedDays = new List<int>();
    mExcludedDays.Add(DayOfWeekEnum::Sunday);
    mExcludedDays.Add(DayOfWeekEnum::Saturday);
}

TradingSession::TradingSession(TradingSession &ts)
{
    mTradeAllDay = ts.TradeAllDay();

    mHourStart = ts.HourStart();
    mMinuteStart = ts.MinuteStart();
    mDayStart = ts.DayStart();
    mMonthStart = ts.MonthStart();

    mExclusiveHourEnd = ts.ExclusiveHourEnd();
    mExclusiveMinuteEnd = ts.ExclusiveMinuteEnd();
    mExclusiveDayEnd = ts.ExclusiveDayEnd();
    mExclusiveMonthEnd = ts.ExclusiveMonthEnd();

    mExcludedDays = new List<int>();
    for (int i = 0; i < ts.mExcludedDays.Size(); i++)
    {
        mExcludedDays.Add(ts.mExcludedDays[i]);
    }
}

void TradingSession::AddMonthDaySession(int monthStart, int dayStart, int exclusiveMonthEnd, int exclusiveDayEnd)
{
    mTradeAllDay = false;

    mDayStart = dayStart;
    mMonthStart = monthStart;

    mExclusiveDayEnd = exclusiveDayEnd;
    mExclusiveMonthEnd = exclusiveMonthEnd;
}

void TradingSession::AddHourMinuteSession(int hourStart, int minuteStart, int exclusiveHourEnd, int exclusiveMinuteEnd)
{
    mTradeAllDay = false;

    mHourStart = hourStart;
    mMinuteStart = minuteStart;

    mExclusiveHourEnd = exclusiveHourEnd;
    mExclusiveMinuteEnd = exclusiveMinuteEnd;
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

    if (mTradeAllDay)
    {
        return true;
    }

    return WithinDayMonthYear() && WithinHourMinute();
}

bool TradingSession::WithinDayMonthYear()
{
    // we don't care about day / month if any are empty
    if (mDayStart == EMPTY || mMonthStart == EMPTY || mExclusiveDayEnd == EMPTY || mExclusiveMonthEnd == EMPTY)
    {
        return true;
    }

    datetime startTime = DateTimeHelper::DayMonthYearToDateTime(mDayStart, mMonthStart, Year());
    datetime endTime = 0;

    bool rolloverYear = (mExclusiveMonthEnd < mMonthStart) || (mMonthStart == mExclusiveMonthEnd && mExclusiveDayEnd < mDayStart);
    if (rolloverYear)
    {
        endTime = DateTimeHelper::DayMonthYearToDateTime(mExclusiveDayEnd, mExclusiveMonthEnd, Year() + 1);
    }
    else
    {
        endTime = DateTimeHelper::DayMonthYearToDateTime(mExclusiveDayEnd, mExclusiveMonthEnd, Year());
    }

    return TimeCurrent() >= startTime && TimeCurrent() < endTime;
}

bool TradingSession::WithinHourMinute()
{
    // we don't care about hour / minute if any are empty
    if (mHourStart == EMPTY || mMinuteStart == EMPTY || mExclusiveHourEnd == EMPTY || mExclusiveMinuteEnd == EMPTY)
    {
        return true;
    }

    // int currentTime = (Hour() * 59) + Minute();
    // int startTime = (mHourStart * 59) + mMinuteStart;
    // int endTime = (mExclusiveHourEnd * 59) + mExclusiveMinuteEnd;

    // return currentTime >= startTime && currentTime < endTime;

    datetime startTime = DateTimeHelper::HourMinuteToDateTime(mHourStart, mMinuteStart, Day());
    datetime endTime = DateTimeHelper::HourMinuteToDateTime(mExclusiveHourEnd, mExclusiveMinuteEnd, Day());

    bool rolloverDay = (mExclusiveHourEnd < mHourStart) || (mHourStart == mExclusiveHourEnd && mExclusiveMinuteEnd < mMinuteStart);
    if (rolloverDay)
    {
        // add one day in seconds
        endTime += (60 * 60 * 24);
    }

    return TimeCurrent() >= startTime && TimeCurrent() < endTime;
}