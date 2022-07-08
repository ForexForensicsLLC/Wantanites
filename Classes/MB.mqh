//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapitalMT4\Classes\Zone.mqh>

class CMB
{
   private: 
      int mType;
      int mStartIndex;
      int mEndIndex;
      int mHighIndex;
      int mLowIndex;
      
      
      bool mDrawn;
      
      CZone* mZones[];
      
      int mMaxZones;
      int mZoneCount;
      
      bool mHasUnretrievedZones;
                  
   public:
      CMB(int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones);
      ~CMB();
      
      int Type() { return mType; }
      int StartIndex() { return mStartIndex; }
      int EndIndex() { return mEndIndex; }
      int HighIndex(){ return mHighIndex;}
      int LowIndex() { return mLowIndex; }
      
      bool HasUnretrievedZones() { return mHasUnretrievedZones; }
   
      string ToString();
      
      void AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice);
      void CheckAddZones(string mSymbol, int timeFrame, int barIndex, bool allowZoneMitigation);
      void GetUnretrievedZones(CZone &zones[]);
      
      void Draw(string symbol, int timeFrame);
      void DrawZones(string symbol, int timeFrame);
      
      void UpdateIndexes(int barIndex);
      
};

CMB::CMB(int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones)
{
   mType = type;
   mStartIndex = startIndex;
   mEndIndex = endIndex;
   mHighIndex = highIndex;
   mLowIndex = lowIndex;
   
   mMaxZones = maxZones;
   
   mDrawn = false;
   
   ArrayResize(mZones, maxZones);
}

CMB::~CMB()
{
   ObjectsDeleteAll(ChartID(), "MB", 0, OBJ_RECTANGLE);
   
   for (int i = 0; i < mZoneCount; i++)
   {
      delete mZones[i];
   }
}

void CMB::AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice)
{
   if (mZoneCount < mMaxZones)
   {
      CZone* zone = new CZone(mType, entryIndex, entryPrice, exitIndex, exitPrice);
      
      mZones[mZoneCount] = zone;
      mZoneCount += 1;
   }
   
   mHasUnretrievedZones = true;
}

// Finds all zones with imbalances before them from startIndex -> endIndex
// GOES LEFT TO RIGHT 
void CMB::CheckAddZones(string symbol, int timeFrame, int barIndex, bool allowZoneMitigation)
{
   bool prevImbalance = false;
   bool currentImbalance = false;
   
   int zoneCount = 0;
   
   if (mType == OP_BUY)
   {
      // only go from low -> current so that we only grab imbalances that are in the imbpulse that broke structure and not in the move down
      for (int i = mLowIndex; i >= barIndex; i--)
      {        
         // make sure imbalance is in current mb. This allows for imbalances after the MB was valdiated
         double imbalanceExit = iLow(symbol, timeFrame, iLowest(symbol, timeFrame, MODE_LOW, 2, i));
         currentImbalance = iHigh(symbol, timeFrame, i + 1) < iLow(symbol, timeFrame, i - 1) && imbalanceExit < iHigh(symbol, timeFrame, mEndIndex);
         
         if (currentImbalance && !prevImbalance)
         {
            double imbalanceEntry = iHigh(symbol, timeFrame, i + 1);
            double mitigatedZone = iLow(symbol, timeFrame, iLowest(symbol, timeFrame, MODE_LOW, i - barIndex, barIndex)) < imbalanceEntry;
            
            // only allow zones we haven't added yet and that follow the mitigation parameter
            if (zoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone))
            {
               AddZone(i + 1, imbalanceEntry, mEndIndex, imbalanceExit);
            }
            
            zoneCount += 1;
         }
         
         prevImbalance = currentImbalance;          
      }
   }
   else if (mType == OP_SELL)
   {  
      // only go from high -> current so that we only grab imbalances that are in the impulse taht broke sructure and not in the move up
      for (int i = mHighIndex; i >= barIndex; i--)
      {
         // make sure imbalance is in current mb. This allows for imbalances after the MB was validated
         double imbalanceExit = iHigh(symbol, timeFrame, iHighest(symbol, timeFrame, MODE_HIGH, 2, i));
         currentImbalance = iLow(symbol, timeFrame, i +1) > iHigh(symbol, timeFrame, i - 1) && imbalanceExit > iLow(symbol, timeFrame, mEndIndex);
         
         if (currentImbalance && !prevImbalance)
         {
            double imbalanceEntry = iLow(symbol, timeFrame, i + 1);
            double mitigatedZone = iHigh(symbol, timeFrame, iHighest(symbol, timeFrame, MODE_HIGH, i - barIndex, barIndex)) > imbalanceEntry;
            
            // only allow zones we haven't added yet and that follow the mitigation parameter
            if (zoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone))
            {
               AddZone(i + 1, imbalanceEntry, mEndIndex, imbalanceExit); 
            }
            
            zoneCount += 1;
         }
                
         prevImbalance = currentImbalance;
      }   
   }
}

void CMB::GetUnretrievedZones(CZone &zones[])
{
   for (int i = 0; i <= mZoneCount - 1; i++)
   {
      if (!mZones[i].WasRetrieved)
      {
         mZones[i].WasRetrieved = true;
         zones[i] = mZones[i];
      }
   }
   
   mHasUnretrievedZones = false;
}

string CMB::ToString()
{
   return "Type: " + ", Start Index: " + mStartIndex + ", End Index: " + mEndIndex + ", High Index: " + mHighIndex + ", Low Index: " + mLowIndex;
}

void CMB::Draw(string symbol, int timeFrame)
{
   if (mDrawn)
   {
      return;
   }
   
   color clr = mType == OP_BUY ? clrLimeGreen : clrRed;  
   string name = "MB - Type: " + mType + ", Start Price: " + mStartIndex + ", End: " + mEndIndex + ", High: " + mHighIndex + ", Low: " + mLowIndex;
   
   if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, iTime(symbol, timeFrame, mStartIndex), iHigh(symbol, timeFrame, mHighIndex), 
      iTime(symbol, timeFrame, mEndIndex), iLow(symbol, timeFrame, mLowIndex)))
   {
      Print("Object Creation Failed: ", GetLastError());
      return;
   }
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_FILL, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);    
   
   mDrawn = true;

}

void CMB::DrawZones(string symbol, int timeFrame)
{
   for (int i = 0; i < mZoneCount; i++)
   {
      mZones[i].Draw(symbol, timeFrame);
   }
}

void CMB::UpdateIndexes(int barIndex)
{
   mStartIndex = mStartIndex + barIndex;
   mEndIndex = mEndIndex + barIndex;
   mHighIndex = mHighIndex + barIndex;
   mLowIndex = mLowIndex + barIndex;
}