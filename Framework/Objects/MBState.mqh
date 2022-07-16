//+------------------------------------------------------------------+
//|                                                      MBState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\Zone.mqh>

class MBState
{
   protected:
      string mSymbol;
      int mTimeFrame;
      
      int mNumber;
      int mType;
      int mStartIndex;
      int mEndIndex;
      int mHighIndex;
      int mLowIndex;
      
      bool mDrawn;
      
      Zone* mZones[];
      int mMaxZones;
      int mZoneCount;
      int mUnretrievedZoneCount;
      
      string mName;

   public:
      // ------------- Getters --------------
      string Symbol() { return mSymbol; }
      int TimeFrame() { return mTimeFrame; }
      int Number() { return mNumber; }
      int Type() { return mType; }
      int StartIndex() { return mStartIndex; }
      int EndIndex() { return mEndIndex; }
      int HighIndex(){ return mHighIndex;}
      int LowIndex() { return mLowIndex; }
      
      int ZoneCount() { return mZoneCount; }
      int UnretrievedZoneCount() { return mUnretrievedZoneCount; }
   
      // --------- Display Methods ---------
      string ToString();
      void Draw(bool printErrors);
      void DrawZones(bool printErrors);
};

// ---------------- Display Methods -------------------
// returns a string description of the MB
string MBState::ToString()
{
   return "MB - TF: " + IntegerToString(mTimeFrame) + 
      ", Type: " + IntegerToString(mType) + 
      ", Start: " + IntegerToString(mStartIndex) + 
      ", End: " + IntegerToString(mEndIndex) + 
      ", High: " + IntegerToString(mHighIndex) + 
      ", Low: " + IntegerToString(mLowIndex);
}
// Draws the current MB if it hasn't been drawn before
void MBState::Draw(bool printErrors)
{
   if (mDrawn)
   {
      return;
   }
   
   color clr = mType == OP_BUY ? clrLimeGreen : clrRed;  
   
   if (!ObjectCreate(0, mName, OBJ_RECTANGLE, 0, 
      iTime(mSymbol, mTimeFrame, mStartIndex), // Start 
      iHigh(mSymbol, mTimeFrame, mHighIndex),  // High
      iTime(mSymbol, mTimeFrame, mEndIndex),   // End
      iLow(mSymbol, mTimeFrame, mLowIndex)))  // Low
   {
      if (printErrors)
      {
         Print("MB Object Creation Failed: ", GetLastError());
      }
      
      return;
   }
   
   ObjectSetInteger(0, mName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, mName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, mName, OBJPROP_BACK, false);
   ObjectSetInteger(0, mName, OBJPROP_FILL, false);
   ObjectSetInteger(0, mName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, mName, OBJPROP_SELECTABLE, false);    
   
   mDrawn = true;
}

void MBState::DrawZones(bool printErrors)
{
   for (int i = 0; i < mZoneCount; i++)
   {
      mZones[i].Draw(printErrors);
   }
}
