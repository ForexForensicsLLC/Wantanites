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
input double StopLossPaddingPips = 70;
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
int const MagicNumber = 10002;
int const MaxTradesPerDay = 10;
int const MaxSpreadPips = 100;

// --- EA Globals ---
MBTracker* MBT;
MBState* MBStates[];
ZoneState* ZoneStates[];

bool HadMinROC = false;

double SetUpRangeEnd = -1.0;
int SetUpType = -1;

bool SingleMBSetUp = false;
bool DoubleMBSetUp = false;

bool StopTrading = false;

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
   double openPrice  = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 0, 0);
   
   // only trade if spread is below the allow maximum and if it is within our trading time 
   if (currentSpread <= MaxSpreadPips && openPrice != NULL)
   {
      if (!StopTrading)
      {
         if (SingleMBSetUp || DoubleMBSetUp)
         {
            // cancle / move all orders to break even if we've put in 3 consecutive MBs
            bool tripleMB = MBT.HasNMostRecentConsecutiveMBs(3);
            if (tripleMB)
            {
               StopTrading = true;
               TradeHelper::MoveAllOrdersToBreakEvenByMagicNumber(MagicNumber);
               TradeHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
               return;
            }
            
            bool brokeRange = (SetUpType == OP_BUY && Close[0] < SetUpRangeEnd) || (SetUpType == OP_SELL && Close[0] > SetUpRangeEnd);
            bool liquidatedSecondAndContinued = DoubleMBSetUp && MBT.NthMostRecentMBIsOpposite(0) && MBT.NthMostRecentMBIsOpposite(1);
            bool crossedOpenPrice = (Close[1] < openPrice && MathMax(Close[0], High[0]) > openPrice) || (Close[1] > openPrice && MathMin(Close[0], Low[0]) < openPrice);
                   
            // Stop trading for the day
            if (brokeRange || liquidatedSecondAndContinued || crossedOpenPrice)
            {
               StopTrading = true;
               TradeHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            }
         }
         
         double minRateOfChange = iCustom(Symbol(), Period(), "Min ROC. From Time", ServerHourStartTime, ServerMinuteStartTime, ServerHourEndTime, ServerMinuteEndTime, MinROCPercent, 1, 0);
         HadMinROC = !HadMinROC ? minRateOfChange != NULL : HadMinROC;
         
         // if we've had a Min ROC and ahven't had a setup yet, and the current MB just broke structure
         if (HadMinROC && !SingleMBSetUp && !DoubleMBSetUp && MBT.NthMostRecentMBIsOpposite(0, MBStates))
         {
            // only if the setup happened during our session
            if (TimeMinute(iTime(Symbol(), Period(), MBStates[0].StartIndex())) >= 30)
            {
               SingleMBSetUp = true;       
               
               // store type and range end for ease of access later 
               SetUpType = MBStates[0].Type();
               
               if (SetUpType == OP_BUY)
               {
                  SetUpRangeEnd = iLow(Symbol(), Period(), MBStates[0].LowIndex());
               }
               else if (SetUpType == OP_SELL)
               {
                  SetUpRangeEnd = iHigh(Symbol(), Period(), MBStates[0].HighIndex());
               }
               
               // place orders on the zones of the first MB
               if (MBT.GetNthMostRecentMBsUnretrievedZones(0, ZoneStates))
               {
                  PlaceLimitOrders();
               }
            }
            
            ClearMBs();
            ClearZones();
         }   
         
         // if we've had a min roc and a single MB break down and a second has just continuted structure
         if (HadMinROC && SingleMBSetUp && !DoubleMBSetUp && MBT.HasNMostRecentConsecutiveMBs(2, MBStates))
         {
            DoubleMBSetUp = true;
            
            // place orders on the zones of the second MB
            if (MBT.GetNthMostRecentMBsUnretrievedZones(1, ZoneStates))
            {
               PlaceLimitOrders();
            }
            
            ClearMBs();
            ClearZones();
         }
         
         // check for any zones that may have printed after the second MB was validated
         if (HadMinROC && (SingleMBSetUp || DoubleMBSetUp) && MBT.GetNthMostRecentMBsUnretrievedZones(0, ZoneStates))
         {
            PlaceLimitOrders();
            ClearZones();
         }
      }
   }
   else
   {
      HadMinROC = false;
      StopTrading = false;
      
      SetUpRangeEnd = -1.0;
      SetUpType = -1;
      
      SingleMBSetUp = false;
      DoubleMBSetUp = false;
      
      // TradeHelper::RecordTradesForToday(MagicNumber);
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
         stopLossRange = ZoneStates[i].Range() + TradeHelper::PipsToRange(MaxSpreadPips) + TradeHelper::PipsToRange(StopLossPaddingPips);
         stopLoss = entryPrice - stopLossRange;
         takeProfit = entryPrice + (stopLossRange * PartialOneRR);
      }
      else if (SetUpType == OP_SELL)
      {
         entryPrice = ZoneStates[i].EntryPrice();
         stopLossRange = ZoneStates[i].Range() + TradeHelper::PipsToRange(MaxSpreadPips) + TradeHelper::PipsToRange(StopLossPaddingPips);
         stopLoss = entryPrice + stopLossRange;
         takeProfit = entryPrice - (stopLossRange * PartialOneRR);
      }

      lots = TradeHelper::GetLotSize(TradeHelper::RangeToPips(stopLossRange), RiskPercent);
      
      TradeHelper::PlaceLimitOrderWithSinglePartial(orderType, lots, entryPrice, stopLoss, takeProfit, PartialOnePercent, MagicNumber);
   }   
}

// remove all MBs from the array to avoid getting false signals
void ClearMBs()
{
   ArrayFree(MBStates);
   ArrayResize(MBStates, MBsNeeded);
}

// remove all Zones from the array to avoid getting false signals
void ClearZones()
{
   ArrayFree(ZoneStates);
   ArrayResize(ZoneStates, MaxZonesInMB);
}