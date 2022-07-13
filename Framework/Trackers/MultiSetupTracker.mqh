//+------------------------------------------------------------------+
//|                                                 SetUpWatcher.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\SetUp.mqh>
#include <SummitCapital\Framework\Objects\OrderPlacer.mqh>

class MultiSetupTracker
{
   typedef bool (*TValidZoneRetrieverFunc)(MBTracker* &mbt, ZoneState* &zoneStates[]);
   typedef bool (*TConfirmationFunc)(MBTracker* &mbt);
   
   private:    
      int mTotalSetUps; 
      
      MBTracker* mMBTrackers[];
      SetUp* mSetUps[];
      OrderPlacer* mOrderPlacer;
     
      TValidZoneRetrieverFunc mGetValidZones[];     
      TConfirmationFunc mFinalConfirmation;
        
   public:
      MultiSetupTracker(TConfirmationFunc finalConfirmationFunc, OrderPlacer* &orderPlacer);
      ~MultiSetupTracker();
      
      void AddSetUp(MBTracker* &mbt, SetUp* &setUp, TValidZoneRetrieverFunc validZoneRetrieverFunc);      
      void Check();
};

MultiSetupTracker::MultiSetupTracker(TConfirmationFunc finalConfiramtionFunc, OrderPlacer* &orderPlacer)
{
   mTotalSetUps = 0;
   
   ArrayResize(mMBTrackers, 1);
   ArrayResize(mSetUps, 1);
   ArrayResize(mGetValidZones, 1);
   
   mFinalConfirmation = finalConfiramtionFunc;
   mOrderPlacer = orderPlacer;
}

MultiSetupTracker::~MultiSetupTracker()
{
}

void MultiSetupTracker::AddSetUp(MBTracker *&mbt, SetUp* &setUp, TValidZoneRetrieverFunc validZoneRetrieverFunc)
{
   if (ArraySize(mMBTrackers) < mTotalSetUps)
   {
      ArrayResize(mMBTrackers, mTotalSetUps + 1);
      ArrayResize(mSetUps, mTotalSetUps + 1);
      ArrayResize(mGetValidZones, mTotalSetUps + 1);
   }
   
   mMBTrackers[mTotalSetUps] = mbt;
   mSetUps[mTotalSetUps] = setUp;
   mGetValidZones[mTotalSetUps] = validZoneRetrieverFunc;
   
   mTotalSetUps += 1;
}

void MultiSetupTracker::Check()
{
   /* TODO
   if (OrdersTotal() > 0)
   {
      mBreakEven.Check();
   }
   */
   
   for (int i = 0; i < mTotalSetUps; i++)
   {
      if (!mSetUps[i].Check(mMBTrackers[i]))
      {
         return;
      }
      
      ZoneState* zoneStates[];
      if (!mGetValidZones[i](mMBTrackers[i], zoneStates))
      {
         return;
      }
      
      if (i == mTotalSetUps - 1 && mFinalConfirmation(mMBTrackers[i]))
      {
         mOrderPlacer.PlaceOrders(mMBTrackers, zoneStates);
      }
   }
}