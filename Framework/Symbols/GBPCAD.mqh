//+------------------------------------------------------------------+
//|                                                   PipValueHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Symbols\USDCAD.mqh>

class GBPCAD
{
public:
    static string BrokerSymbol();
    static double PipValuePerLot();
};

static string GBPCAD::BrokerSymbol()
{
    return "GBPCAD";
}

double GBPCAD::PipValuePerLot()
{
    // first need to get pip value in base currency, Canadian in this case
    double gbpCadPipValueInCanadian = MarketInfo(BrokerSymbol(), MODE_LOTSIZE) * MarketInfo(BrokerSymbol(), MODE_TICKSIZE) * 10;

    MqlTick currentTick;
    if (!SymbolInfoTick(USDCAD::BrokerSymbol(), currentTick))
    {
        return 0.0;
    }

    // convert canadian base to USD by multiplying by the USD/CAD rate
    return gbpCadPipValueInCanadian * currentTick.bid;
}