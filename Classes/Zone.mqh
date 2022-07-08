//+------------------------------------------------------------------+
//|                                                         Zone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class CZone
{
   private: 
      int mType;
      
      int mEntryIndex;
      int mExitIndex;
      
      double mEntryPrice;
      double mExitPrice;
      
      bool mDrawn;

   public:
      int Type() { return mType; }
      
      int EntryIndex() { return mEntryIndex; }
      int ExitIndex() { return mExitIndex; }
      
      double EntryPrice() { return mEntryPrice; }
      double ExitPrice() { return mExitPrice; }
      double WasRetrieved;
      
      CZone(int type, int entryIndex, double entryPrice, int exitIndex, double exitPrice);
     ~CZone();
     
     void Draw(string symbol, int timeFrame);
};

CZone::CZone(int type, int entryIndex, double entryPrice, int exitIndex, double exitPrice)
{
   mType = type;
   mEntryIndex = entryIndex;
   mExitIndex = exitIndex;
   
   mEntryPrice = entryPrice;
   mExitPrice = exitPrice;
   
   mDrawn = false;
   
   WasRetrieved = false;
}

CZone::~CZone()
{
   ObjectsDeleteAll(ChartID(), "Zone", 0, OBJ_RECTANGLE);
}

void CZone::Draw(string symbol, int timeFrame)
{
   if (mDrawn)
   {
      return;
   }
   // color chartBackground=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
   // color front = mType == OP_BUY ? clrLimeGreen : clrRed;
   
   color clr = mType == OP_BUY ? clrYellow : clrPurple;
   // clr ^= front;
   // clr ^= chartBackground;

   // color clr = mType == OP_BUY ? clrLimeGreen : clrRed;  
   string name = "Zone - Entry Index: " + mEntryIndex + ", Entry Price: " + mEntryPrice + "Exit Index: " + mExitIndex +  ", Exit Price: " + mExitPrice;
   
   if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, iTime(symbol, timeFrame, mEntryIndex), mEntryPrice, 
         iTime(symbol, timeFrame, mExitIndex), mExitPrice))
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