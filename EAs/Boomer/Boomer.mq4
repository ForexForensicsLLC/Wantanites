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

bool HadMinROC = false;

double SetUpRangeEnd = -1.0;
int SetUpType = -1;

bool SingleMBSetUp = false;
bool DoubleMBSetUp = false;

bool StopTrading = false;

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
   double openPrice  = iCustom(Symbol(), Period(), "Include/SummitCapital/Finished/Min ROC. From Time", 0, 0);
   if (openPrice != NULL && !StopTrading)
   {
      if (SingleMBSetUp || DoubleMBSetUp)
      {
         bool tripleMB = MBT.HasMostRecentConsecutiveMBs(3);
         if (tripleMB)
         {
            StopTrading = true;
            TradeHelper::MoveAllOrdersToBreakEvenByMagicNumber(MagicNumber);
            TradeHelper::CancelAllPendingLimitOrdersByMagicNumber(MagicNumber);
            return;
         }
         
         bool brokeRange = (SetUpType == OP_BUY && Close[0] < SetUpRangeEnd) || (SetUpType == OP_SELL && Close[0] > SetUpRangeEnd);
         bool liquidatedSecondAndContinued = DoubleMBSetUp && MBT.IsOppositeMB(0) && MBT.IsOppositeMB(1);
         bool crossedOpenPrice = (Close[1] < openPrice && MathMax(Close[0], High[0]) > openPrice) || (Close[1] > openPrice && MathMin(Close[0], Low[0]) < openPrice);
                
         if (brokeRange || liquidatedSecondAndContinued || crossedOpenPrice)
         {
            StopTrading = true;
            TradeHelper::CancelAllPendingLimitOrdersByMagicNumber(MagicNumber);
         }
      }
      
      double minRateOfChange = iCustom(Symbol(), Period(), "Include/SummitCapital/Finished/Min ROC. From Time", 1, 0);
      HadMinROC = !HadMinROC ? minRateOfChange != NULL : HadMinROC;
      
      if (HadMinROC && !SingleMBSetUp && !DoubleMBSetUp && MBT.IsOppositeMB(0, MBs))
      {
         SingleMBSetUp = true;        
         SetUpType = MBs[0].Type();
         
         if (SetUpType == OP_BUY)
         {
            SetUpRangeEnd = iLow(Symbol(), Period(), MBs[0].LowIndex());
         }
         else if (MBs[0].Type() == OP_SELL)
         {
            SetUpRangeEnd = iHigh(Symbol(), Period(), MBs[0].HighIndex());
         }
         
         if (currentSpread <= MaxSpread && MBT.GetUnretrievedZonesForNthMostRecentMB(1, 1, Zones))
         {
            PlaceLimitOrders();
         }

         ClearMBs();
         ClearZones();
      }   
      
      if (HadMinROC && SingleMBSetUp && !DoubleMBSetUp && MBT.HasMostRecentConsecutiveMBs(2, MBs))
      {
         DoubleMBSetUp = true;
         
         if (currentSpread <= MaxSpread && MBT.GetUnretrievedZonesForNthMostRecentMB(2, 1, Zones))
         {
            PlaceLimitOrders();
         }
         
         ClearMBs();
         ClearZones();
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
void ClearMBs()
{
   ArrayFree(MBs);
   ArrayResize(MBs, MBsNeeded);
}

void ClearZones()
{
   ArrayFree(Zones);
   ArrayResize(Zones, MaxZonesInMB);
}