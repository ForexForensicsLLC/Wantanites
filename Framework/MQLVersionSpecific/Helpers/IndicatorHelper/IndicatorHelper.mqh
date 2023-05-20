//+------------------------------------------------------------------+
//|                                                     IndicatorHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#ifdef __MQL4__
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\IndicatorHelper\MQL4IndicatorHelper.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\IndicatorHelper\MQL5IndicatorHelper.mqh>
#endif

class IndicatorHelper
{
public:
    static double MovingAverage(string symbol, ENUM_TIMEFRAMES timeFrame, int maPeriod, int shift, ENUM_MA_METHOD mode, int appliedPrice, int position);
    static double OnBalanceVolumnAverageChange(string symbol, ENUM_TIMEFRAMES timeFrame, int appliedPrice, int period);
    static double RSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiPeriod, int appliePrice, int poisition);
};

static double IndicatorHelper::MovingAverage(string symbol, ENUM_TIMEFRAMES timeFrame, int maPeriod, int shift, ENUM_MA_METHOD mode, int appliedPrice, int position)
{
    return VersionSpecificIndicatorHelper::MovingAverage(symbol, timeFrame, maPeriod, shift, mode, appliedPrice, position);
}

static double IndicatorHelper::OnBalanceVolumnAverageChange(string symbol, ENUM_TIMEFRAMES timeFrame, int appliedPrice, int period)
{
    return VersionSpecificIndicatorHelper::OnBalanceVolumnAverageChange(symbol, timeFrame, appliedPrice, period);
}

static double IndicatorHelper::RSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiPeriod, int appliedPrice, int position)
{
    return VersionSpecificIndicatorHelper::RSI(symbol, timeFrame, rsiPeriod, appliedPrice, position);
}