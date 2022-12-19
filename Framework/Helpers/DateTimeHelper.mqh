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
    static datetime HourMinuteToDateTime(int hour, int minute);
};

datetime DateTimeHelper::HourMinuteToDateTime(int hour, int minute)
{
    string timeString = Year() + "." + Month() + "." + Day() + " " + IntegerToString(hour) + ":" + IntegerToString(minute);
    return StringToTime(timeString);
}