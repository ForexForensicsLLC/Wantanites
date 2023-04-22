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
    static int MQLUTCOffset();

    static MqlDateTime CurrentTime();
    static int CurrentYear();
    static int CurrentMonth();
    static int CurrentDay();
    static int CurrentHour();
    static int CurrentMinute();
    static int CurrentSecond();
    static int CurrentDayOfWeek();

    static MqlDateTime ToMQLDateTime(datetime dt);
    static int ToDay(datetime dt);

    static datetime HourMinuteToDateTime(int hour, int minute, int day);
    static datetime DayMonthYearToDateTime(int day, int month, int year);
    static datetime FullDateTimeToString(int day, int month, int year, int hour, int minute);

    static datetime YearDayMonthStringToDateTime(string date);

    static string FormatAsTwoDigits(int value);

    static datetime UTCToMQLTime(datetime utcTime);
    static datetime MQLTimeToUTC(datetime mqlTime);
};

int DateTimeHelper::MQLUTCOffset()
{
    // all mql4 charts are displayed in UTC+2 non DST time
    if (TimeDaylightSavings() != 0)
    {
        return 3;
    }

    return 2;
}

MqlDateTime DateTimeHelper::CurrentTime()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt;
}

int DateTimeHelper::CurrentYear()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.year;
}

int DateTimeHelper::CurrentMonth()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.mon;
}

int DateTimeHelper::CurrentDay()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.day;
}

int DateTimeHelper::CurrentHour()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.hour;
}

int DateTimeHelper::CurrentMinute()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.min;
}

int DateTimeHelper::CurrentSecond()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.sec;
}

int DateTimeHelper::CurrentDayOfWeek()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    return dt.day_of_week;
}

static MqlDateTime DateTimeHelper::ToMQLDateTime(datetime dt)
{
    MqlDateTime mqldt;
    TimeToStruct(dt, mqldt);

    return mqldt;
}

static int DateTimeHelper::ToDay(datetime dt)
{
    MqlDateTime mqldt;
    TimeToStruct(dt, mqldt);

    return mqldt.day;
}

datetime DateTimeHelper::HourMinuteToDateTime(int hour, int minute, int day)
{
    MqlDateTime dt = CurrentTime();

    string timeString = dt.year + "." + dt.mon + "." + day + " " + IntegerToString(hour) + ":" + IntegerToString(minute);
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

datetime DateTimeHelper::UTCToMQLTime(datetime utcDateTime)
{
    return utcDateTime += (60 * 60 * MQLUTCOffset());
}

datetime DateTimeHelper::MQLTimeToUTC(datetime mqlDateTime)
{
    return mqlDateTime -= (60 * 60 * MQLUTCOffset());
}