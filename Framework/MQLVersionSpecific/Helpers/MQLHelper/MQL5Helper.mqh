//+------------------------------------------------------------------+
//|                                                    MQLHelepr.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/Index.mqh>

class MQLVersionSpecificHelper
{
public:
    static bool GetLowest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, out int &lowIndex);
    static bool GetHighest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, out int &highIndex);
};
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
static bool MQLVersionSpecificHelper::GetLowest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, out int &lowIndex)
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

static bool MQLVersionSpecificHelper::GetHighest(string symbol, ENUM_TIMEFRAMES timeFrame, int mode, int count, int startIndex, bool inclusive, out int &highIndex)
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