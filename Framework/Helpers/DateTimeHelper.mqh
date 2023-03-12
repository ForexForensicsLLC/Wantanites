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
    static datetime FullDateTimeToString(int day, int month, int year, int hour, int minute);

    static datetime YearDayMonthStringToDateTime(string date);

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

datetime DateTimeHelper::FullDateTimeToString(int day, int month, int year, int hour, int minute)
{
    string dateString = DayMonthYearToDateTime(day, month, year) + " " + IntegerToString(hour) + ":" + IntegerToString(minute);
    return StringToTime(dateString);
}

// returns a new datetime from a string in the format yyyy/dd/MM HH:mm
datetime DateTimeHelper::YearDayMonthStringToDateTime(string date)
{
    string year = StringSubstr(date, 0, 4);
    string day = StringSubstr(date, 5, 2);
    string month = StringSubstr(date, 8, 2);
    string hour = StringSubstr(date, 11, 2);
    string minute = StringSubstr(date, 14, 2);

    Print("Date: ", date, ", Year: ", year, ", Day: ", day, ", Month: ", month, ", Hour: ", hour, ", Minute: ", minute);

    return FullDateTimeToString(StringToInteger(day), StringToInteger(month), StringToInteger(year), StringToInteger(hour), StringToInteger(minute));
}

string DateTimeHelper::FormatAsTwoDigits(int value)
{
    if (value >= 10)
    {
        return IntegerToString(value);
    }
    else
    {
        return "0" + IntegerToString(value);
    }

    return "";
}