//+------------------------------------------------------------------+
//|                                     ValidZoneRetrieverHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

class ValidZoneRetrievers
{
public:
   static bool MostRecentValidZoneInFirstMB(MBTracker* &mbt, ZoneState* &zoneStates[]);
   static bool MostRecentValidZoneInSecondMB(MBTracker* &mbt, ZoneState* &zoneStates[]);
   static bool MostRecentValidZoneInFirstOrSecondMB(MBTracker* &mbt, ZoneState* &zoneStates[]);
   
   static bool AllZonesInFirstOrSecondMB(MBTracker* &mbt, ZoneState* &zoneStates[]);
};

static bool ValidZoneRetrievers::MostRecentValidZoneInFirstMB(MBTracker* &mbt, ZoneState* &zoneStates[])
{
   return mbt.GetNthMostRecentMBsClosestValidZone(1, zoneStates);
}

static bool ValidZoneRetrievers::MostRecentValidZoneInFirstOrSecondMB(MBTracker *&mbt,ZoneState *&zoneStates[])
{
   if (mbt.GetNthMostRecentMBsClosestValidZone(0, zoneStates))
   {
      return true;
   }
   else if (mbt.GetNthMostRecentMBsClosestValidZone(1, zoneStates))
   {
      return true;
   }
   
   return false;
}