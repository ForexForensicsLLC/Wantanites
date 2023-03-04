//+------------------------------------------------------------------+
//|                                                   PipValueHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Symbols\Symbol.mqh>

class NASDAQ : public Symbol
{
public:
    virtual string BrokerSymbol() { return "US100.cash"; }
    virtual double PipValuePerLot();
};

double NASDAQ::PipValuePerLot()
{
    return MarketInfo(BrokerSymbol(), MODE_LOTSIZE) * MarketInfo(BrokerSymbol(), MODE_TICKSIZE) * 10;
}
