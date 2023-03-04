//+------------------------------------------------------------------+
//|                                                   PipValueHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Symbols\USDCAD.mqh>

class USDCAD
{
public:
    static string BrokerSymbol();
    static double PipValuePerLot();
};

static string USDCAD::BrokerSymbol()
{
    return "USDCAD";
}