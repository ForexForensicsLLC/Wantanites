//+------------------------------------------------------------------+
//|                                               TradingSession.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>

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

    string DisplayName() { return "TradingSession"; }

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

    int StartIndex(string symbol, ENUM_TIMEFRAMES timeFrame);

    bool CurrentlyWithinSession();
};

TradingSession::TradingSession()
{
    mTradeAllDay = true;

    AddHourMinuteSession(ConstantValues::EmptyInt, ConstantValues::EmptyInt, ConstantValues::EmptyInt, ConstantValues::EmptyInt);
    AddMonthDaySession(ConstantValues::EmptyInt, ConstantValues::EmptyInt, ConstantValues::EmptyInt, ConstantValues::EmptyInt);

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

int TradingSession::StartIndex(string symbol, ENUM_TIMEFRAMES timeFrame)
{
    datetime startTime = StringToTime(IntegerToString(HourStart()) + ":" + IntegerToString(MinuteStart()));
    return iBarShift(symbol, timeFrame, startTime);
}

bool TradingSession::CurrentlyWithinSession()
{
    if (mExcludedDays.Contains(DateTimeHelper::CurrentDayOfWeek()))
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
    if (mDayStart == ConstantValues::EmptyInt ||
        mMonthStart == ConstantValues::EmptyInt ||
        mExclusiveDayEnd == ConstantValues::EmptyInt ||
        mExclusiveMonthEnd == ConstantValues::EmptyInt)
    {
        return true;
    }

    int currentYear = DateTimeHelper::CurrentYear();
    datetime startTime = DateTimeHelper::DayMonthYearToDateTime(mDayStart, mMonthStart, currentYear);
    datetime endTime = 0;

    bool rolloverYear = (mExclusiveMonthEnd < mMonthStart) || (mMonthStart == mExclusiveMonthEnd && mExclusiveDayEnd < mDayStart);
    if (rolloverYear)
    {
        endTime = DateTimeHelper::DayMonthYearToDateTime(mExclusiveDayEnd, mExclusiveMonthEnd, currentYear + 1);
    }
    else
    {
        endTime = DateTimeHelper::DayMonthYearToDateTime(mExclusiveDayEnd, mExclusiveMonthEnd, currentYear);
    }

    return TimeCurrent() >= startTime && TimeCurrent() < endTime;
}

bool TradingSession::WithinHourMinute()
{
    // we don't care about hour / minute if any are empty
    if (mHourStart == ConstantValues::EmptyInt ||
        mMinuteStart == ConstantValues::EmptyInt ||
        mExclusiveHourEnd == ConstantValues::EmptyInt ||
        mExclusiveMinuteEnd == ConstantValues::EmptyInt)
    {
        return true;
    }

    int currentDay = DateTimeHelper::CurrentDay();
    datetime startTime = DateTimeHelper::HourMinuteToDateTime(mHourStart, mMinuteStart, currentDay);
    datetime endTime = DateTimeHelper::HourMinuteToDateTime(mExclusiveHourEnd, mExclusiveMinuteEnd, currentDay);

    bool rolloverDay = (mExclusiveHourEnd < mHourStart) || (mHourStart == mExclusiveHourEnd && mExclusiveMinuteEnd < mMinuteStart);
    if (rolloverDay)
    {
        // add one day in seconds
        endTime += (60 * 60 * 24);
    }

    return TimeCurrent() >= startTime && TimeCurrent() < endTime;
}