//+------------------------------------------------------------------+
//|                                                     Template.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs

//Make sure path is correct
#include <SummitCapital\InProgress\MBTracker.mqh>
#include <SummitCapital\InProgress\TradeHelper.mqh>

// --- EA Inputs ---
input double StopLossPadding = ;
input double RiskPercent = ;
input int PartialOneRR = ;
input double PartialOnePercent = ;

// -- MBTracker Inputs ---
input int MBsToTrack = 100;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;

// --- EA Constants ---
double const MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
int const MBsNeeded = ;
int const MagicNumber = ;
int const MaxTradesPerDay = ;
int const MaxSpread = ;

// --- EA Globals ---
MBTracker* MBT;
MB* MBs[];
Zone* Zones[];

int OnInit()
{
   MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones);
   
   ArrayResize(MBs, MBsNeeded);
   ArrayResize(Zones, MaxZonesInMB);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete MBT;
}

void OnTick()
{
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD);
}
