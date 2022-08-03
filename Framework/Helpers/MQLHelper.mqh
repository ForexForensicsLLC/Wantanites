//+------------------------------------------------------------------+
//|                                                    MQLHelepr.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/Index.mqh>

class MQLHelper
{
public:
    // Tested
    static bool GetLowest(string symbol, int timeFrame, int mode, int count, int startIndex, bool inclusive, out int &lowIndex);

    // Tested
    static bool GetHighest(string symbol, int timeFrame, int mode, int count, int startIndex, bool inclusive, out int &highIndex);

    // Tested
    static bool GetLowestLow(string symbol, int timeFrame, int count, int startIndex, bool inclusive, out double &low);

    // Tested
    static bool GetHighestHigh(string symbol, int timeFrame, int count, int startIndex, bool inclusive, out double &high);
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
static bool MQLHelper::GetLowest(string symbol, int timeFrame, int mode, int count, int startIndex, bool inclusive, out int &lowIndex)
{
    if (inclusive)
    {
        count += 1;
    }

    if (count < 1)
    {
        return false;
    }

    lowIndex = iLowest(symbol, timeFrame, mode, count, startIndex);

    if (lowIndex < 0)
    {
        return false;
    }

    return true;
}

static bool MQLHelper::GetHighest(string symbol, int timeFrame, int mode, int count, int startIndex, bool inclusive, out int &highIndex)
{
    if (inclusive)
    {
        count += 1;
    }

    if (count < 1)
    {
        return false;
    }

    highIndex = iHighest(symbol, timeFrame, mode, count, startIndex);

    if (highIndex < 0)
    {
        return false;
    }

    return true;
}

static bool MQLHelper::GetLowestLow(string symbol, int timeFrame, int count, int startIndex, bool inclusive, out double &low)
{
    int lowestIndex = -1;
    if (!MQLHelper::GetLowest(symbol, timeFrame, MODE_LOW, count, startIndex, inclusive, lowestIndex))
    {
        return false;
    }

    low = iLow(symbol, timeFrame, lowestIndex);
    return true;
}

static bool MQLHelper::GetHighestHigh(string symbol, int timeFrame, int count, int startIndex, bool inclusive, out double &high)
{
    int highestIndex = -1;
    if (!MQLHelper::GetHighest(symbol, timeFrame, MODE_HIGH, count, startIndex, inclusive, highestIndex))
    {
        return false;
    }

    high = iHigh(symbol, timeFrame, highestIndex);
    return true;
}