//+------------------------------------------------------------------+
//|                                                   CandleStickHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class CandleStickHelper
{
public:
    static bool IsBullish(string symbol, ENUM_TIMEFRAMES timeFrame, int index);
    static bool IsBearish(string symbol, ENUM_TIMEFRAMES timeFrame, int index);

    static bool IsDownFractal(string symbol, ENUM_TIMEFRAMES timeFrame, int index);
    static bool IsUpFractal(string symbol, ENUM_TIMEFRAMES timeFrame, int index);

    static double CandleLength(string symbol, ENUM_TIMEFRAMES timeFrame, int index);
    static double BodyLength(string symbol, ENUM_TIMEFRAMES timeFrame, int index);

    static double PercentChange(string symbol, ENUM_TIMEFRAMES timeFrame, int index);
    static double PercentBody(string symbol, ENUM_TIMEFRAMES timeFrame, int index);

    static bool HasImbalance(int type, string symbol, ENUM_TIMEFRAMES timeFrame, int index);
    static bool BrokeFurther(int type, string symbol, ENUM_TIMEFRAMES timeFrame, int index);

    static double HighestBodyPart(string symbol, ENUM_TIMEFRAMES timeFrame, int index);
    static double LowestBodyPart(string symbol, ENUM_TIMEFRAMES timeFrame, int index);
};

bool CandleStickHelper::IsBullish(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return iClose(symbol, timeFrame, index) >= iOpen(symbol, timeFrame, index);
}

bool CandleStickHelper::IsBearish(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return iClose(symbol, timeFrame, index) < iOpen(symbol, timeFrame, index);
}

static bool CandleStickHelper::IsDownFractal(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    double thisLow = iLow(symbol, timeFrame, index);
    return thisLow < iLow(symbol, timeFrame, index + 1) && thisLow < iLow(symbol, timeFrame, index - 1);
}
static bool CandleStickHelper::IsUpFractal(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    double thisHigh = iHigh(symbol, timeFrame, index);
    return thisHigh > iHigh(symbol, timeFrame, index + 1) && thisHigh > iHigh(symbol, timeFrame, index - 1);
}

double CandleStickHelper::CandleLength(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return iHigh(symbol, timeFrame, index) - iLow(symbol, timeFrame, index);
}

double CandleStickHelper::BodyLength(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return MathAbs(iOpen(symbol, timeFrame, index) - iClose(symbol, timeFrame, index));
}

double CandleStickHelper::PercentChange(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return ((iClose(symbol, timeFrame, index) - iOpen(symbol, timeFrame, index)) / iClose(symbol, timeFrame, index)) * 100;
}

double CandleStickHelper::PercentBody(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    double candleLength = iHigh(symbol, timeFrame, index) - iLow(symbol, timeFrame, index);
    if (candleLength <= 0)
    {
        return 0.0;
    }

    return BodyLength(symbol, timeFrame, index) / candleLength;
}

bool CandleStickHelper::HasImbalance(int type, string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    if (type == OP_BUY)
    {
        return iHigh(symbol, timeFrame, index + 1) < iLow(symbol, timeFrame, index - 1);
    }
    else if (type == OP_SELL)
    {
        return iLow(symbol, timeFrame, index + 1) > iHigh(symbol, timeFrame, index - 1);
    }

    return false;
}

bool CandleStickHelper::BrokeFurther(int type, string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    if (type == OP_BUY)
    {
        return iClose(symbol, timeFrame, index) > iHigh(symbol, timeFrame, index + 1);
    }
    else if (type == OP_SELL)
    {
        return iClose(symbol, timeFrame, index) < iLow(symbol, timeFrame, index + 1);
    }

    return false;
}

double CandleStickHelper::HighestBodyPart(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return MathMax(iOpen(symbol, timeFrame, index), iClose(symbol, timeFrame, index));
}

double CandleStickHelper::LowestBodyPart(string symbol, ENUM_TIMEFRAMES timeFrame, int index)
{
    return MathMin(iOpen(symbol, timeFrame, index), iClose(symbol, timeFrame, index));
}