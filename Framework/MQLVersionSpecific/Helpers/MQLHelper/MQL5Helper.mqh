//+------------------------------------------------------------------+
//|                                                    MQLHelepr.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class VersionSpecificMQLHelper
{
public:
    static long CurrentChartID();

    static bool GetLowest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, int &lowIndex);
    static bool GetHighest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, int &highIndex);
};

static long VersionSpecificMQLHelper::CurrentChartID()
{
    // ChartID always seems to work in mql5 no matter if we are in the strategy tester or not
    return ChartID();
}
/**
 * @brief
 *
 * @param symbol
 * @param timeFrame
 * @param mode
 * @param count - X number of candles back from the startIndex
 * @param startIndex
 * @param inclusive
 * @param lowIndex
 * @return true
 * @return false
 */
static bool VersionSpecificMQLHelper::GetLowest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, int &lowIndex)
{
    if (inclusive)
    {
        count += 1;
    }

    if (count < 1)
    {
        return false;
    }

    if (mode > 4)
    {
        return false;
    }

    lowIndex = iLowest(symbol, timeFrame, (ENUM_SERIESMODE)mode, count, startIndex);

    if (lowIndex < 0)
    {
        return false;
    }

    return true;
}

static bool VersionSpecificMQLHelper::GetHighest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, int &highIndex)
{
    if (inclusive)
    {
        count += 1;
    }

    if (count < 1)
    {
        return false;
    }

    if (mode > 4)
    {
        return false;
    }

    highIndex = iHighest(symbol, timeFrame, (ENUM_SERIESMODE)mode, count, startIndex);

    if (highIndex < 0)
    {
        return false;
    }

    return true;
}