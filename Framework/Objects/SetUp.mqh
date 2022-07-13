//+------------------------------------------------------------------+
//|                                                        SetUp.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\SetUpHelper.mqh>

typedef bool (*TSetUp)(MBTracker* &mbt);
typedef bool (*TGetSetUpEndingMB)(MBTracker* &mbt, MBState* &mbState);

class SetUp
{  
   protected:
      bool mInSetUp;
      MBState* mSetUpRangeEndMB;
      
      TGetSetUpEndingMB GetSetUpEndingMB;
      TSetUp IsValid;
      TSetUp IsInvalid;
      
   public:
      bool InSetUp() { return mInSetUp; } 
      
      SetUp(TSetUp isValid, TSetUp isInvalid, TGetSetUpEndingMB getSetUpEndingMB);
      
      bool Check(MBTracker* &mbt);
};

SetUp::SetUp(TSetUp isValid,TSetUp isInvalid, TGetSetUpEndingMB getSetUpEndingMB)
{
   IsValid = isValid;
   IsInvalid = isInvalid;
   GetSetUpEndingMB = getSetUpEndingMB;
}

bool SetUp::Check(MBTracker* &mbt)
{
   if (!mInSetUp && IsValid(mbt))
   {
      mInSetUp = true;     
      GetSetUpEndingMB(mbt, mSetUpRangeEndMB);
   }
   else if (mInSetUp) 
   {   
      bool invalidateSetUp = IsInvalid(mbt) || SetUpHelper::BrokeRange(mSetUpRangeEndMB);
      if (invalidateSetUp)
      {
         mInSetUp = false;
         mSetUpRangeEndMB = NULL;
      }
   }
   
   return mInSetUp;
}