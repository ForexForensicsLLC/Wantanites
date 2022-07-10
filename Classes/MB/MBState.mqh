//+------------------------------------------------------------------+
//|                                                      MBState.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\InProgress\Zone.mqh>

class MBState
{
   protected:
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

   public:
   /*
      MBState();
      ~MBState();
      */
   
      // ------------- Getters --------------
      int Type() { return mType; }
      int StartIndex() { return mStartIndex; }
      int EndIndex() { return mEndIndex; }
      int HighIndex(){ return mHighIndex;}
      int LowIndex() { return mLowIndex; }
      
      int ZoneCount() { return mZoneCount; }
      int UnretrievedZoneCount() { return mUnretrievedZoneCount; }
   
      // --------- Display Methods ---------
      string ToString();
      void Draw(string symbol, int timeFrame);
      void DrawZones(string symbol, int timeFrame);
};

/*
MBState::MBState()
{
}

MBState::~MBState()
{
}

*/

// ---------------- Display Methods -------------------
// returns a string description of the MB
string MBState::ToString()
{
   return "MB - Type: " + IntegerToString(mType) + 
      ", Start: " + IntegerToString(mStartIndex) + 
      ", End: " + IntegerToString(mEndIndex) + 
      ", High: " + IntegerToString(mHighIndex) + 
      ", Low: " + IntegerToString(mLowIndex);
}
// Draws the current MB if it hasn't been drawn before
void MBState::Draw(string symbol, int timeFrame)
{
   if (mDrawn)
   {
      return;
   }
   
   color clr = mType == OP_BUY ? clrLimeGreen : clrRed;  
   string name = ToString();
   
   if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, 
      iTime(symbol, timeFrame, mStartIndex), // Start 
      iHigh(symbol, timeFrame, mHighIndex),  // High
      iTime(symbol, timeFrame, mEndIndex),   // End
      iLow(symbol, timeFrame, mLowIndex)))  // Low
   {
      Print("MB Object Creation Failed: ", GetLastError());
      return;
   }
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_FILL, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);    
   
   mDrawn = true;
}

void MBState::DrawZones(string symbol, int timeFrame)
{
   for (int i = 0; i < mZoneCount; i++)
   {
      mZones[i].Draw(symbol, timeFrame);
   }
}
