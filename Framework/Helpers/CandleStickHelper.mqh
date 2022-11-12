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
    static bool IsBullish(string symbol, int timeFrame, int index);
    static bool IsBearish(string symbol, int timeFrame, int index);

    static double BodyLength(string symbol, int timeFrame, int index);

    static double PercentChange(string symbol, int timeFrame, int index);
    static double PercentBody(string symbol, int timeFrame, int index);

    static bool HasImbalance(int type, string symbol, int timeFrame, int index);

    static double GetHighestBodyPart(string symbol, int timeFrame, int index);
    static double GetLowestBodyPart(string symbol, int timeFrame, int index);
};

bool CandleStickHelper::IsBullish(string symbol, int timeFrame, int index)
{
    return iClose(symbol, timeFrame, index) > iOpen(symbol, timeFrame, index);
}

bool CandleStickHelper::IsBearish(string symbol, int timeFrame, int index)
{
    return iClose(symbol, timeFrame, index) < iOpen(symbol, timeFrame, index);
}

double CandleStickHelper::BodyLength(string symbol, int timeFrame, int index)
{
    return MathAbs(iOpen(symbol, timeFrame, index) - iClose(symbol, timeFrame, index));
}

double CandleStickHelper::PercentChange(string symbol, int timeFrame, int index)
{
    return ((iClose(symbol, timeFrame, index) - iOpen(symbol, timeFrame, index)) / iClose(symbol, timeFrame, index)) * 100;
}

double CandleStickHelper::PercentBody(string symbol, int timeFrame, int index)
{
    double candleLength = iHigh(symbol, timeFrame, index) - iLow(symbol, timeFrame, index);
    if (candleLength <= 0)
    {
        return 0.0;
    }

    return BodyLength(symbol, timeFrame, index) / candleLength;
}

bool CandleStickHelper::HasImbalance(int type, string symbol, int timeFrame, int index)
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

double CandleStickHelper::GetHighestBodyPart(string symbol, int timeFrame, int index)
{
    return MathMax(iOpen(symbol, timeFrame, index), iClose(symbol, timeFrame, index));
}

double CandleStickHelper::GetLowestBodyPart(string symbol, int timeFrame, int index)
{
    return MathMin(iOpen(symbol, timeFrame, index), iClose(symbol, timeFrame, index));
}