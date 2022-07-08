//+------------------------------------------------------------------+
//|                                      NASDAQ100_1Sec_Reversal.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapitalMT4\Classes\MBTracker.mqh>

// --- Inputs ---
input double StopLossPadding = 50;
input double RiskPercent = 0.25;
input int PartialOneRR = 13;
input double PartialOnePercent = 0.5;

input int MBsToTrack = 100;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;

// --- Global Variables ---
CMBTracker* MBTracker;

double MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
double Spread = MarketInfo(Symbol(), MODE_SPREAD);

double MinROCs = 0.0;
bool ReversalSetUp = false;
bool DoubleMBReversal = false;
double CrossedOpenPriceAfterMinROC = false;

CMB* DoubleMB[];

int OnInit()
{
   MBTracker = new CMBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones);
   ArrayResize(DoubleMB, 2);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete MBTracker;
}

void OnTick()
{
   double openPrice = iCustom(NULL, 0, "./Indicators/Min ROC. From Time", 0, 0);
   double minROC = iCustom(NULL, 0, "./Indicators/Min ROC. From Time", 1, 0);
   
   if (openPrice != NULL)
   {
      if (minROC != NULL)
      {
         MinROCs += 1;
      }
      
      if (MBTracker.HasMostRecentConsecutiveMBs(2, DoubleMB))
      {
         datetime firstMBStartTime = iTime(Symbol(), Period(), DoubleMB[1].StartIndex());
         
         // MB was created after the start of the new york session
         if (TimeMinute(firstMBStartTime) >= 30)
         {
            // Place Limit Orders on all zones
            if (DoubleMB[0].Type() == OP_BUY)
            {
            }
            else if (DoubleMB[0].Type() == OP_SELL)
            {
            }
         }
      }     
   }
}