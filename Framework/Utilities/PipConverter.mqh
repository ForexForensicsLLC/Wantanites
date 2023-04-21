//+------------------------------------------------------------------+
//|                                                  PipConverter.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class PipConverter
{
public:
    static double PointsToPips(double points);
    static double PipsToPoints(double pips);
};

static double PipConverter::PointsToPips(double points)
{
    // do Digits - 1 for pips otherwise it would be in pippetts
    return points * MathPow(10, Digits - 1);
}

static double PipConverter::PipsToPoints(double pips)
{
    // do Digits - 1 for pips otherwise it would be in pippetts
    return pips / MathPow(10, Digits - 1);
}