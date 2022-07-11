//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\InProgress\MBState.mqh>
#include <SummitCapital\InProgress\Zone.mqh>

class MB : public MBState
{         
   private:
      void InternalCheckAddZones(string symbol, int timeFrame, int startingIndex, int endingIndex, bool allowZoneMitigation);
      
   public:
      // --- Constructors / Destructors ----------
      MB(int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones);
      ~MB();
      
      // --- Maintenance Methods ---
      void UpdateIndexes(int barIndex);
      
      // ---- Adding Zones -------------
      void CheckAddZones(string symbol, int timeFrame, bool allowZoneMitigation);
      void CheckAddZonesAfterMBValidation(string symbol, int timeFrame, int barIndex, bool allowZoneMitigation);
      void AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice);
      
      // ----- Retrieving Zones --------
      bool GetUnretrievedZones(int mbOffset, ZoneState* &zoneStates[]);
};
// #############################################################
// ####################### Private Methods #####################
// #############################################################
// ------------- Helper Methods ---------------
// Checks for zones with imbalances after and adds them if they are not already added
// GOES LEFT TO RIGHT 
void MB::InternalCheckAddZones(string symbol, int timeFrame, int startingIndex, int endingIndex, bool allowZoneMitigation)
{
   bool prevImbalance = false;
   bool currentImbalance = false;
   
   int zoneCount = 0;
   
   if (mType == OP_BUY)
   {
      // only go from low -> current so that we only grab imbalances that are in the imbpulse that broke structure and not in the move down
      for (int i = startingIndex; i >= endingIndex; i--)
      {        
         // make sure imbalance is in current mb. This allows for imbalances after the MB was valdiated
         double imbalanceExit = iLow(symbol, timeFrame, iLowest(symbol, timeFrame, MODE_LOW, 2, i));
         currentImbalance = iHigh(symbol, timeFrame, i + 1) < iLow(symbol, timeFrame, i - 1) && imbalanceExit < iHigh(symbol, timeFrame, mStartIndex);
         
         if (currentImbalance && !prevImbalance)
         {
            double imbalanceEntry = iHigh(symbol, timeFrame, i + 1);
            double mitigatedZone = iLow(symbol, timeFrame, iLowest(symbol, timeFrame, MODE_LOW, i - endingIndex, endingIndex)) < imbalanceEntry;
            
            // only allow zones we haven't added yet and that follow the mitigation parameter
            if (zoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone))
            {
               int endIndex = mEndIndex <= i ? mEndIndex : i - 5;
               AddZone(i + 1, imbalanceEntry, endIndex, imbalanceExit);
            }
            
            zoneCount += 1;
         }
         
         prevImbalance = currentImbalance;          
      }
   }
   else if (mType == OP_SELL)
   {  
      // only go from high -> current so that we only grab imbalances that are in the impulse taht broke sructure and not in the move up
      for (int i = startingIndex; i >= endingIndex; i--)
      {
         // make sure imbalance is in current mb. This allows for imbalances after the MB was validated
         double imbalanceExit = iHigh(symbol, timeFrame, iHighest(symbol, timeFrame, MODE_HIGH, 2, i));
         currentImbalance = iLow(symbol, timeFrame, i +1) > iHigh(symbol, timeFrame, i - 1) && imbalanceExit > iLow(symbol, timeFrame, mStartIndex);
         
         if (currentImbalance && !prevImbalance)
         {
            double imbalanceEntry = iLow(symbol, timeFrame, i + 1);
            double mitigatedZone = iHigh(symbol, timeFrame, iHighest(symbol, timeFrame, MODE_HIGH, i - endingIndex, endingIndex)) > imbalanceEntry;
            
            // only allow zones we haven't added yet and that follow the mitigation parameter
            if (zoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone))
            {
               int endIndex = mEndIndex <= i ? mEndIndex : i - 5;
               AddZone(i + 1, imbalanceEntry, endIndex, imbalanceExit); 
            }
            
            zoneCount += 1;
         }
                
         prevImbalance = currentImbalance;
      }   
   }
}
// #############################################################
// ####################### Public Methods ######################
// #############################################################
// --------- Constructor / Destructor --------
MB::MB(int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones)
{
   mType = type;
   mStartIndex = startIndex;
   mEndIndex = endIndex;
   mHighIndex = highIndex;
   mLowIndex = lowIndex;
   
   mMaxZones = maxZones;
   mZoneCount = 0;
   mUnretrievedZoneCount = 0;
   
   mDrawn = false;
   
   ArrayResize(mZones, maxZones);
}

MB::~MB()
{
   ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);
   
   for (int i = 0; i < mZoneCount; i++)
   {
      delete mZones[i];
   }
}
// ------------- Maintenance Methods ---------------
void MB::UpdateIndexes(int barIndex)
{
   mStartIndex = mStartIndex + barIndex;
   mEndIndex = mEndIndex + barIndex;
   mHighIndex = mHighIndex + barIndex;
   mLowIndex = mLowIndex + barIndex;
   
   for (int i = 0; i < mZoneCount; i++)
   {
      mZones[i].UpdateIndexes(barIndex);
   }
}
// --------------- Adding Zones -------------------
// Checks for zones that are within the MB
void MB::CheckAddZones(string symbol, int timeFrame, bool allowZoneMitigation)
{
   int startIndex = mType == OP_BUY ? mLowIndex : mHighIndex;
   InternalCheckAddZones(symbol, timeFrame, startIndex, mEndIndex, allowZoneMitigation);
}
// Checks for  zones that occur after the MB
void MB::CheckAddZonesAfterMBValidation(string symbol, int timeFrame, int barIndex, bool allowZoneMitigation)
{
   InternalCheckAddZones(symbol, timeFrame, mEndIndex, barIndex, allowZoneMitigation);
}

// Add zones 
void MB::AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice)
{
   if (mZoneCount < mMaxZones)
   {
      Zone* zone = new Zone(mType, entryIndex, entryPrice, exitIndex, exitPrice, false);
      
      mZones[mZoneCount] = zone;
      
      mZoneCount += 1;
      mUnretrievedZoneCount += 1;
   }
}
// ----------------- Zone Retrieval --------------------------
// Casts all Unretireved zones to a ZoneState and returns them
bool MB::GetUnretrievedZones(int mbOffset, ZoneState* &zoneStates[])
{
   bool retrievedZones = false;
   for (int i = (mZoneCount - mUnretrievedZoneCount); i < mZoneCount; i++)
   {
      if (!mZones[i].WasRetrieved())
      {
         mZones[i].WasRetrieved(true);
         zoneStates[i + mbOffset] = mZones[i];
         
         retrievedZones = true;
      }
   }
   
   mUnretrievedZoneCount = 0;
   return retrievedZones;
}