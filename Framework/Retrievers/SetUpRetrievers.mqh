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

class SetUpRetrievers
{
   public:    
      static bool DoubleMB(MBTracker* &mbt);
      static bool DoubleMBRangeEnd(MBTracker* &mbt, MBState* &mbState);
      
      static bool TripleMB(MBTracker* &mbt);
};

static bool SetUpRetrievers::DoubleMB(MBTracker *&mbt)
{
   return mbt.HasNMostRecentConsecutiveMBs(2);
}

static bool SetUpRetrievers::DoubleMBRangeEnd(MBTracker *&mbt, MBState* &mbState)
{
   return mbt.GetNthMostRecentMB(1, mbState); 
}

static bool SetUpRetrievers::TripleMB(MBTracker *&mbt)
{
   return mbt.HasNMostRecentConsecutiveMBs(3);
}