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
    return iMA(symbol, timeFrame, maPeriod, shift, mode, appliedPrice, position);
}

static double VersionSpecificIndicatorHelper::OnBalanceVolumnAverageChange(string symbol, ENUM_TIMEFRAMES timeFrame, int appliedPrice, int period)
{
    int sum = 0;
    for (int i = 0; i < period; i++)
    {
        sum += (iOBV(symbol, timeFrame, appliedPrice, i + 1) - iOBV(symbol, timeFrame, appliedPrice, i));
    }

    return sum / period;
}

static double VersionSpecificIndicatorHelper::RSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiPeriod, int appliedPrice, int position)
{
    return iRSI(symbol, timeFrame, rsiPeriod, appliedPrice, position);
}
