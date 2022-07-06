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
      
      CZone* mZones[];
      int mZoneCount;
      
      bool mHasUnretrievedZones;
                  
   public:
      CMB(int type, int startIndex, int endIndex, int highIndex, int lowIndex);
      ~CMB();
      
      int Type() { return mType; }
      int StartIndex() { return mStartIndex; }
      int EndIndex() { return mEndIndex; }
      int HighIndex(){ return mHighIndex;}
      int LowIndex() { return mLowIndex; }
      
      bool HasUnretrievedZones() { return mHasUnretrievedZones; }
   
      void AddZone(double open, double close);
      void GetUnretrievedZones(CZone &zones[]);
      
};

CMB::CMB(int type, int startIndex, int endIndex, int highIndex, int lowIndex)
{
   mType = type;
   mStartIndex = startIndex;
   mEndIndex = endIndex;
   mHighIndex = highIndex;
   mLowIndex = lowIndex;
}

CMB::~CMB()
{
}

void CMB::AddZone(double open, double close)
{
   CZone* zone = new CZone(open, close);
   mZones[mZoneCount] = zone;
   mZoneCount += 1;
   
   mHasUnretrievedZones = true;
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