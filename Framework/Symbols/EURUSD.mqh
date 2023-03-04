//+------------------------------------------------------------------+
//|                                                   PipValueHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Symbols\EURUSD.mqh>

class EURUSD
{
public:
    static string BrokerSymbol();
    static double PipValuePerLot();
};

static string EURUSD::BrokerSymbol()
{
    return "EURUSD";
}

static double EURUSD::PipValuePerLot()
{
    // should always be 10 since the base currency is USD but it doesn't hurt to make sure
    return MarketInfo(BrokerSymbol(), MODE_LOTSIZE) * MarketInfo(BrokerSymbol(), MODE_TICKSIZE) * 10;
}