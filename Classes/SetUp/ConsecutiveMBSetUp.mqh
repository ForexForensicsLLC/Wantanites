//+------------------------------------------------------------------+
//|                                           ConsecutiveMBSetUp.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\InProgress\SetUp.mqh>

class ConsecutiveMBSetUp : public SetUp
{
   private:
      int mNConsecutiveMBs;
   
   public:
      ConsecutiveMBSetUp(MBTracker &mbt, int nConsecutiveMBs);
      ~ConsecutiveMBSetUp();
};

ConsecutiveMBSetUp::ConsecutiveMBSetUp(MBTracker &mbt, int nConsecutiveMBs)
{
   mMBT = mbt;
   mNConsecutiveMBs = nConsecutiveMBs;
}

ConsecutiveMBSetUp::~ConsecutiveMBSetUp()
{
}

virtual bool ConsecutiveMBSetUp::Check()
{
   return mMBT.HasNMostRecentConsecutiveMBs(mNConsecutiveMBs);
}
