//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class DateTimeHelper
{
public:
    static datetime HourMinuteToDateTime(int hour, int minute, int day);
    static datetime DayMonthYearToDateTime(int day, int month, int year);

    static string FormatAsTwoDigits(int value);
};

datetime DateTimeHelper::HourMinuteToDateTime(int hour, int minute, int day)
{
    string timeString = Year() + "." + Month() + "." + day + " " + IntegerToString(hour) + ":" + IntegerToString(minute);
    return StringToTime(timeString);
}

datetime DateTimeHelper::DayMonthYearToDateTime(int day, int month, int year)
{
    string dateString = IntegerToString(year) + "." + IntegerToString(month) + "." + IntegerToString(day);
    return StringToTime(dateString);
}

string DateTimeHelper::FormatAsTwoDigits(int value)
{
    if (value >= 10)
    {
        return IntegerToString(TimeMonth(date));
    }
    else
    {
        return "0" + IntegerToString(TimeMonth(date));
    }

    return "";
}