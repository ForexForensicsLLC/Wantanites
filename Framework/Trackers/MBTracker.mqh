//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\Framework\Objects\MB.mqh>

class MBTracker
{
   private:
      // --- Operation Variables --- 
      int mTimeFrame;
      string mSymbol;    
      int mPrevCalculated;
      datetime mFirstBarTime;
      bool mInitialLoad;
      bool mPrintErrors; // used to prevent printing errors on obj creation. Should be used on 1 second chart to save resources
      
      // --- MB Counting / Tracking--- 
      int mMBsToTrack;
      int mCurrentMBs;
      int mMBsCreated;
      
      int mCurrentBullishRetracementIndex;
      int mCurrentBearishRetracementIndex;
      
      bool mPendingBullishMB;
      bool mPendingBearishMB;
      
      int mPendingBullishMBLowIndex;
      int mPendingBearishMBHighIndex;
      
      // --- Zone Counting / Tracking---
      int mMaxZonesInMB;
      bool mAllowZoneMitigation;
      bool mAllowZonesAfterMBValidation;
      
      
      MB* mMBs[];
      
      // --- Tracking Methods --- 
      void init(string symbol, int timeFrame, int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool printErrors);  
      void Update();
      int MostRecentMBIndex() { return mMBsToTrack - mCurrentMBs; }
      
      // --- MB Creation Methods ---
      void CalculateMB(int barIndex);
      void CheckSetRetracement(int startingIndex, int mbType, int prevMBType);
      void CheckSetPendingMB(int startingIndex, int mbType);
      void CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex);    
      void ResetTracking();
      
      // --------- Helper Methods ----------------
      bool InternalHasNMostRecentConsecutiveMBs(int nMBs);
      bool InternalNthMostRecentMBIsOpposite(int nthMB);

   public:
      // --- Constructors / Destructors ---
      MBTracker();
      MBTracker(int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool printErrors);
      MBTracker(string symbol, int timeFrame, int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool printErrors);      
      ~MBTracker();
      
      // --- Maintenance Methods ---
      void UpdateIndexes(int barIndex);
      
      // --- MB Schematic Methods ---
      bool GetNthMostRecentMB(int nthMB, MBState* &mbState);
      bool HasNMostRecentConsecutiveMBs(int nMBs);
      bool HasNMostRecentConsecutiveMBs(int nMBs, MBState* &mbStates[]);
      
      bool NthMostRecentMBIsOpposite(int nthMB);
      bool NthMostRecentMBIsOpposite(int nthMB, MBState* &mbState[]);
        
      int NumberOfConsecutiveMBsBeforeNthMostRecent(int nthMB);
      
      // --- MB Display Methods ---
      void PrintNMostRecentMBs(int nMBs);     
      void DrawNMostRecentMBs(int nMBs);
      
      // --- Zone Retrieval Methods ---
      bool GetNthMostRecentMBsUnretrievedZones(int nthMB, ZoneState* &zoneState[]);
      bool GetNMostRecentMBsUnretrievedZones(int nMBs, ZoneState* &zoneStates[]);
      bool GetNthMostRecentMBsClosestValidZone(int nthMB, ZoneState* &zoneState[]);
      bool NthMostRecentMBsClosestValidZoneIsHolding(int nthMB, ZoneState* &zoneState[]);
      
      // -- Zone Display Methods -- 
      void DrawZonesForNMostRecentMBs(int nMBs);
};

// ##############################################################
// ####################### Private Methods ######################
// ##############################################################

//----------------------- Tracking Methods ----------------------
void MBTracker::init(string symbol, int timeFrame, int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool printErrors)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   mPrevCalculated = 0;
   mFirstBarTime = 0;
   mInitialLoad = true;
   mPrintErrors = printErrors;
   
   mMBsToTrack = mbsToTrack;
   mMaxZonesInMB = maxZonesInMB;
   mMBsCreated = 0;
   mAllowZoneMitigation = allowZoneMitigation;
   mAllowZonesAfterMBValidation = allowZonesAfterMBValidation;
   
   mCurrentBullishRetracementIndex = -1;
   mCurrentBearishRetracementIndex = -1;
   
   ArrayResize(mMBs, mbsToTrack);
   
   Update();
}

void MBTracker::Update()
{
   // how many bars are available to calcualte
   int bars = iBars(mSymbol, mTimeFrame);
   datetime firstBarTime = iTime(mSymbol, mTimeFrame, bars - 1);
   
   // how many bars to calculate
   int limit = bars - mPrevCalculated;
   
   if (!mInitialLoad && limit == 1)
   {
      UpdateIndexes(limit);
   }
   
   if (mFirstBarTime != firstBarTime)
   {
      Print("Not Equal Time");
      limit = bars;
      mFirstBarTime = firstBarTime;
   }
   
   // Calcualte MBs for each bar we have left
   for (int i = limit - 1; i >= 0; i--)
   {
      CalculateMB(i);
   }
   
   mPrevCalculated = bars;
   mInitialLoad = false;
}

//----------------------- MB Creation Methods ----------------------------
void MBTracker::CalculateMB(int barIndex)
{
   if (CheckPointer(mMBs[mMBsToTrack - 1]) == POINTER_INVALID)
   {
      CheckSetRetracement(barIndex, OP_BUY, -1);
      CheckSetPendingMB(barIndex, OP_BUY);
      
      CheckSetRetracement(barIndex, OP_SELL, -1);
      CheckSetPendingMB(barIndex, OP_SELL);
      
      // validated Bullish MB
      if (mPendingBullishMB && iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
      {
         CreateMB(OP_BUY, mCurrentBullishRetracementIndex, barIndex, mCurrentBullishRetracementIndex, mPendingBullishMBLowIndex);
         ResetTracking();
         return;
      }
      // validated Bearish MB
      else if (mPendingBearishMB && iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
      {
         CreateMB(OP_SELL, mCurrentBearishRetracementIndex, barIndex, mPendingBearishMBHighIndex, mCurrentBearishRetracementIndex);
         ResetTracking();
         return;
      }
   }
   // prev mb was bullish
   else if (mMBs[MostRecentMBIndex()].Type() == OP_BUY)
   {
      CheckSetRetracement(barIndex, OP_BUY, OP_BUY);
      CheckSetPendingMB(barIndex, OP_BUY);
      
      if (mPendingBullishMB)
      {
         // new bullish mb has been validated, create new one
         if (iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
         {
            CreateMB(OP_BUY, mCurrentBullishRetracementIndex, barIndex, mCurrentBullishRetracementIndex, mPendingBullishMBLowIndex);
            ResetTracking();
         }
         // previous bullish mb has been broken, create bearish MB
         else if (iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mMBs[mMBsToTrack - mCurrentMBs].LowIndex()))
         {
            int highestIndex = iHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBs[mMBsToTrack - mCurrentMBs].StartIndex() - barIndex, barIndex);
            CreateMB(OP_SELL, mMBs[mMBsToTrack - mCurrentMBs].LowIndex(), barIndex, highestIndex, mMBs[mMBsToTrack - mCurrentMBs].LowIndex());
            ResetTracking();
         }
      }
      // only allow the most recent MB to have zones after it has been validated if there is no pending MB 
      else if (mAllowZonesAfterMBValidation)
      {
         mMBs[MostRecentMBIndex()].CheckAddZonesAfterMBValidation(barIndex, mAllowZoneMitigation);
      }
   }
   // prev mb was bearish
   else if (mMBs[MostRecentMBIndex()].Type() == OP_SELL)
   {
      CheckSetRetracement(barIndex, OP_SELL, OP_SELL);
      CheckSetPendingMB(barIndex, OP_SELL);
      
      if (mPendingBearishMB)
      {
         // new bearish mb has been validated, create new one
         if  (iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
         {
            CreateMB(OP_SELL, mCurrentBearishRetracementIndex, barIndex, mPendingBearishMBHighIndex, mCurrentBearishRetracementIndex);
            ResetTracking();
         }
         // previous bearish mb has been broken, create bullish MB
         else if (iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mMBs[mMBsToTrack - mCurrentMBs].HighIndex()))
         {
            int lowestIndex = iLowest(mSymbol, mTimeFrame, MODE_LOW, mMBs[mMBsToTrack - mCurrentMBs].StartIndex() - barIndex, barIndex);
            CreateMB(OP_BUY, mMBs[mMBsToTrack - mCurrentMBs].HighIndex(), barIndex, mMBs[mMBsToTrack - mCurrentMBs].HighIndex(), lowestIndex);
            ResetTracking();
         }
      }
      // only allow the most recent MB to have zones after it has been validated if there is no pending MB 
      else if (mAllowZonesAfterMBValidation)
      {
         mMBs[MostRecentMBIndex()].CheckAddZonesAfterMBValidation(barIndex, mAllowZoneMitigation);
      }
   }
}

// Method that Checks for retracements
// Will set mCurrentBullishRetracementIndex or mCurrentBearishRetracementIndex if one is found
// Will reset mCurrentBullishRetracementIndex or mCurrentBearishRetracementIndex if they are invalidated
void MBTracker::CheckSetRetracement(int startingIndex, int mbType, int prevMBType)
{
   if (mbType == OP_BUY)
   {
      // candle that has a high that is lower than the one before it, bullish retracement started 
      if (mCurrentBullishRetracementIndex == -1 && iHigh(mSymbol, mTimeFrame, startingIndex) < iHigh(mSymbol, mTimeFrame, startingIndex + 1))
      {
         if (prevMBType == OP_BUY)
         {
            mCurrentBullishRetracementIndex = iHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBs[mMBsToTrack - mCurrentMBs].EndIndex() - startingIndex + 1, startingIndex);
         }
         else 
         {
            mCurrentBullishRetracementIndex = startingIndex;
         }
      }
      // bullish retracement invalidated
      else if (!mPendingBullishMB && mCurrentBullishRetracementIndex > -1 && iHigh(mSymbol, mTimeFrame, startingIndex) > iHigh(mSymbol, mTimeFrame, mCurrentBullishRetracementIndex))
      {
         mCurrentBullishRetracementIndex = -1;
      }
   }         
   else if (mbType == OP_SELL)
   {
      // candle that has a low that is higher than the one before it, bearish retraceemnt started
      if (mCurrentBearishRetracementIndex == -1 && iLow(mSymbol, mTimeFrame, startingIndex) > iLow(mSymbol, mTimeFrame, startingIndex + 1))
      {
         if (prevMBType == OP_SELL)
         {
            mCurrentBearishRetracementIndex = iLowest(mSymbol, mTimeFrame, MODE_LOW, mMBs[mMBsToTrack - mCurrentMBs].EndIndex() - startingIndex + 1, startingIndex);
         }
         else 
         {
            mCurrentBearishRetracementIndex = startingIndex;
         }
      }
      // bearish retracement invalidated
      else if (!mPendingBearishMB && mCurrentBearishRetracementIndex > -1 && iLow(mSymbol, mTimeFrame, startingIndex) < iLow(mSymbol, mTimeFrame, mCurrentBearishRetracementIndex))
      {
         mCurrentBearishRetracementIndex = -1;
      }
   }
}

// method that checks if the current retracement turns into a pending mb
void MBTracker::CheckSetPendingMB(int startingIndex, int mbType)
{
   if (mbType == OP_BUY && mCurrentBullishRetracementIndex > -1)
   {
      // if we already have a pending bullish mb, we just need to find the index of the lowest candle within it
      if (mPendingBullishMB)
      {
         mPendingBullishMBLowIndex = iLowest(mSymbol, mTimeFrame, MODE_LOW, mCurrentBullishRetracementIndex - startingIndex, startingIndex);
      }   
      // loop through each bar and check every bar before it up to the retracement start and see if there is one with a body further than our current
      else
      {
         for (int j = startingIndex; j <= mCurrentBullishRetracementIndex; j++)
         {
            for (int k = j; k <= mCurrentBullishRetracementIndex; k++)
            {
               if (MathMin(iOpen(mSymbol, mTimeFrame, j), iClose(mSymbol, mTimeFrame, j)) < iLow(mSymbol, mTimeFrame, k))
               {
                  mPendingBullishMB = true;
                  break;
               }   
            } 
            
            // can break out if we found one
            if (mPendingBullishMB)
            {
               break;
            }                
         }              
         // find index of lowest candle within pending mb
         if (mPendingBullishMB)
         {
            mPendingBullishMBLowIndex = iLowest(mSymbol, mTimeFrame, MODE_LOW, mCurrentBullishRetracementIndex - startingIndex, startingIndex);
         } 
      }      
   }         
   else if (mbType == OP_SELL && mCurrentBearishRetracementIndex > -1)
   {
      // if we already have a pending bearish mb, we just need to find the index of the highest candle within it
      if (mPendingBearishMB)
      {
         mPendingBearishMBHighIndex = iHighest(mSymbol, mTimeFrame, MODE_HIGH, mCurrentBearishRetracementIndex - startingIndex, startingIndex);
      }
      // loop through each bar and check every bar before it up to the retracement start and see if there is one with a body further than our current
      else
      {
         for (int j = startingIndex; j <= mCurrentBearishRetracementIndex; j++)
         {
            for (int k = j; k <= mCurrentBearishRetracementIndex; k++)
            {
               if (MathMax(iOpen(mSymbol, mTimeFrame, j), iClose(mSymbol, mTimeFrame, j)) > iHigh(mSymbol, mTimeFrame, k))
               {
                  mPendingBearishMB = true;
               }
            }
            
            // can break out if we found one
            if (mPendingBearishMB)
            {
               break;
            }
         }                 
         // find index of highest candle within pending mb
         if (mPendingBearishMB)
         {
            mPendingBearishMBHighIndex = iHighest(mSymbol, mTimeFrame, MODE_HIGH, mCurrentBearishRetracementIndex - startingIndex, startingIndex);
         }      
      }
   }
}

// method that create an mb
void MBTracker::CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex)
{
    if (mCurrentMBs == mMBsToTrack)
    {  
        delete mMBs[mMBsToTrack - 1];
        ArrayCopy(mMBs, mMBs, 1, 0, mMBsToTrack - 1);
        
        MB* mb = new MB(mSymbol, mTimeFrame, mMBsCreated, mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB);
        mb.CheckAddZones(mAllowZoneMitigation);       
        mMBs[0] = mb;
    }
    else
    {
        MB* mb = new MB(mSymbol, mTimeFrame, mMBsCreated, mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB);       
        mb.CheckAddZones(mAllowZoneMitigation);
        mMBs[(mMBsToTrack - 1) - mCurrentMBs] = mb;
        
        mCurrentMBs += 1;
    }
    
    mMBsCreated += 1;
}

// method that resets all tracking
void MBTracker::ResetTracking(void)
{
    mPendingBullishMB = false;
    mPendingBearishMB = false;

    mCurrentBullishRetracementIndex = -1;
    mCurrentBearishRetracementIndex = -1;

    mPendingBearishMBHighIndex = -1;
    mPendingBullishMBLowIndex = -1;
}

// --------------- Helper Methods ------------------------
bool MBTracker::InternalHasNMostRecentConsecutiveMBs(int nMBs)
{
   Update();
   
   if (nMBs > mCurrentMBs)
   {
      Print("Looking for more consecutive MBs, ", nMBs, ", than there are MBs, ", mCurrentMBs);
      return false;
   }
   
   int mbType = -1; 
   for (int i = 0; i < nMBs; i++)
   {
      if (i == 0)
      {
         mbType = mMBs[MostRecentMBIndex() + i].Type();       
      }
      else if (mbType != mMBs[MostRecentMBIndex() + i].Type())
      {
         return false;        
      }
   }
   
   return true;
}

// Checks if the nthMB is a differnt type than the one before it
bool MBTracker::InternalNthMostRecentMBIsOpposite(int nthMB)
{
   Update();
   
   if (nthMB >= mCurrentMBs - 1)
   {
      Print("Can't check MB before, ", nthMB, " MB. Total MBs, ", mMBsToTrack - 1);
      return false;
   }
   
   int i = MostRecentMBIndex() + nthMB;
   return mMBs[i].Type() != mMBs[i + 1].Type();
}
// ##############################################################
// ######################## Public Methods ######################
// ##############################################################

// -------------- Constructors / Destructors --------------------
MBTracker::MBTracker()
{
   init(Symbol(), 0, 100, 5, false, true, true);
}

MBTracker::MBTracker(int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool printErrors)
{
   init(Symbol(), 0, mbsToTrack, maxZonesInMB, allowZoneMitigation, allowZonesAfterMBValidation, printErrors);
}

MBTracker::MBTracker(string symbol, int timeFrame,int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation, bool allowZonesAfterMBValidation, bool printErrors)
{
   init(symbol, timeFrame, mbsToTrack, maxZonesInMB, allowZoneMitigation, allowZonesAfterMBValidation, printErrors);
}

MBTracker::~MBTracker()
{
   Print("Deint MBTracker");
   for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
   {
      delete mMBs[i];
   }  
}

// -------------- Maintenance Methods --------------------------
void MBTracker::UpdateIndexes(int barIndex)
{
   mCurrentBullishRetracementIndex = mCurrentBullishRetracementIndex > -1 ? mCurrentBullishRetracementIndex + barIndex : -1;
   mCurrentBearishRetracementIndex = mCurrentBearishRetracementIndex > -1 ? mCurrentBearishRetracementIndex + barIndex : -1;
   
   mPendingBullishMBLowIndex = mPendingBullishMBLowIndex > -1 ? mPendingBullishMBLowIndex + barIndex : -1;
   mPendingBearishMBHighIndex = mPendingBearishMBHighIndex > -1 ? mPendingBearishMBHighIndex + barIndex : -1;
   
   for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
   {
      mMBs[i].UpdateIndexes(barIndex);
   }
}

// -------------- MB Schematic Mehthods ---------------
bool MBTracker::GetNthMostRecentMB(int nthMB, MBState *&mbState)
{
   Update();
   
   if (nthMB > mCurrentMBs)
   {
      Print("Nth MB, ", nthMB, ", is further than current MBs, ", mCurrentMBs);
      return false;
   }
   
   mbState = mMBs[MostRecentMBIndex() + nthMB];
   return true;
}

bool MBTracker::HasNMostRecentConsecutiveMBs(int nMBs)
{
  return InternalHasNMostRecentConsecutiveMBs(nMBs);
}

bool MBTracker::HasNMostRecentConsecutiveMBs(int nMBs, MBState* &mbStates[])
{  
   if (nMBs < ArraySize(mbStates))
   {
      Print("Trying to retrieve more consecutive MBs, ", nMBs, ", than array can hold, ", ArraySize(mbStates));
      return false;
   }
   
   if (InternalHasNMostRecentConsecutiveMBs(nMBs))
   {
      for (int i = 0; i < nMBs; i++)
      {
         mbStates[i] = mMBs[MostRecentMBIndex() + i];
      }
      
      return true;
   }
   
   return false;
}

bool MBTracker::NthMostRecentMBIsOpposite(int nthMB)
{
   return InternalNthMostRecentMBIsOpposite(nthMB);
}

bool MBTracker::NthMostRecentMBIsOpposite(int nthMB, MBState* &mbState[])
{
   if(InternalNthMostRecentMBIsOpposite(nthMB))
   {
      mbState[0] = mMBs[MostRecentMBIndex() + nthMB];
      return true;
   }
   
   return false;
}
// Counts how many consecutive MBs of the same type occurred before the nthMB 
// <Param> nthMB: The index of the MB to start; exclusive <Param> 
int MBTracker::NumberOfConsecutiveMBsBeforeNthMostRecent(int nthMB)
{
   if (nthMB > mCurrentMBs)
   {
      Print("Can't check ", nthMB, " MBs Back. Current MBs ", mCurrentMBs);
      return 0;
   }
   
   Update();
   
   int count = 0;
   int type = -1;
   int startingIndex = MostRecentMBIndex() + nthMB + 1;
   
   for (int i = startingIndex; i <= mMBsToTrack - 1; i++)
   {
      if (i == startingIndex)
      {
         type = mMBs[i].Type();
      }  
      else 
      {
         if (type != mMBs[i].Type())
         {
            return count;
         }
      }
          
      count += 1;
   }
   
   return count;
}

// ---------------- MB Display Methods --------------
void MBTracker::PrintNMostRecentMBs(int n)
{
   Update();
   
   if (n == -1 || n > mCurrentMBs)
   {
      n = mCurrentMBs;
   }
   
   for (int i = (mMBsToTrack - n); i < MostRecentMBIndex() + n; i++)
   {
      Print(mMBs[i].ToString());
   } 
}

void MBTracker::DrawNMostRecentMBs(int n)
{
   Update();
   
   if (n == -1 || n > mCurrentMBs)
   {
      n = mCurrentMBs;
   }
   
   for (int i = MostRecentMBIndex(); i < MostRecentMBIndex() + n; i++)
   {
      mMBs[i].Draw(mPrintErrors);     
   } 
}

// ------------- Zone Retrieval ----------------
// Gets all unretrieved zones from the nth most recent MB
// will place them in the index at which they occured in the MB
bool MBTracker::GetNthMostRecentMBsUnretrievedZones(int nthMB, ZoneState *&zoneStates[])
{
   Update();
   
   if (nthMB >= mCurrentMBs)
   {
      Print("Can't get zones for MB: ", nthMB, ", Total MBs: ", mCurrentMBs);
      return false;
   }
   
   int i = MostRecentMBIndex() + nthMB - 1;
   
   if (mMBs[MostRecentMBIndex() + nthMB].UnretrievedZoneCount() > 0)
   {
      return mMBs[MostRecentMBIndex() + nthMB].GetUnretrievedZones(0, zoneStates);
   }
   
   return false;
}

// Gets the n most recent mbs unretrieved zones
// the first 0 -> mMaxZonesInMB zones will be for the first MB,
// then mMaxZonesInMB -> 2 * mMaxZonesInMB zones will be for the second MB,
// so on and so on
bool MBTracker::GetNMostRecentMBsUnretrievedZones(int nMBs, ZoneState* &zoneStates[])
{
   Update();
   
   if (nMBs > mCurrentMBs)
   {
      Print("Can't get ", nMBs, " MBs when there is only ", mCurrentMBs);
      return false;
   }
   
   if (ArraySize(zoneStates) < nMBs * mMaxZonesInMB)
   {
      Print("ZoneStates is not large enough to hold all possible zones");
      return false;
   }
   bool retrievedZones = false;
   for (int i = 0; i < nMBs; i++)
   {
      if (mMBs[MostRecentMBIndex() + i].UnretrievedZoneCount() > 0)
      {
         retrievedZones = mMBs[MostRecentMBIndex() + i].GetUnretrievedZones(i * mMaxZonesInMB, zoneStates);
      }
   }
   
   return retrievedZones;
}

bool MBTracker::GetNthMostRecentMBsClosestValidZone(int nthMB, ZoneState* &zoneState[])
{
   Update();
   
   if (nthMB >= mCurrentMBs)
   {
      Print("Can't get zone for MB: ", nthMB, ", Total MBs: ", mCurrentMBs);
      return false;
   }
   
   return mMBs[MostRecentMBIndex() + nthMB].GetClosestValidZone(zoneState);
}

bool MBTracker::NthMostRecentMBsClosestValidZoneIsHolding(int nthMB, ZoneState* &zoneState[])
{
   if (GetNthMostRecentMBsClosestValidZone(nthMB, zoneState))
   {
      return zoneState[0].IsHolding();
   }
   
   return false;
}

// ------------- Zone Display ----------------- 
void MBTracker::DrawZonesForNMostRecentMBs(int nMBs)
{
   Update();
   
   if (nMBs == -1 || nMBs > mCurrentMBs)
   {
      nMBs = mCurrentMBs;
   }
   
   for (int i = MostRecentMBIndex(); i < MostRecentMBIndex() + nMBs; i++)
   {
      mMBs[i].DrawZones(mPrintErrors);
   } 
}