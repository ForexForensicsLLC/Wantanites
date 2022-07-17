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

typedef int (*TMBSetUpFunc)(MBTracker* &mbt);
typedef double (*TMBSetUpRangeStartFunc)(MBTracker* &mbt);

class MBSetUp
{  
   private:
      string mSymbol;
      int mTimeFrame;
      
      bool mInSetUp;
      int mSetUpType; 
      double mSetUpStart;
      
      TMBSetUpFunc mIsValid;   
      TMBSetUpFunc mIsInvalid; 
      TMBSetUpRangeStartFunc mGetMBSetUpRangeStart;
      
      bool BrokeRange();
      
   public:
      bool InSetUp() { return mInSetUp; } 
      
      MBSetUp(TMBSetUpFunc isValid, TMBSetUpFunc isInvalid, TMBSetUpRangeStartFunc getSetUpRangeStart);
      ~MBSetUp();
      
      bool Check(MBTracker* &mbt);
};

MBSetUp::MBSetUp(TMBSetUpFunc isValid, TMBSetUpFunc isInvalid, TMBSetUpRangeStartFunc getSetUpRangeStart)
{
   mIsValid = isValid;
   mIsInvalid = isInvalid;
   mGetMBSetUpRangeStart = getSetUpRangeStart;
}

MBSetUp::~MBSetUp()
{
}

bool MBSetUp::Check(MBTracker* &mbt)
{
   if (!mInSetUp)
   {
      int tempSetUpType = mIsValid(mbt);
      if (tempSetUpType != -1)
      {
         mSetUpType = tempSetUpType;   
         mSetUpStart = mGetMBSetUpRangeStart(mbt);
         
         mInSetUp = true;  
      }
   }
   else
   {   
      bool invalidateSetUp = mIsInvalid(mbt) || BrokeRange();
      if (invalidateSetUp)
      {
         mSetUpType = -1;
         mSetUpStart = -1;
         
         mInSetUp = false;
      }
   }
   
   return mInSetUp;
}

bool MBSetUp::BrokeRange()
{  
   bool brokeBullishMB = mSetUpType == OP_BUY && iLow(mSymbol, mTimeFrame, 0) < mSetUpStart;
   bool brokeBearishMB = mSetUpType == OP_SELL && iHigh(mSymbol, mTimeFrame, 0) > mSetUpStart;
     
   return brokeBullishMB || brokeBearishMB;
}