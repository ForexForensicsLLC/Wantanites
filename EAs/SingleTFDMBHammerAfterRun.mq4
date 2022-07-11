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
#include <SummitCapital\InProgress\ConfirmationHelper.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0.1;
input double RiskPercent = 0.25;
input int TargetRR = 3;
/*
input int PartialOneRR = 10;
input double PartialOnePercent = 50;
*/

// -- MBTracker Inputs ---
input int MBsToTrack = 100;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = true;

// --- EA Constants ---
double const MinStopLoss = MarketInfo(Symbol(), MODE_STOPLEVEL) * _Point;
int const MBsNeeded = 2;
int const MagicNumber = 10003;
int const MaxTradesPerDay = 10;
double const MaxSpreadPips = 5;

// --- EA Globals ---
MBTracker* MBT;
MBState* MBStates[];
ZoneState* ZoneStates[];

bool SetUp = false;
int CurrentZoneIndex = MaxZonesInMB * MBsNeeded - 1;
int OnInit()
{
   MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors);
   
   ArrayResize(MBStates, MBsNeeded);
   ArrayResize(ZoneStates, MaxZonesInMB * MBsNeeded);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // delete MBT;
}

void OnTick()
{
   // divide by 10 to go from points -> pips
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) / 10;
   if (currentSpread < MaxSpreadPips && TradingTime())
   {
      // look for a fresh double MB after a run of at least 4 MBs
      if (!SetUp && !MBT.HasNMostRecentConsecutiveMBs(3) && MBT.HasNMostRecentConsecutiveMBs(2, MBStates) && MBT.NumberOfConsecutiveMBsBeforeNthMostRecent(1) > 3)
      {
         SetUp = true;
      }
      
      if (SetUp)
      {
         if (MBT.HasNMostRecentConsecutiveMBs(3))
         {
            TradeHelper::MoveAllOrdersToBreakEvenByMagicNumber(MagicNumber);
            SetUp = false;
            
            return;
         }
         
         bool brokeSetUpRange = MBStates[1].Type() == OP_BUY ? MathMin(iClose(Symbol(), Period(), 0), iOpen(Symbol(), Period(), 0)) < iLow(Symbol(), Period(), MBStates[1].LowIndex()) :
            MathMax(iOpen(Symbol(), Period(), 0), iClose(Symbol(), Period(), 0)) > iHigh(Symbol(), Period(), MBStates[1].HighIndex());
            
         if (brokeSetUpRange)
         {
            SetUp = false;            
            TradeHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
            
            return;
         }
         
         if (MBT.GetNMostRecentMBsUnretrievedZones(2, ZoneStates))
         {
            CurrentZoneIndex = MaxZonesInMB * MBsNeeded - 1;
         }
         
         int prevZoneIndex = CurrentZoneIndex;
         
         // find our most recent non borken zone
         for (int i = CurrentZoneIndex; i > 0; i--)
         {
            if (CheckPointer(ZoneStates[i]) == POINTER_INVALID)
            {
               CurrentZoneIndex -= 1;
               continue;
            }
            
            if (!ZoneStates[i].IsBroken(Symbol(), Period(), 0))
            {
               CurrentZoneIndex = i;
               break;
            }
         }
         
         if (CheckPointer(ZoneStates[CurrentZoneIndex]) == POINTER_INVALID)
         {
            return;
         }
         
         // broke our previous zone, cancel any stop orders we have pending
         if (prevZoneIndex != CurrentZoneIndex && OrdersTotal() > 0)
         {
            TradeHelper::CancelAllPendingOrdersByMagicNumber(MagicNumber);
         }
         
         if (OrdersTotal() == 0 && ZoneStates[CurrentZoneIndex].IsHolding(Symbol(), Period()))
         {
            if (ZoneStates[CurrentZoneIndex].Type() == OP_BUY && ConfirmationHelper::Hammer(Symbol(), Period()))
            {
               PlaceStopOrder(CurrentZoneIndex);
            }
            else if (ZoneStates[CurrentZoneIndex].Type() == OP_SELL && ConfirmationHelper::ShootingStar(Symbol(), Period()))
            {
               PlaceStopOrder(CurrentZoneIndex);
            }
         } 
      }
      else
      {
         ClearMBs();
      }
   }
}

void PlaceStopOrder(int zoneIndex)
{
   // convert from OP_BUY, OP_SELL -> OP_BUYSTOP, OP_SELLSTOP
   int orderType = ZoneStates[zoneIndex].Type() + 4;
   
   double entryPrice = 0.0;
   double stopLossRange = 0.0;
   double stopLoss = 0.0;
   double takeProfit = 0.0;
   double lots = 0.0;
   
   if (ZoneStates[zoneIndex].Type() == OP_BUY)
   {
      entryPrice = MathMax(iHigh(Symbol(), Period(), 0), Ask);
      stopLossRange = entryPrice > ZoneStates[zoneIndex].EntryPrice() ? ZoneStates[zoneIndex].Range() + MathAbs(ZoneStates[zoneIndex].EntryPrice() - entryPrice) : MathAbs(entryPrice - ZoneStates[zoneIndex].ExitPrice());
      stopLossRange += TradeHelper::PipsToRange(StopLossPaddingPips) + TradeHelper::PipsToRange(MaxSpreadPips);
      stopLoss = entryPrice - stopLossRange;
      takeProfit = entryPrice + (stopLossRange * TargetRR);
   }
   else if (ZoneStates[zoneIndex].Type() == OP_SELL)
   {
      entryPrice = MathMin(iLow(Symbol(), Period(), 0), Bid);
      stopLossRange = entryPrice < ZoneStates[zoneIndex].EntryPrice() ? ZoneStates[zoneIndex].Range() + MathAbs(ZoneStates[zoneIndex].EntryPrice() - entryPrice) : MathAbs(entryPrice - ZoneStates[zoneIndex].ExitPrice());
      stopLossRange += TradeHelper::PipsToRange(StopLossPaddingPips) + TradeHelper::PipsToRange(MaxSpreadPips);
      stopLoss = entryPrice + stopLossRange;
      takeProfit = entryPrice - (stopLossRange * TargetRR);
   }
   
   lots = TradeHelper::GetLotSize(TradeHelper::RangeToPips(stopLossRange), RiskPercent);
   
   //Print("G Type: ", orderType, ", Entry: ", entryPrice, ", SLPips: ", TradeHelper::RangeToPips(stopLossRange), ", SL: ", stopLoss, ", TP: ", takeProfit, ", Lots: ", lots);
   //Print("Zone EnP: ", ZoneStates[zoneIndex].EntryPrice(), ", Zone Exp: ", ZoneStates[zoneIndex].ExitPrice());
   //Print("Ask: ", Ask, ", Bid: ", Bid);
   
   TradeHelper::PlaceStopOrderWithNoPartials(orderType, lots, entryPrice, stopLoss, takeProfit, MagicNumber);
}

bool TradingTime()
{
   // don't trade from 4 - 7 central time aka spread hour
   return !(Hour() < 3);
}

void ClearMBs()
{
   ArrayFree(MBStates);
   ArrayResize(MBStates, MBsNeeded);
}