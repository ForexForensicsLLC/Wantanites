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
input double StopLossPadding = 70;
input double RiskPercent = 0.25;
input int PartialOneRR = 13;
input double PartialOnePercent = 50;

// -- MBTracker Inputs ---
input int MBsToTrack = 100;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;

// --- Min ROC. Inputs ---
input int ServerHourStartTime = 16; 
input int ServerMinuteStartTime = 30;
input int ServerHourEndTime = 16 ; 
input int ServerMinuteEndTime = 33;
input double MinROCPercent = 0.18;

// --- EA Constants ---
double const MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
int const MBsNeeded = 2;
int const MagicNumber = 10001;
int const MaxTradesPerDay = 10;
int const MaxSpread = 100;

// --- EA Globals ---
MBTracker* MBT;
MB* MBs[];
Zone* Zones[];

bool StopTrading = false;
bool DoubleMBSetUp = false;

int SetUps = 0;
int SetUpType = -1;
double SetUpRangeEnd = -1;

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
   double openPrice = iCustom(Symbol(), Period(), "Include/SummitCapital/Finished/Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 0, 0);
   
   // only trade if our spread is below the maximum and we are within our trading time
   if (currentSpread <= MaxSpread && openPrice != NULL)
   {
      if (!StopTrading)
      {
         // stop trading if we've gone further than 0.18% past the start of the day
         double minROC = iCustom(Symbol(), Period(), "Include/SummitCapital/Finished/Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 1, 0);
         if (minROC != NULL)
         {
            StopTrading = true;
            TradeHelper::CancelAllPendingLimitOrdersByMagicNumber(MagicNumber);
            return;
         }
         
         if (DoubleMBSetUp)
         {
            // cancel / move all orders to break even if we put in a third consecutive MB
            if (MBT.HasMostRecentConsecutiveMBs(3))
            {
               DoubleMBSetUp = false;
               TradeHelper::MoveAllOrdersToBreakEvenByMagicNumber(MagicNumber);
               TradeHelper::CancelAllPendingLimitOrdersByMagicNumber(MagicNumber);
               
               // if its our second setup, stop trading for the day
               if (SetUps == 2)
               {
                  StopTrading = true;
               }
               
               return;
            }
            
            // we've broken the range
            if ((SetUpType == OP_BUY && Close[0] < SetUpRangeEnd) || (SetUpType == OP_SELL && Close[0] > SetUpRangeEnd))
            {
               DoubleMBSetUp = false;
               
               // if its our second set up, stop trading for the day
               if (SetUps == 2)
               {
                  StopTrading = true;
               }
               
               return;
            }     
         }
         
         // if its either the first or second Double MB of the session and aren't currently in a set up
         if (SetUps < 2 && !DoubleMBSetUp && MBT.HasMostRecentConsecutiveMBs(2, MBs))
         {
            // if we're below the max spread and the entire set up happened after the start of the session
            if (currentSpread <= MaxSpread && TimeMinute(iTime(Symbol(), Period(), MBs[1].StartIndex())) >= 30)
            {
               SetUps += 1;
               DoubleMBSetUp = true;
               
               // store type and range end for ease of access later
               SetUpType = MBs[1].Type();
               
               if (SetUpType == OP_BUY)
               {
                  SetUpRangeEnd = iLow(Symbol(), Period(), MBs[1].LowIndex());
               }
               else if (SetUpType == OP_SELL)
               {
                  SetUpRangeEnd = iHigh(Symbol(), Period(), MBs[1].HighIndex());
               }
               
               // loop through both MBs and place orders on every zone
               for (int i = 0; i < MBsNeeded; i++)
               {
                  if (MBT.GetUnretrievedZonesForNthMostRecentMB(i, 1, Zones))
                  {
                     PlaceLimitOrders();
                     ClearZones();
                  }
               }
            }
            
            ClearMBs();
         }
         
         // check to see if a new zones was created after the double mb
         if (DoubleMBSetUp && MBT.GetUnretrievedZonesForNthMostRecentMB(1, 1, Zones))
         {
            if (currentSpread <= MaxSpread)
            {
               PlaceLimitOrders();
               ClearZones();
            }
         }
      }
   }
   else 
   {
      StopTrading = false;
      DoubleMBSetUp = false;
      
      SetUps = 0;
      SetUpType = -1;
      SetUpRangeEnd = -1;
   }
}

void PlaceLimitOrders()
{
   for (int i = 0; i < MaxZonesInMB; i++)
   {
      if (CheckPointer(Zones[i]) == POINTER_INVALID)
      {
         return;
      }   
      
      int orderType = SetUpType + 2;
      
      double stopLossPips = Zones[i].Range() + MaxSpread + StopLossPadding;
      stopLossPips = stopLossPips < MinStopLoss ? MinStopLoss : stopLossPips;
      
      double stopLoss = SetUpType == OP_BUY ? Zones[i].EntryPrice() - stopLossPips : Zones[i].EntryPrice() + stopLossPips;
      double takeProfit = SetUpType == OP_BUY ? Zones[i].EntryPrice() + (PartialOneRR * stopLossPips) : Zones[i].EntryPrice() - (PartialOneRR * stopLossPips);

      double lots = TradeHelper::GetLotSize(stopLossPips, RiskPercent);
      
      TradeHelper::PlaceLimitOrderWithSinglePartial(orderType, lots, Zones[i].EntryPrice(), stopLoss, takeProfit, PartialOnePercent, MagicNumber);
   }   
}

// remove all MBs from the array so we don't get any false readings
void ClearMBs()
{
   ArrayFree(MBs);
   ArrayResize(MBs, MBsNeeded);
}

// remove all zones from the array so we don't get any false readings
void ClearZones()
{
   ArrayFree(Zones);
   ArrayResize(Zones, MaxZonesInMB);
}