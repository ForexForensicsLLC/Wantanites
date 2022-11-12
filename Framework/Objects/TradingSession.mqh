//+------------------------------------------------------------------+
//|                                               TradingSession.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class TradingSession
{
private:
    int mHourStart;
    int mMinuteStart;
    int mInclusiveHourEnd;
    int mInclusiveMinuteEnd;

public:
    TradingSession(int hourStart, int minuteStart, int inclusiveHourEnd, int inclusiveMinuteEnd);
    TradingSession(TradingSession &ts);
    ~TradingSession();

    int HourStart() { return mHourStart; }
    int MinuteStart() { return mMinuteStart; }
    int InclusiveHourEnd() { return mInclusiveHourEnd; }
    int InclusiveMinuteEnd() { return mInclusiveMinuteEnd; }

    bool CurrentlyWithinSession();
};

TradingSession::TradingSession(int hourStart, int minuteStart, int inclusiveHourEnd, int inclusiveMinuteEnd)
{
    mHourStart = hourStart;
    mMinuteStart = minuteStart;
    mInclusiveHourEnd = inclusiveHourEnd;
    mInclusiveMinuteEnd = inclusiveMinuteEnd;
}

TradingSession::TradingSession(TradingSession &ts)
{
    mHourStart = ts.HourStart();
    mMinuteStart = ts.MinuteStart();
    mInclusiveHourEnd = ts.InclusiveHourEnd();
    mInclusiveMinuteEnd = ts.InclusiveMinuteEnd();
}

TradingSession::~TradingSession()
{
}

bool TradingSession::CurrentlyWithinSession()
{
    int currentTime = (Hour() * 59) + Minute();
    int startTime = (mHourStart * 59) + mMinuteStart;
    int endTime = (mInclusiveHourEnd * 59) + mInclusiveMinuteEnd;

    return currentTime >= startTime && currentTime <= endTime;
}