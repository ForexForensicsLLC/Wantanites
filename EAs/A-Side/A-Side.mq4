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
#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 7;
input double RiskPercent = 0.25;
input int PartialOneRR = 13;
input double PartialOnePercent = 50;

// -- MBTracker Inputs ---
input int MBsToTrack = 100;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;

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
int const MaxSpreadPips = 10;

// --- EA Globals ---
MBTracker* MBT;
MBState* MBStates[];
ZoneState* ZoneStates[];

bool StopTrading = false;
bool DoubleMBSetUp = false;

int SetUps = 0;
int SetUpType = -1;
double SetUpRangeEnd = -1;

int OnInit()
{
   MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors);
   
   ArrayResize(MBStates, MBsNeeded);
   ArrayResize(ZoneStates, MaxZonesInMB);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete MBT;
}

void OnTick()
{
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) / 10;
   double openPrice = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 0, 0);
   
   // only trade if our spread is below the maximum and we are within our trading time
   if (currentSpread <= MaxSpreadPips && openPrice != NULL)
   {
      if (!StopTrading)
      {
         // stop trading if we've gone further than 0.18% past the start of the day
         double minROC = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 1, 0);
         if (minROC != NULL)
         {
            StopTrading = true;
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            return;
         }
         
         if (DoubleMBSetUp)
         {
            // cancel / move all orders to break even if we put in a third consecutive MB
            if (MBT.HasNMostRecentConsecutiveMBs(3))
            {
               DoubleMBSetUp = false;
               OrderHelper::MoveAllOrdersToBreakEvenByMagicNumber(MagicNumber);
               OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
               
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
         if (SetUps < 2 && !DoubleMBSetUp && MBT.HasNMostRecentConsecutiveMBs(2, MBStates))
         {
            // if the entire set up happened after the start of the session
            if (TimeMinute(iTime(Symbol(), Period(), MBStates[1].StartIndex())) >= 30)
            {
               SetUps += 1;
               DoubleMBSetUp = true;
               
               // store type and range end for ease of access later
               SetUpType = MBStates[1].Type();
               
               if (SetUpType == OP_BUY)
               {
                  SetUpRangeEnd = iLow(Symbol(), Period(), MBStates[1].LowIndex());
               }
               else if (SetUpType == OP_SELL)
               {
                  SetUpRangeEnd = iHigh(Symbol(), Period(), MBStates[1].HighIndex());
               }
               
               // loop through both MBs and place orders on every zone
               for (int i = 0; i < MBsNeeded; i++)
               {
                  if (MBT.GetNthMostRecentMBsUnretrievedZones(i, ZoneStates))
                  {
                     PlaceLimitOrders();
                     ClearZones();
                  }
               }
            }
            
            ClearMBs();
         }
         
         // check to see if a new zones was created after the double mb
         if (DoubleMBSetUp && MBT.GetNthMostRecentMBsUnretrievedZones(0, ZoneStates))
         {
            PlaceLimitOrders();
            ClearZones();         
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
      if (CheckPointer(ZoneStates[i]) == POINTER_INVALID)
      {
         continue;
      }   
      
      int orderType = SetUpType + 2;
      
      double entryPrice = 0.0;
      double stopLossRange = 0.0;
      double stopLoss = 0.0;
      double takeProfit = 0.0;
      double lots = 0.0;
      
      if (SetUpType == OP_BUY)
      {
         entryPrice = ZoneStates[i].EntryPrice();
         stopLossRange = ZoneStates[i].Range() + OrderHelper::PipsToRange(MaxSpreadPips) + OrderHelper::PipsToRange(StopLossPaddingPips);
         stopLoss = entryPrice - stopLossRange;
         takeProfit = entryPrice + (stopLossRange * PartialOneRR);
      }
      else if (SetUpType == OP_SELL)
      {
         entryPrice = ZoneStates[i].EntryPrice();
         stopLossRange = ZoneStates[i].Range() + OrderHelper::PipsToRange(MaxSpreadPips) + OrderHelper::PipsToRange(StopLossPaddingPips);
         stopLoss = entryPrice + stopLossRange;
         takeProfit = entryPrice - (stopLossRange * PartialOneRR);
      }

      lots = OrderHelper::GetLotSize(OrderHelper::RangeToPips(stopLossRange), RiskPercent);
      
      OrderHelper::PlaceLimitOrderWithSinglePartial(orderType, lots, entryPrice, stopLoss, takeProfit, PartialOnePercent, MagicNumber);
   }   
}

// remove all MBs from the array so we don't get any false readings
void ClearMBs()
{
   ArrayFree(MBStates);
   ArrayResize(MBStates, MBsNeeded);
}

// remove all zones from the array so we don't get any false readings
void ClearZones()
{
   ArrayFree(ZoneStates);
   ArrayResize(ZoneStates, MaxZonesInMB);
}