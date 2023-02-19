//+------------------------------------------------------------------+
//|                                                   Symbol.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class Symbol
{
public:
    virtual string BrokerSymbol() = NULL;
    virtual double PipValuePerLot() = NULL;

    double PipsToRange(double pips);
    double RangeToPips(double range);
};

double Symbol::PipsToRange(double pips)
{
    return pips / MathPow(10, MarketInfo(BrokerSymbol(), MODE_DIGITS) - 1);
}

double Symbol::RangeToPips(double range)
{
    return range * MathPow(10, MarketInfo(BrokerSymbol(), MODE_DIGITS) - 1);
}