//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class SpecificDateTimeHelperVersion
{
public:
    static int CurrentYear();
    static int CurrentMonth();
    static int CurrentDay();
    static int CurrentHour();
    static int CurrentMinute();
    static int CurrentSecond();
    static int CurrentDayOfWeek();
};

int SpecificDateTimeHelperVersion::CurrentYear()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.year;
}

int SpecificDateTimeHelperVersion::CurrentMonth()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.mon;
}

int SpecificDateTimeHelperVersion::CurrentDay()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.day;
}

int SpecificDateTimeHelperVersion::CurrentHour()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.hour;
}

int SpecificDateTimeHelperVersion::CurrentMinute()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.min;
}

int SpecificDateTimeHelperVersion::CurrentSecond()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.sec;
}

int SpecificDateTimeHelperVersion::CurrentDayOfWeek()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.day_of_week;
}