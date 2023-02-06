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
#include <WantaCapital\Framework\Trackers\MBTracker.mqh>
#include <WantaCapital\Framework\Helpers\OrderHelper.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 7;
input double RiskPercent = 0.25;
input int PartialOneRR = 13;
input double PartialOnePercent = 50;

// -- MBTracker Inputs 
input int MBsToTrack = 3;
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
int const MaxSpreadPips = 7;

// --- EA Globals ---
MBTracker* MBT;
MBState* MBStates[];
ZoneState* ZoneStates[];

bool StopTrading = false;
bool DoubleMBSetUp = false;

bool CanceledAllPendingOrders = false;

int SetUps = 0;
int SetUpType = -1;
double SetUpRangeStart = -1;
int MBTwoNumber = -1;

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
   MBT.DrawNMostRecentMBs(-1);
   MBT.DrawZonesForNMostRecentMBs(-1);
   
   if (OrdersTotal() > 0)
   {
      MBState* mbState; 
      if (MBT.GetNthMostRecentMB(0, mbState) && mbState.Number() > MBTwoNumber && mbState.Type() == SetUpType)
      {
         // TODO: Add Spread Back
         OrderHelper::TrailAllOrdersToMBUpToBreakEven(MagicNumber, 0, 0, mbState);      
      }
      
      if (!CanceledAllPendingOrders)
      {  
         bool tripleMB = MBT.HasNMostRecentConsecutiveMBs(3);
         bool liquidatedSecondAndContinued = DoubleMBSetUp && MBT.NthMostRecentMBIsOpposite(0) && MBT.NthMostRecentMBIsOpposite(1);
                
         //Print("Checking to cancel");
         // Stop trading for the day
         if (tripleMB || liquidatedSecondAndContinued)
         {
            Print("Canceling");
            StopTrading = true;
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            CanceledAllPendingOrders = true;
         }
      }
   }
   
   double openPrice = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 0, 0);
   
   // only trade if our spread is below the maximum and we are within our trading time
   if (openPrice != NULL)
   {
      double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) / 10;
      
      if (currentSpread <= MaxSpreadPips)
      {
         // stop trading if we've gone further than 0.18% past the start of the day
         double minROC = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 1, 0);
         
         if (minROC != NULL)
         {
            StopTrading = true;
            OrderHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            return;
         }
         
         bool brokeStartRange = (SetUpType == OP_BUY && Close[0] < SetUpRangeStart) || (SetUpType == OP_SELL && Close[0] > SetUpRangeStart);
         if (brokeStartRange)
         {
            DoubleMBSetUp = false;
            
            if (SetUps == 2)
            {
               StopTrading = true;
            }
         }
            
         if (!StopTrading)
         {            
            // if its either the first or second Double MB of the session and aren't currently in a set up
            if (SetUps < 2 && !DoubleMBSetUp && MBT.HasNMostRecentConsecutiveMBs(2, MBStates))
            {
               // if the entire set up happened after the start of the session
               if (TimeMinute(iTime(Symbol(), Period(), MBStates[1].StartIndex())) >= ServerMinuteStartTime)
               {
                  SetUps += 1;
                  DoubleMBSetUp = true;
                  
                  // store type and range end for ease of access later
                  SetUpType = MBStates[1].Type();
                  
                  if (SetUpType == OP_BUY)
                  {
                     SetUpRangeStart = iLow(Symbol(), Period(), MBStates[1].LowIndex());
                  }
                  else if (SetUpType == OP_SELL)
                  {
                     SetUpRangeStart = iHigh(Symbol(), Period(), MBStates[1].HighIndex());
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
            MBState* tempMBState;
            if (DoubleMBSetUp && MBT.GetNthMostRecentMB(0, tempMBState))
            {
               if (tempMBState.Number() == MBTwoNumber && MBT.GetNthMostRecentMBsUnretrievedZones(0, ZoneStates))
               {            
                  PlaceLimitOrders();
                  ClearZones();  
               }       
            }
         }
      }
   }
   else 
   {
      StopTrading = false;
      DoubleMBSetUp = false;
      
      CanceledAllPendingOrders = false;
      
      SetUps = 0;
      SetUpType = -1;
      SetUpRangeStart = -1;
      MBTwoNumber = -1;
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
         entryPrice = ZoneStates[i].EntryPrice() + OrderHelper::PipsToRange(MaxSpreadPips);
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
      CanceledAllPendingOrders = false;
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