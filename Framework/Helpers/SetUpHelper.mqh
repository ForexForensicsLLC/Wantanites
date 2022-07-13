//+------------------------------------------------------------------+
//|                                                  SetUpHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class SetUpHelper
{
   private:
   
   public:
      static bool BrokeRange(MBState* &mbState);
};

static bool SetUpHelper::BrokeRange(MBState* &mbState)
{
   bool brokeBullishMB = false;
   bool brokeBearishMB = false;
   
   if (CheckPointer(mbState) != POINTER_INVALID)
   {
      brokeBullishMB = mbState.Type() == OP_BUY && iLow(mbState.Symbol(), mbState.TimeFrame(), 0) < iLow(mbState.Symbol(), mbState.TimeFrame(), mbState.LowIndex());
      brokeBearishMB = mbState.Type() == OP_SELL && iHigh(mbState.Symbol(), mbState.TimeFrame(), 0) > iHigh(mbState.Symbol(), mbState.TimeFrame(), mbState.HighIndex());
   }
   
   return brokeBullishMB || brokeBearishMB;
}


