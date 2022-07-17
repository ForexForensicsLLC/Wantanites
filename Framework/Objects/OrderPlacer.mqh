//+------------------------------------------------------------------+
//|                                                  TradePlacer.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class OrderPlacer
{ 
   typedef double (*TGetStopLossFunc)(ZoneState* &zoneState);                  // Functions that return the PRICE of the stop loss
   typedef bool (*TPlaceOrderFunc)(OrderPlacer &op, ZoneState* &zoneStates[]); // Functions that place the order(s)
   
   private:   
      int mPartialCount;
      
      int mMagicNumber;  
      double mRiskPercent;
      int mStopLossPaddingPips;
      int mSpreadPips;
      
      int mPartialRRs[];
      int mPartialPercents[];
      
      TDynamicPartialFunc mSetDynamicPartials;
      TPlaceOrderFunc mInternalPlaceOrder;
      
   public:
      int PartialCount() { return mPartialCount; }
      
      int MagicNumber() { return mMagicNumber; }
      double RiskPercent() { return mRiskPercent; }
      int StopLossPaddingPips() { return mStopLossPaddingPips; }
      int SpreadPips() { return mSpreadPips; }
      
      int PartialRRs(int i) { return mPartialRRs[i]; }
      int PartialPercents(int i) {return mPartialPercents[i]; }
      
      OrderPlacer(int magicNumber, double riskPercent, int stopLossPaddingPips, int spreadPips, TGetStopLossFunc getStopLossFunc, TPlaceOrderFunc placeOrderFunc);
      OrderPlacer(int magicNumber, double riskPercent, int stopLossPaddingPips, int spreadPips, TGetStopLossFunc getStopLossFunc, TPlaceOrderFunc placeOrderFunc, TDynamicPartialFunc dynamicPartialFunc);
      ~OrderPlacer();
      
      TGetStopLossFunc GetStopLoss;
      void AddPartial(int partialRR, int partialPercent);
      bool PlaceOrders(MBTracker* &mbTrackers[], ZoneState* &zoneStates[]);
};

OrderPlacer::OrderPlacer(int magicNumber, double riskPercent, int stopLossPaddingPips, int spreadPips, TGetStopLossFunc getStopLossFunc, TPlaceOrderFunc placeOrderFunc)
{
   mPartialCount = 0;
   
   mMagicNumber = magicNumber;
   mRiskPercent = riskPercent;
   mStopLossPaddingPips = stopLossPaddingPips;
   mSpreadPips = spreadPips;
   GetStopLoss = getStopLossFunc;
   
   ArrayResize(mPartialRRs, 1);
   ArrayResize(mPartialPercents, 1);
   
   mInternalPlaceOrder = placeOrderFunc;
}

OrderPlacer::OrderPlacer(int magicNumber, double riskPercent, int stopLossPaddingPips, int spreadPips, TGetStopLossFunc getStopLossFunc, TPlaceOrderFunc placeOrderFunc, TDynamicPartialFunc dynamicPartialFunc)
{
   mPartialCount = 0;
   
   mMagicNumber = magicNumber;
   mRiskPercent = riskPercent;
   mStopLossPaddingPips = stopLossPaddingPips;
   mSpreadPips = spreadPips;
   GetStopLoss = getStopLossFunc;
   
   ArrayResize(mPartialRRs, 1);
   ArrayResize(mPartialPercents, 1);
   
   mInternalPlaceOrder = placeOrderFunc;
   mSetDynamicPartials = dynamicPartialFunc;
}

OrderPlacer::~OrderPlacer()
{
}

void OrderPlacer::AddPartial(int partialRR, int partialPercent)
{
   if (ArraySize(mPartialRRs) == mPartialCount)
   {
      ArrayResize(mPartialRRs, mPartialCount + 1);
      ArrayResize(mPartialPercents, mPartialCount + 1);
   }
   
   mPartialRRs[mPartialCount] = partialRR;
   mPartialPercents[mPartialCount] = partialPercent;
   
   mPartialCount += 1;
}

bool OrderPlacer::PlaceOrders(MBTracker* &mbTrackers[], ZoneState* &zoneStates[])
{
   if (mSetDynamicPartials != NULL)
   {
      mSetDynamicPartials(GetPointer(this), mbTrackers);
   }
   
   for (int i = ArraySize(zoneStates) - 1; i >= 0; i--)
   {
      if (CheckPointer(zoneStates[i]) == POINTER_INVALID)
      {
         continue;
      }
      
      mInternalPlaceOrder(GetPointer(this), zoneStates);
   }
   
   return true;
}
