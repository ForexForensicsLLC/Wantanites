//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapital\InProgress\MB.mqh>

class MBTracker
{
   private:
      // --- Operation Variables --- 
      int mTimeFrame;
      string mSymbol;    
      int mPrevCalculated;
      datetime mFirstBarTime;
      bool mInitialLoad;
      
      // --- MB Counting --- 
      int mMBsToTrack;
      int mCurrentMBs;
      
      // --- Zone Counting ---
      int mMaxZonesInMB;
      bool mAllowZoneMitigation;
      
      // --- MB Structure Tracking ---      
      int mCurrentBullishRetracementIndex;
      int mCurrentBearishRetracementIndex;
      
      bool mPendingBullishMB;
      bool mPendingBearishMB;
      
      int mPendingBullishMBLowIndex;
      int mPendingBearishMBHighIndex;
      
      MB* mMBs[];
      
      // --- Methods
      void Update();
      
      void CalculateMB(int barIndex);
      void CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex);
      
      void CheckSetRetracement(int startingIndex, int mbType, int prevMBType);
      void CheckSetPendingMB(int startingIndex, int mbType);
      
      void ResetTracking();
     

   public:
      MBTracker();
      MBTracker(int mbsToTrack, int maxZonesInMB, bool allowZoneMitigatino);
      MBTracker(string symbol, int timeFrame, int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation);
      
      ~MBTracker();
      
      void init(string symbol, int timeFrame, int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation);     
      void UpdateIndexes(int barIndex);
      
      void PrintMBs(int mostRecentMBsToPrint);     
      void DrawMBs(int mostRecentMBsToDraw);
      void DrawZones(int mostRecentMBsToDrawZonesFor);
      
      bool GetUnretrievedZonesForNthMostRecentMB(int nthMostRecentMB, int currentBarIndex, Zone* &zones[]);
      
      bool HasMostRecentConsecutiveMBs(int numberOfMostRecentConsecutiveMBs);
      bool HasMostRecentConsecutiveMBs(int numberOfMostRecentConsecutiveMBs, MB* &mbs[]);
      
      bool IsOppositeMB(int nthMostRecentMB);
      bool IsOppositeMB(int nthMostRecentMB, MB* &mb[]);
};

MBTracker::MBTracker()
{
   init(Symbol(), 0, 3, 5, false);
}

MBTracker::MBTracker(int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation)
{
   init(Symbol(), 0, mbsToTrack, maxZonesInMB, allowZoneMitigation);
}

MBTracker::MBTracker(string symbol, int timeFrame,int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation)
{
   init(symbol, timeFrame, mbsToTrack, maxZonesInMB, allowZoneMitigation);
}

MBTracker::~MBTracker()
{
   for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
   {
      delete mMBs[i];
   }  
}

void MBTracker::init(string symbol, int timeFrame, int mbsToTrack, int maxZonesInMB, bool allowZoneMitigation)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   mPrevCalculated = 0;
   mFirstBarTime = 0;
   mInitialLoad = true;
   
   mMBsToTrack = mbsToTrack;
   mMaxZonesInMB = maxZonesInMB;
   mAllowZoneMitigation = allowZoneMitigation;
   
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
   
   // force recalculation of current bar
   /*
   if (mPrevCalculated > 0)
   {
      limit++;
   }
   */
   
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
   else if (mMBs[mMBsToTrack - mCurrentMBs].Type() == OP_BUY)
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
   }
   // prev mb was bearish
   else if (mMBs[mMBsToTrack - mCurrentMBs].Type() == OP_SELL)
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
        
        MB* mb = new MB(mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB);
        mb.CheckAddZones(mSymbol, mTimeFrame, endIndex, mAllowZoneMitigation);       
        mMBs[0] = mb;
    }
    else
    {
        MB* mb = new MB(mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB);
        
        mb.CheckAddZones(mSymbol, mTimeFrame, endIndex, mAllowZoneMitigation);
        mMBs[(mMBsToTrack - 1) - mCurrentMBs] = mb;
        
        mCurrentMBs += 1;
    }
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

bool MBTracker::GetUnretrievedZonesForNthMostRecentMB(int nthMostRecentMB, int currentBarIndex, Zone* &zones[])
{
   Update();
   
   bool retrievedNewZones = false;
   if (nthMostRecentMB > mCurrentMBs)
   {
      Print("Can't get zones for MB: ", nthMostRecentMB, ", Total MBs: ", mCurrentMBs);
      return false;
   }
   
   int i = (mMBsToTrack - mCurrentMBs) + nthMostRecentMB - 1;
   
   // only allow the most recent MB to have zones after it has been validated if there is no pending MB 
   if (i == (mMBsToTrack - mCurrentMBs) && !mPendingBullishMB && !mPendingBearishMB)
   {
      mMBs[i].CheckAddZones(mSymbol, mTimeFrame, currentBarIndex, mAllowZoneMitigation);
   }

   if (mMBs[i].HasUnretrievedZones())
   {
      mMBs[i].GetUnretrievedZones(zones);
      retrievedNewZones = true;
   }
   
   
   return retrievedNewZones;
}

void MBTracker::PrintMBs(int mostRecentMBsToPrint)
{
   Update();
   
   if (mostRecentMBsToPrint == -1 || mostRecentMBsToPrint > mCurrentMBs)
   {
      mostRecentMBsToPrint = mCurrentMBs;
   }
   
   for (int i = (mMBsToTrack - mostRecentMBsToPrint); i < (mMBsToTrack - mCurrentMBs) + mostRecentMBsToPrint; i++)
   {
      Print(mMBs[i].ToString());
   } 
}

void MBTracker::DrawMBs(int mostRecentMBsToDraw)
{
   Update();
   
   if (mostRecentMBsToDraw == -1 || mostRecentMBsToDraw > mCurrentMBs)
   {
      mostRecentMBsToDraw = mCurrentMBs;
   }
   
   for (int i = (mMBsToTrack - mCurrentMBs); i < (mMBsToTrack - mCurrentMBs) + mostRecentMBsToDraw; i++)
   {
      mMBs[i].Draw(mSymbol, mTimeFrame);     
   } 
}

void MBTracker::DrawZones(int mostRecentMBsToDrawZonesFor)
{
   Update();
   
   if (mostRecentMBsToDrawZonesFor == -1 || mostRecentMBsToDrawZonesFor > mCurrentMBs)
   {
      mostRecentMBsToDrawZonesFor = mCurrentMBs;
   }
   
   for (int i = (mMBsToTrack - mCurrentMBs); i < (mMBsToTrack - mCurrentMBs) + mostRecentMBsToDrawZonesFor; i++)
   {
      mMBs[i].DrawZones(mSymbol, mTimeFrame);
   } 
}

bool MBTracker::HasMostRecentConsecutiveMBs(int numberOfMostRecentConsecutiveMBs)
{
   MB* tempMBs[];
   ArrayResize(tempMBs, numberOfMostRecentConsecutiveMBs);
   
   return HasMostRecentConsecutiveMBs(numberOfMostRecentConsecutiveMBs, tempMBs);
}

// Checks for n most recent mbs of the same type
bool MBTracker::HasMostRecentConsecutiveMBs(int numberOfMostRecentConsecutiveMBs, MB* &mbs[])
{
   Update();
   
   if (numberOfMostRecentConsecutiveMBs > ArraySize(mbs))
   {
      Print("Can't look for more MBs than array parameter can hold");
      return false;
   }
   
   if (numberOfMostRecentConsecutiveMBs > mCurrentMBs)
   {
      Print("Looking for more consecutive MBs than there are MBs");
      return false;
   }
   
   int mbType;
   MB* tempMBs[];
   ArrayResize(tempMBs, ArraySize(mbs));
   
   for (int i = 0; i > numberOfMostRecentConsecutiveMBs; i++)
   {
      if (i == 0)
      {
         mbType = mMBs[mMBsToTrack - mCurrentMBs + i].Type();       
      }
      else
      {
         if (mbType != mMBs[mMBsToTrack - mCurrentMBs + i].Type())
         {
            return false;
         }
         
         tempMBs[i] = mMBs[mMBsToTrack - mCurrentMBs + i];
      }
   }
   
   ArrayCopy(mbs, tempMBs, 0, 0, WHOLE_ARRAY);
   return true;
}

bool MBTracker::IsOppositeMB(int nthMostRecentMB)
{
   MB* tempMBs[];
   ArrayResize(tempMBs, 1);
   
   return IsOppositeMB(nthMostRecentMB , tempMBs);
}

// checks if the nth most recent MB is of opposite type than the one before it
bool MBTracker::IsOppositeMB(int nthMostRecentMB, MB* &mb[])
{
   Update();
   
   int i = (mMBsToTrack - mCurrentMBs) + nthMostRecentMB - 1;
     
   if (i < mMBsToTrack && mMBs[i].Type() != mMBs[i + 1].Type())
   {
      mb[0] = mMBs[i];
      return true;
   }
   
   return false;
}