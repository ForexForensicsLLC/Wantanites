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

#include <SummitCapitalMT4\Classes\MBTracker.mqh>

// --- Inputs ---
input double StopLossPadding = 50;
input double RiskPercent = 0.25;
input int PartialOneRR = 13;
input double PartialOnePercent = 0.5;

// -- MBTracker ---
input int MBsToTrack = 100;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;

CMBTracker* MBTracker;

// --- General Global Variables --- 
double MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
double Spread = MarketInfo(Symbol(), MODE_SPREAD);

int OnInit()
{
   MBTracker = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete MBTracker;
}

void OnTick()
{
}

double CalculateLotSize(double SLPips)
{          
   double LotSize = 0;
   // We get the value of a tick.
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   // If the digits are 3 or 5, we normalize multiplying by 10.
   if ((Digits == 3) || (Digits == 5))
   {
      nTickValue = nTickValue * 10;
   }
   // We apply the formula to calculate the position size and assign the value to the variable.
   LotSize = (AccountBalance() * RiskPercent / 100) / (SLPips * nTickValue) / 100;
   Print(LotSize);
   return LotSize;
}

void BreakEven()
{
}

bool WithinTradingTime()
{
}

bool BelowSpreadThreshold()
{
}