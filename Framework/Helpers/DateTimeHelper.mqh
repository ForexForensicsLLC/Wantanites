//+------------------------------------------------------------------+
//|                                                   DateTimeHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

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

class DateTimeHelper
{
public:
    static int MQLUTCOffset(datetime dt);

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

    static bool IsDayLightSavings(datetime dt);
    static MqlDateTime GetNthDayOfWeekForMonthAndYear(int nth, DayOfWeekEnum dayOfWeek, int month, int year);

    static bool DateIsDuringCandleIndex(string symbol, ENUM_TIMEFRAMES timeFrame, datetime date, int candleIndex);
};

int DateTimeHelper::MQLUTCOffset(datetime dt)
{
    // all mql4 charts are displayed in UTC+2 non DST time
    if (IsDayLightSavings(dt))
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
    return FullDateTimeToString(day, dt.mon, dt.year, hour, minute);
}

datetime DateTimeHelper::DayMonthYearToDateTime(int day, int month, int year)
{
    string dateString = IntegerToString(year) + "." + IntegerToString(month) + "." + IntegerToString(day);
    return StringToTime(dateString);
}

datetime DateTimeHelper::FullDateTimeToString(int day, int month, int year, int hour, int minute)
{
    string dateString = IntegerToString(year) + "." +
                        IntegerToString(month) + "." +
                        IntegerToString(day) + " " +
                        IntegerToString(hour) + ":" +
                        IntegerToString(minute);

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
    return utcDateTime += (60 * 60 * MQLUTCOffset(utcDateTime));
}

datetime DateTimeHelper::MQLTimeToUTC(datetime mqlDateTime)
{
    return mqlDateTime -= (60 * 60 * MQLUTCOffset(mqlDateTime));
}

static bool DateTimeHelper::IsDayLightSavings(datetime dt)
{
    MqlDateTime dayLightSavingsStartMQLDT = GetNthDayOfWeekForMonthAndYear(2, DayOfWeekEnum::Sunday, 3, CurrentYear());
    MqlDateTime dayLightSavingsEndMQLDT = GetNthDayOfWeekForMonthAndYear(1, DayOfWeekEnum::Sunday, 11, CurrentYear());

    MqlDateTime currentMQLTime;
    TimeToStruct(dt, currentMQLTime);

    if (currentMQLTime.day == dayLightSavingsStartMQLDT.day && currentMQLTime.mon == dayLightSavingsStartMQLDT.mon)
    {
        // start at 2 A.M Local Time
        return currentMQLTime.hour >= 10;
    }
    else if (currentMQLTime.day == dayLightSavingsEndMQLDT.day && currentMQLTime.mon == dayLightSavingsEndMQLDT.mon)
    {
        // end at 2 A.M Local Time
        return currentMQLTime.hour < 10;
    }

    datetime daylightSavingsStartDT = StructToTime(dayLightSavingsStartMQLDT);
    datetime daylightSavingsEndDT = StructToTime(dayLightSavingsEndMQLDT);

    return (dt > daylightSavingsStartDT && dt < daylightSavingsEndDT);
}

static MqlDateTime DateTimeHelper::GetNthDayOfWeekForMonthAndYear(int nth, DayOfWeekEnum dayOfWeek, int month, int year)
{
    datetime firstOfMonthDT = DayMonthYearToDateTime(1, month, year);

    MqlDateTime mqldt;
    TimeToStruct(firstOfMonthDT, mqldt);

    int firstDayOfWeekOfMonth = mqldt.day_of_week;
    int firstTargetDayOfWeekNumber = 0;

    // find how many days away the first week day of the month is from our target week day
    // if our current day of week is greater than our targer, then we need to loop around to it
    if (firstDayOfWeekOfMonth > dayOfWeek)
    {
        firstTargetDayOfWeekNumber = firstDayOfWeekOfMonth + (firstDayOfWeekOfMonth + dayOfWeek - 1);
    }
    else
    {
        firstTargetDayOfWeekNumber = firstDayOfWeekOfMonth + (firstDayOfWeekOfMonth - dayOfWeek);
    }

    datetime nthDayOfWeekForMonthAndYearDT;
    if (nth == 1)
    {
        nthDayOfWeekForMonthAndYearDT = DayMonthYearToDateTime(firstTargetDayOfWeekNumber, month, year);
    }
    else
    {
        int nthDayOfWeek = firstTargetDayOfWeekNumber + (7 * (nth - 1));
        nthDayOfWeekForMonthAndYearDT = DayMonthYearToDateTime(nthDayOfWeek, month, year);
    }

    MqlDateTime nthDayOfWeekForMonthAndYearMQLDT;
    TimeToStruct(nthDayOfWeekForMonthAndYearDT, nthDayOfWeekForMonthAndYearMQLDT);

    return nthDayOfWeekForMonthAndYearMQLDT;
}

static bool DateTimeHelper::DateIsDuringCandleIndex(string symbol, ENUM_TIMEFRAMES timeFrame, datetime date, int candleIndex)
{
    // iTime looks like it always returns the exact bar time but it doesn't hurt to make sure
    datetime currentBarTime = iTime(symbol, timeFrame, candleIndex);
    int secondsPerCandle = timeFrame * 60;
    datetime exactBarTime = currentBarTime - (currentBarTime % secondsPerCandle); // get exact bar time

    return MathAbs(date - exactBarTime) < secondsPerCandle;
}