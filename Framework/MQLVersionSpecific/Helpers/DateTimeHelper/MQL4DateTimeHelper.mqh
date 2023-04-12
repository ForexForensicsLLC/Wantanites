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
    return Year();
}

int SpecificDateTimeHelperVersion::CurrentMonth()
{
    return Month();
}

int SpecificDateTimeHelperVersion::CurrentDay()
{
    return Day();
}

int SpecificDateTimeHelperVersion::CurrentHour()
{
    return Hour();
}

int SpecificDateTimeHelperVersion::CurrentMinute()
{
    return Minute();
}

int SpecificDateTimeHelperVersion::CurrentSecond()
{
    return Seconds();
}

int SpecificDateTimeHelperVersion::CurrentDayOfWeek()
{
    return DayOfWeek();
}