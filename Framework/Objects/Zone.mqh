//+------------------------------------------------------------------+
//|                                                         Zone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\ZoneState.mqh>

class Zone : public ZoneState
{
   public:    
      // --- Constructor / Destructor --- 
      Zone(string symbol, int timeFrame, int type, int entryIndex, double entryPrice, int exitIndex, double exitPrice, bool allowWickBreaks);
     ~Zone();
     
     // --- Setters ---
     void WasRetrieved(bool wasRetrieved) { mWasRetrieved = wasRetrieved; }
     
     // --- Maintenance Methods ---
     void UpdateIndexes(int barIndex);
};

Zone::Zone(string symbol, int timeFrame, int type, int entryIndex, double entryPrice, int exitIndex, double exitPrice, bool allowWickBreaks)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   
   mType = type;
   
   mEntryIndex = entryIndex;
   mExitIndex = exitIndex;
   
   mEntryPrice = entryPrice;
   mExitPrice = exitPrice;
   
   mAllowWickBreaks = allowWickBreaks;
   mDrawn = false; 
   mWasRetrieved = false;
   
   mName = "Zone: " + IntegerToString(MathRand()) + ", Sym: " + mSymbol + ", TF: " + IntegerToString(mTimeFrame);
}

Zone::~Zone()
{
   ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);
}
// -------------- Maintenance Methods ---------------
void Zone::UpdateIndexes(int barIndex)
{
   mEntryIndex += barIndex;
   mExitIndex += barIndex;
}
