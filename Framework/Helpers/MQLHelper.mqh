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
    static bool GetLowest(string symbol, int timeFrame, int mode, int count, int startIndex, bool inclusive, out int &lowIndex);
    static bool GetHighest(string symbol, int timeFrame, int mode, int count, int startIndex, bool inclusive, out int &highIndex);

    static bool GetLowestIndexBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out int &lowIndex);
    static bool GetHighestIndexBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out int &highIndex);

    static bool GetLowestLow(string symbol, int timeFrame, int count, int startIndex, bool inclusive, out double &low);
    static bool GetHighestHigh(string symbol, int timeFrame, int count, int startIndex, bool inclusive, out double &high);

    static bool GetLowestLowBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &high);
    static bool GetHighestHighBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &high);

    static bool GetHighestBodyBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &highestBody);
    static bool GetLowestBodyBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &lowestBody);
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

static bool MQLHelper::GetLowestIndexBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out int &lowIndex)
{
    if (rightIndex > leftIndex)
    {
        return false;
    }

    if (!MQLHelper::GetLowest(symbol, timeFrame, MODE_LOW, leftIndex - rightIndex, rightIndex, inclusive, lowIndex))
    {
        return false;
    }

    return true;
}

static bool MQLHelper::GetHighestIndexBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out int &highIndex)
{
    if (rightIndex > leftIndex)
    {
        return false;
    }

    if (!MQLHelper::GetHighest(symbol, timeFrame, MODE_HIGH, leftIndex - rightIndex, rightIndex, inclusive, highIndex))
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

static bool MQLHelper::GetLowestLowBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &low)
{
    if (rightIndex > leftIndex)
    {
        return false;
    }

    if (!MQLHelper::GetLowestLow(symbol, timeFrame, leftIndex - rightIndex, rightIndex, inclusive, low))
    {
        return false;
    }

    return true;
}

static bool MQLHelper::GetHighestHighBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &high)
{
    if (rightIndex > leftIndex)
    {
        return false;
    }

    if (!MQLHelper::GetHighestHigh(symbol, timeFrame, leftIndex - rightIndex, rightIndex, inclusive, high))
    {
        return false;
    }

    return true;
}

/// @brief This will return the highest body at the given time. If you are running on every tick it could give inaccurate results
static bool MQLHelper::GetHighestBodyBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &highestBody)
{
    if (rightIndex > leftIndex)
    {
        return false;
    }

    int highestOpen;
    if (!GetHighest(symbol, timeFrame, MODE_OPEN, leftIndex - rightIndex, rightIndex, inclusive, highestOpen))
    {
        return false;
    }

    int highestClose;
    if (!GetHighest(symbol, timeFrame, MODE_CLOSE, leftIndex - rightIndex, rightIndex, inclusive, highestClose))
    {
        return false;
    }

    highestBody = MathMax(iOpen(symbol, timeFrame, highestOpen), iClose(symbol, timeFrame, highestClose));
    return true;
}

/// @brief This will return the lowest body at the given time. If you are running on every tick it could give inaccurate results
static bool MQLHelper::GetLowestBodyBetween(string symbol, int timeFrame, int leftIndex, int rightIndex, bool inclusive, out double &lowestBody)
{
    if (rightIndex > leftIndex)
    {
        return false;
    }

    int lowestOpen;
    if (!GetLowest(symbol, timeFrame, MODE_OPEN, leftIndex - rightIndex, rightIndex, inclusive, lowestOpen))
    {
        return false;
    }

    int lowestClose;
    if (!GetLowest(symbol, timeFrame, MODE_CLOSE, leftIndex - rightIndex, rightIndex, inclusive, lowestClose))
    {
        return false;
    }

    lowestBody = MathMin(iOpen(symbol, timeFrame, lowestOpen), iClose(symbol, timeFrame, lowestClose));
    return true;
}