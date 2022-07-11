//+------------------------------------------------------------------+
//|                                                        SetUp.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\InProgress\MBTracker.mqh>

class SetUp
{
   protected:
      MBTracker* mMBT;
   
   public:
      virtual bool Check() { return false; }
};