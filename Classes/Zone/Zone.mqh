//+------------------------------------------------------------------+
//|                                                         Zone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\InProgress\ZoneState.mqh>

class Zone : public ZoneState
{
   public:    
      // --- Constructor / Destructor --- 
      Zone(int type, int entryIndex, double entryPrice, int exitIndex, double exitPrice);
     ~Zone();
     
     // --- Setters ---
     void WasRetrieved(bool wasRetrieved) { mWasRetrieved = wasRetrieved; }
     
     // --- Maintenance Methods ---
     void UpdateIndexes(int barIndex);
};

Zone::Zone(int type, int entryIndex, double entryPrice, int exitIndex, double exitPrice)
{
   mType = type;
   mEntryIndex = entryIndex;
   mExitIndex = exitIndex;
   
   mEntryPrice = entryPrice;
   mExitPrice = exitPrice;
   
   mDrawn = false; 
   mWasRetrieved = false;
}

Zone::~Zone()
{
   ObjectsDeleteAll(ChartID(), "Zone", 0, OBJ_RECTANGLE);
}
// -------------- Maintenance Methods ---------------
void Zone::UpdateIndexes(int barIndex)
{
   mEntryIndex += barIndex;
   mExitIndex += barIndex;
}
