//+------------------------------------------------------------------+
//|                                           TradePlacerMethods.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\OrderPlacer.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class OrderPlacementRetrievers
{    
   public:     
      static bool StopOrderOnCurrentCandle(OrderPlacer &op, ZoneState* &zoneStates[]);
};

static bool OrderPlacementRetrievers::StopOrderOnCurrentCandle(OrderPlacer &op, ZoneState* &zoneStates[])
{
   Print("Placing Order. Number of Zones: ", ArraySize(zoneStates));
   bool allOrdersPlaced = true;
   for (int i = 0; i < ArraySize(zoneStates); i++)
   {
      // convert from OP_BUY, OP_SELL -> OP_BUYSTOP, OP_SELLSTOP
      int orderType = zoneStates[i].Type()  +4;
      
      double entryPrice = 0.0;
      double stopLossRange = 0.0;
      double stopLoss = 0.0;
      double takeProfit = 0.0;
      double lots = 0.0;
      
      if (zoneStates[i].Type() == OP_BUY)
      {
         entryPrice = MathMax(iHigh(Symbol(), Period(), 0), Ask);
         stopLossRange = MathAbs(entryPrice - op.GetStopLoss(zoneStates[i])) + OrderHelper::PipsToRange(op.StopLossPaddingPips()) + OrderHelper::PipsToRange(op.SpreadPips());
         stopLoss = entryPrice - stopLossRange;
      }
      else if (zoneStates[i].Type() == OP_SELL)
      {
         entryPrice = MathMin(iLow(Symbol(), Period(), 0), Bid);
         stopLossRange = MathAbs(entryPrice - op.GetStopLoss(zoneStates[i])) + OrderHelper::PipsToRange(op.StopLossPaddingPips()) + OrderHelper::PipsToRange(op.SpreadPips());
         stopLoss = entryPrice + stopLossRange;
      }
      
      lots = OrderHelper::GetLotSize(OrderHelper::RangeToPips(stopLossRange), op.RiskPercent());
      
      //Print("G Type: ", orderType, ", Entry: ", entryPrice, ", SLPips: ", TradeHelper::RangeToPips(stopLossRange), ", SL: ", stopLoss, ", TP: ", takeProfit, ", Lots: ", lots);
      //Print("Zone EnP: ", ZoneStates[zoneIndex].EntryPrice(), ", Zone Exp: ", ZoneStates[zoneIndex].ExitPrice());
      //Print("Ask: ", Ask, ", Bid: ", Bid);
      for (int j = 0; j < op.PartialCount(); j++)
      {
         lots *= (op.PartialPercents(j) / 100);
         takeProfit = zoneStates[i].Type() == OP_BUY ? entryPrice + (stopLossRange * op.PartialRRs(j)) : entryPrice - (stopLossRange * op.PartialRRs(j));
         
         if (!OrderHelper::PlaceStopOrder(orderType, lots, entryPrice, stopLoss, takeProfit, op.MagicNumber()))
         {
            allOrdersPlaced = false;
         }
      }
   }
   
   return allOrdersPlaced;
}