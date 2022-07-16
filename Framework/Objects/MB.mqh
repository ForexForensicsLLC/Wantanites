//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\MBState.mqh>
#include <SummitCapital\Framework\Objects\Zone.mqh>

class MB : public MBState
{         
   private:
      void InternalCheckAddZones(int startingIndex, int endingIndex, bool allowZoneMitigation);
      
   public:
      // --- Constructors / Destructors ----------
      MB(string symbol, int timeFrame, int number, int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones);
      ~MB();
      
      // --- Maintenance Methods ---
      void UpdateIndexes(int barIndex);
      
      // ---- Adding Zones -------------
      void CheckAddZones(bool allowZoneMitigation);
      void CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation);
      void AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice);
      
      // ----- Retrieving Zones --------
      bool GetUnretrievedZones(int mbOffset, ZoneState* &zoneStates[]);
      bool GetClosestValidZone(ZoneState* &zoneStates[]);
};
// #############################################################
// ####################### Private Methods #####################
// #############################################################
// ------------- Helper Methods ---------------
// Checks for zones with imbalances after and adds them if they are not already added
// GOES LEFT TO RIGHT 
void MB::InternalCheckAddZones(int startingIndex, int endingIndex, bool allowZoneMitigation)
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
         double imbalanceExit = iLow(mSymbol, mTimeFrame, iLowest(mSymbol, mTimeFrame, MODE_LOW, 2, i));
         currentImbalance = iHigh(mSymbol, mTimeFrame, i + 1) < iLow(mSymbol, mTimeFrame, i - 1) && imbalanceExit < iHigh(mSymbol, mTimeFrame, mStartIndex);
         
         if (currentImbalance && !prevImbalance)
         {
            double imbalanceEntry = iHigh(mSymbol, mTimeFrame, i + 1);
            double mitigatedZone = iLow(mSymbol, mTimeFrame, iLowest(mSymbol, mTimeFrame, MODE_LOW, i - endingIndex, endingIndex)) < imbalanceEntry;
            
            // only allow zones we haven't added yet and that follow the mitigation parameter and that aren't single ticks
            if (zoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit)
            {
               // account for zones after the validaiton of an mb
               int endIndex = mEndIndex <= i ? mEndIndex : i;
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
         double imbalanceExit = iHigh(mSymbol, mTimeFrame, iHighest(mSymbol, mTimeFrame, MODE_HIGH, 2, i));
         currentImbalance = iLow(mSymbol, mTimeFrame, i + 1) > iHigh(mSymbol, mTimeFrame, i - 1) && imbalanceExit > iLow(mSymbol, mTimeFrame, mStartIndex);
         
         if (currentImbalance && !prevImbalance)
         {
            double imbalanceEntry = iLow(mSymbol, mTimeFrame, i + 1);
            double mitigatedZone = iHigh(mSymbol, mTimeFrame, iHighest(mSymbol, mTimeFrame, MODE_HIGH, i - endingIndex, endingIndex)) > imbalanceEntry;
            
            // only allow zones we haven't added yet and that follow the mitigation parameter and that arenen't single ticks
            if (zoneCount >= mZoneCount && (allowZoneMitigation || !mitigatedZone) && imbalanceEntry != imbalanceExit)
            {
               int endIndex = mEndIndex <= i ? mEndIndex : i;
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
MB::MB(string symbol, int timeFrame, int number, int type, int startIndex, int endIndex, int highIndex, int lowIndex, int maxZones)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   
   mNumber = number;
   mType = type;
   mStartIndex = startIndex;
   mEndIndex = endIndex;
   mHighIndex = highIndex;
   mLowIndex = lowIndex;
   
   mMaxZones = maxZones;
   mZoneCount = 0;
   mUnretrievedZoneCount = 0;
   
   mName = "MB: " + IntegerToString(number);
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
void MB::CheckAddZones(bool allowZoneMitigation)
{
   int startIndex = mType == OP_BUY ? mLowIndex : mHighIndex;
   InternalCheckAddZones(startIndex, mEndIndex, allowZoneMitigation);
}
// Checks for  zones that occur after the MB
void MB::CheckAddZonesAfterMBValidation(int barIndex, bool allowZoneMitigation)
{
   InternalCheckAddZones(mEndIndex, barIndex, allowZoneMitigation);
}

// Add zones 
void MB::AddZone(int entryIndex, double entryPrice, int exitIndex, double exitPrice)
{
   if (mZoneCount < mMaxZones)
   {
      Zone* zone = new Zone(mSymbol, mTimeFrame, mNumber, mZoneCount, mType, entryIndex, entryPrice, exitIndex, exitPrice, false);
      
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

bool MB::GetClosestValidZone(ZoneState* &zoneStates[])
{
   for (int i = mZoneCount - 1; i >= 0; i--)
   {
      if (CheckPointer(mZones[i]) != POINTER_INVALID && !mZones[i].IsBroken(0))
      {
         zoneStates[0] = mZones[i];
         return true;
      }
   }
   
   return false;
}