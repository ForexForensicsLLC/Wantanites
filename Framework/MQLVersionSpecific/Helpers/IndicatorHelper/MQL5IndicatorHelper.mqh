//+------------------------------------------------------------------+
//|                                                     VersionSpecificIndicatorHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class VersionSpecificIndicatorHelper
{
public:
    static double MovingAverage(string symbol, ENUM_TIMEFRAMES timeFrame, int maPeriod, int shift, ENUM_MA_METHOD mode, int appliedPrice, int position);
    static double OnBalanceVolumnAverageChange(string symbol, ENUM_TIMEFRAMES timeFrame, int appliedPrice, int period);
    static double RSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiPeriod, int appliedPrice, int position);
};

static double VersionSpecificIndicatorHelper::MovingAverage(string symbol, ENUM_TIMEFRAMES timeFrame, int maPeriod, int shift, ENUM_MA_METHOD mode, int appliedPrice,
                                                            int position)
{
    int handle;
    double values[];

    handle = iMA(symbol, timeFrame, maPeriod, shift, mode, appliedPrice);
    CopyBuffer(handle, 0, 0, position, values);

    // the furthest Indicator value is at the front of the array
    return values[0];
}

static double VersionSpecificIndicatorHelper::OnBalanceVolumnAverageChange(string symbol, ENUM_TIMEFRAMES timeFrame, int appliedPrice, int period)
{
    int handle;
    double values[];

    handle = iOBV(symbol, timeFrame, VOLUME_REAL);
    CopyBuffer(handle, 0, 0, period, values);

    int sum = 0;
    for (int i = 0; i < period; i++)
    {
        // the furthest Indicator value is at the front of the array so the value after it is after it in the array
        sum += (values[i] - values[i + 1]); // prev - next
    }

    return sum / period;
}

static double VersionSpecificIndicatorHelper::RSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiPeriod, int appliedPrice, int position)
{
    int handle;
    double values[];

    handle = iRSI(symbol, timeFrame, rsiPeriod, appliedPrice);
    CopyBuffer(handle, 0, 0, position, values);

    // the furthest Indicator value is at the front of the array
    return values[0];
}