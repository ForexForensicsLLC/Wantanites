//+------------------------------------------------------------------+
//|                                                   PipValueHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class NASDAQ
{
public:
    static string BrokerSymbol();
    static double PipValuePerLot();
};

static string NASDAQ::BrokerSymbol()
{
    return "NAS100";
}

static double NASDAQ::PipValuePerLot()
{
    Print("Lot Size: ", MarketInfo(BrokerSymbol(), MODE_LOTSIZE), ", Tick Size: ", MarketInfo(BrokerSymbol(), MODE_TICKSIZE));
    return MarketInfo(BrokerSymbol(), MODE_LOTSIZE) * MarketInfo(BrokerSymbol(), MODE_TICKSIZE) * 10;
}