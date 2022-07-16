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
      string mSymbol;
      int mTimeFrame;
      
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
      
      bool BelowDemandZone(int barIndex);
      bool AboveSupplyZone(int barIndex);
   
   public:
      // --- Getters ---
      string Symbol() { return mSymbol; }
      int TimeFrame() { return mTimeFrame; }
      
      int Type() { return mType; }
      
      int EntryIndex() { return mEntryIndex; }
      int ExitIndex() { return mExitIndex; }
      
      double EntryPrice() { return mEntryPrice; }
      double ExitPrice() { return mExitPrice; }
    
      bool WasRetrieved() { return mWasRetrieved; }
      
      // --- Computed Properties ---
      double Range() { return MathAbs(mEntryPrice - mExitPrice); }
      bool IsHolding();
      bool IsBroken(int barIndex);
      
      // --- Display Methods ---
      string ToString();
      void Draw(bool printErrors);
};
bool ZoneState::BelowDemandZone(int barIndex)
{
   return (mAllowWickBreaks && MathMin(iOpen(mSymbol, mTimeFrame, barIndex), iClose(mSymbol, mTimeFrame, barIndex)) < mExitPrice) || (!mAllowWickBreaks && iLow(mSymbol, mTimeFrame, barIndex) < mExitPrice);
}

bool ZoneState::AboveSupplyZone(int barIndex)
{
   return (mAllowWickBreaks && MathMax(iOpen(mSymbol, mTimeFrame, barIndex), iClose(mSymbol, mTimeFrame, barIndex)) > mExitPrice) || (!mAllowWickBreaks && iHigh(mSymbol, mTimeFrame, barIndex) > mExitPrice);
}
// ----------------- Computed Properties ----------------------
// checks if price is  currenlty in the zone, and the zone is holding 
bool ZoneState::IsHolding()
{
   if (mType == OP_BUY)
   {
      return iLow(mSymbol, mTimeFrame, 0) < mEntryPrice && !BelowDemandZone(0);
   }
   else if (mType == OP_SELL)
   {
      return iHigh(mSymbol, mTimeFrame, 0) > mEntryPrice && !AboveSupplyZone(0);
   }
   
   return false;
}

// checks if a zone was broken from its entry index to barIndex
bool ZoneState::IsBroken(int barIndex)
{
   if (!mIsBroken)
   {
      if (mType == OP_BUY)
      {
         mIsBroken = BelowDemandZone(iLowest(mSymbol, mTimeFrame, MODE_LOW, mEntryIndex - barIndex, barIndex));
      }
      else if (mType == OP_SELL)
      {
         mIsBroken = AboveSupplyZone(iHighest(mSymbol, mTimeFrame, MODE_HIGH, mEntryIndex - barIndex, barIndex));
      }
   }
   
   return mIsBroken;
}

// ------------------- Display Methods ---------------------
// returns a string description about the zone
string ZoneState::ToString()
{
   return "Zone - TF: " + IntegerToString(mTimeFrame) + 
      ", Entry: " + IntegerToString(mEntryIndex) + 
      ", Exit: " + IntegerToString(mExitIndex); 
}
// Draws the zone on the chart if it hasn't been drawn before
void ZoneState::Draw(bool printErrors)
{
   if (mDrawn)
   {
      return;
   }
   
   color clr = mType == OP_BUY ? clrGold : clrMediumVioletRed;
   
   if (!ObjectCreate(0, mName, OBJ_RECTANGLE, 0, 
         iTime(mSymbol, mTimeFrame, mEntryIndex), // Start
         mEntryPrice,                           // Entry 
         iTime(mSymbol, mTimeFrame, mExitIndex),  // End
         mExitPrice))                           // Exit
   {
      if (printErrors)
      {
         Print("Zone Object Creation Failed: ", GetLastError());
      }
      
      return;
   }
   
   ObjectSetInteger(0, mName, OBJPROP_COLOR, clr);    
   ObjectSetInteger(0, mName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, mName, OBJPROP_BACK, false);
   ObjectSetInteger(0, mName, OBJPROP_FILL, true);
   ObjectSetInteger(0, mName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, mName, OBJPROP_SELECTABLE, false);
   
   mDrawn = true;
}