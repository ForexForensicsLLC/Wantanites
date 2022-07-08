//+------------------------------------------------------------------+
//|                                                  MBIndicator.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

input int MBsToTrack = 200;
input int MaxZonesInMB = 5;
input int AllowZoneMitigation = false;

#include <SummitCapitalMT4\Classes\MBTracker.mqh>

CMBTracker* MBTracker;

int OnInit()
{
   MBTracker = new CMBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowZoneMitigation); 
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete MBTracker;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
  MBTracker.DrawMBs(-1);
  MBTracker.DrawZones(-1);
  
  return rates_total;
}



