//+------------------------------------------------------------------+
//|                                                    ZoneState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class ZoneState
{
   protected:
      int mType;
      
      int mEntryIndex;
      int mExitIndex;
      
      double mEntryPrice;
      double mExitPrice;
      
      bool mAllowWickBreaks;
      bool mIsBroken;
      bool mWasRetrieved;
      bool mDrawn;     
      string mName;
      
      bool BelowDemandZone(string symbol, int timeFrame, int barIndex);
      bool AboveSupplyZone(string symbol, int timeFrame, int barIndex);
   
   public:
      // --- Getters ---
      int Type() { return mType; }
      
      int EntryIndex() { return mEntryIndex; }
      int ExitIndex() { return mExitIndex; }
      
      double EntryPrice() { return mEntryPrice; }
      double ExitPrice() { return mExitPrice; }
    
      bool WasRetrieved() { return mWasRetrieved; }
      
      // --- Computed Properties ---
      double Range() { return MathAbs(mEntryPrice - mExitPrice); }
      bool IsHolding(string symbol, int timeFrame);
      bool IsBroken(string symbol, int timeFrame, int barIndex);
      
      // --- Display Methods ---
      string ToString();
      void Draw(string symbol, int timeFrame, bool printErrors);
};
bool ZoneState::BelowDemandZone(string symbol, int timeFrame, int barIndex)
{
   return (mAllowWickBreaks && MathMin(iOpen(symbol, timeFrame, barIndex), iClose(symbol, timeFrame, barIndex)) < mExitPrice) || (!mAllowWickBreaks && iLow(symbol, timeFrame, barIndex) < mExitPrice);
}

bool ZoneState::AboveSupplyZone(string symbol, int timeFrame, int barIndex)
{
   return (mAllowWickBreaks && MathMax(iOpen(symbol, timeFrame, barIndex), iClose(symbol, timeFrame, barIndex)) > mExitPrice) || (!mAllowWickBreaks && iHigh(symbol, timeFrame, barIndex) > mExitPrice);
}
// ----------------- Computed Properties ----------------------
// checks if price is  currenlty in the zone, and the zone is holding 
bool ZoneState::IsHolding(string symbol, int timeFrame)
{
   if (mType == OP_BUY)
   {
      return iLow(symbol, timeFrame, 0) < mEntryPrice && !BelowDemandZone(symbol, timeFrame, 0);
   }
   else if (mType == OP_SELL)
   {
      return iHigh(symbol, timeFrame, 0) > mEntryPrice && !AboveSupplyZone(symbol, timeFrame, 0);
   }
   
   return false;
}

// checks if a zone was broken from its entry index to barIndex
bool ZoneState::IsBroken(string symbol, int timeFrame, int barIndex)
{
   if (!mIsBroken)
   {
      if (mType == OP_BUY)
      {
         mIsBroken = BelowDemandZone(symbol, timeFrame, iLowest(symbol, timeFrame, MODE_LOW, mEntryIndex - barIndex, barIndex));
      }
      else if (mType == OP_SELL)
      {
         mIsBroken = AboveSupplyZone(symbol, timeFrame, iHighest(symbol, timeFrame, MODE_HIGH, mEntryIndex - barIndex, barIndex));
      }
   }
   
   return mIsBroken;
}

// ------------------- Display Methods ---------------------
// returns a string description about the zone
string ZoneState::ToString()
{
   return "Zone - Entry: " + IntegerToString(mEntryIndex) + 
      ", Exit: " + IntegerToString(mExitIndex); 
}
// Draws the zone on the chart if it hasn't been drawn before
void ZoneState::Draw(string symbol, int timeFrame, bool printErrors)
{
   if (mDrawn)
   {
      return;
   }
   
   color clr = mType == OP_BUY ? clrGold : clrMediumVioletRed;
   string name = ToString();
   
   if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, 
         iTime(symbol, timeFrame, mEntryIndex), // Start
         mEntryPrice,                           // Entry 
         iTime(symbol, timeFrame, mExitIndex),  // End
         mExitPrice))                           // Exit
   {
      if (printErrors)
      {
         Print("Zone Object Creation Failed: ", GetLastError());
      }
      
      return;
   }
   
   mName = name;
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);    
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   mDrawn = true;
}