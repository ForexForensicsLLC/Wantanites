//+------------------------------------------------------------------+
//|                                           StopLossRetrievers.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\ZoneState.mqh>

class StopLossRetrievers
{
   public:
      static double StopLossBelowZone(ZoneState* &zoneState);
      static double StopLossBelowCurrentCandle(ZoneState* &zoneState);
};

static double StopLossRetrievers::StopLossBelowZone(ZoneState* &zoneState)
{
   return zoneState.ExitPrice();
}

static double StopLossRetrievers::StopLossBelowCurrentCandle(ZoneState* &zoneState)
{
   return zoneState.Type() == OP_BUY ? iLow(zoneState.Symbol(), zoneState.TimeFrame(), 0) : iHigh(zoneState.Symbol(), zoneState.TimeFrame(), 0);
}

