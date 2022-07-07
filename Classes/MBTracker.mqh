//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <SummitCapitalMT4\Classes\MB.mqh>

class CMBTracker
{
   private:
      // --- Operation Variables --- 
      ENUM_TIMEFRAMES mTimeFrame;
      string mSymbol;    
      int mPrevCalculated;
      datetime mFirstBarTime;
      
      // --- MB Counting --- 
      int mMBsToTrack;
      int mCurrentMBs;
      
      // --- Zone Counting ---
      int mMaxZonesInMB;
      
      // --- MB Structure Tracking ---      
      int mCurrentBullishRetracementIndex;
      int mCurrentBearishRetracementIndex;
      
      bool mPendingBullishMB;
      bool mPendingBearishMB;
      
      int mPendingBullishMBLowIndex;
      int mPendingBearishMBHighIndex;
      
      CMB* mMBs[];
      
      // --- Methods
      void Update();
      
      void CalculateMB(int barIndex);
      void CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex);
      
      void CheckSetRetracement(int startingIndex, int mbType, int prevMBType);
      void CheckSetPendingMB(int startingIndex, int mbType);
      
      void ResetTracking();
     

   public:
      CMBTracker();
      CMBTracker(string symbol, ENUM_TIMEFRAMES timeFrame, int mbsToTrack, int maxZonesInMB);
      
      ~CMBTracker();
      
      void init(string symbol, ENUM_TIMEFRAMES timeFrame, int mbsToTrack, int maxZonesInMB);     
      
      void PrintMBs(int mostRecentMBsToPrint);     
      void DrawMBs(int mostRecentMBsToDraw);
      void DrawZones(int mostRecentMBsToDrawZonesFor);
      
      void GetUnretrievedZonesInMBs(int mbStartingIndex, int mbEndingIndex, int barIndex, CZone &zones[]);
};

CMBTracker::CMBTracker()
{
   init(Symbol(), 0, 3, 5);
}

CMBTracker::CMBTracker(string symbol, ENUM_TIMEFRAMES timeFrame,int mbsToTrack, int maxZonesInMB)
{
   init(symbol, timeFrame, mbsToTrack, maxZonesInMB);
}

CMBTracker::~CMBTracker()
{
   for (int i = (mMBsToTrack - mCurrentMBs); i < mMBsToTrack; i++)
   {
      delete mMBs[i];
   }  
}

void CMBTracker::init(string symbol,ENUM_TIMEFRAMES timeFrame, int mbsToTrack, int maxZonesInMB)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   mPrevCalculated = 0;
   mFirstBarTime = 0;
   
   mMBsToTrack = mbsToTrack;
   mMaxZonesInMB = maxZonesInMB;
   
   mCurrentBullishRetracementIndex = -1;
   mCurrentBearishRetracementIndex = -1;
   
   ArrayResize(mMBs, mbsToTrack);
   
   Update();
}

void CMBTracker::Update()
{
   // how many bars are available to calcualte
   int bars = iBars(mSymbol, mTimeFrame);
   datetime firstBarTime = iTime(mSymbol, mTimeFrame, bars - 1);
   
   // how many bars to calculate
   int limit = bars - mPrevCalculated;
   
   // force recalculation of current bar
   if (mPrevCalculated > 0)
   {
      limit++;
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
}

void CMBTracker::CalculateMB(int barIndex)
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
void CMBTracker::CheckSetRetracement(int startingIndex, int mbType, int prevMBType)
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
void CMBTracker::CheckSetPendingMB(int startingIndex, int mbType)
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
void CMBTracker::CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex)
{
    if (mCurrentMBs == mMBsToTrack)
    {  
        ArrayCopy(mMBs, mMBs, 0, 1, mMBsToTrack - 1);
        
        CMB* mb = new CMB(mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB);
        mb.CheckAddZones(mSymbol, mTimeFrame, endIndex);       
        mMBs[0] = mb;
    }
    else
    {
        CMB* mb = new CMB(mbType, startIndex, endIndex, highIndex, lowIndex, mMaxZonesInMB);
        
        mb.CheckAddZones(mSymbol, mTimeFrame, endIndex);
        mMBs[(mMBsToTrack - 1) - mCurrentMBs] = mb;
        
        mCurrentMBs += 1;
    }
}

// method that resets all tracking
void CMBTracker::ResetTracking(void)
{
    mPendingBullishMB = false;
    mPendingBearishMB = false;

    mCurrentBullishRetracementIndex = -1;
    mCurrentBearishRetracementIndex = -1;

    mPendingBearishMBHighIndex = -1;
    mPendingBullishMBLowIndex = -1;
}

void CMBTracker::GetUnretrievedZonesInMBs(int mbStartingIndex, int mbEndingIndex, int barIndex, CZone &zones[])
{
   mbStartingIndex = MathMax(mbStartingIndex, mMBsToTrack - mCurrentMBs);
   
   for (int i = mbStartingIndex; i <= mbEndingIndex; i++)
   {
      // only allow the most recent MB to have zones after it has been validated if there is no pending MB 
      if (i == (mMBsToTrack - mCurrentMBs) && !mPendingBullishMB && !mPendingBearishMB)
      {
         mMBs[i].CheckAddZones(mSymbol, mTimeFrame, barIndex);
      }

      if (mMBs[i].HasUnretrievedZones())
      {
         mMBs[i].GetUnretrievedZones(zones);
      }
   }
}

void CMBTracker::PrintMBs(int mostRecentMBsToPrint)
{
   if (mostRecentMBsToPrint == -1 || mostRecentMBsToPrint > mCurrentMBs)
   {
      mostRecentMBsToPrint = mCurrentMBs;
   }
   
   for (int i = mMBsToTrack - mostRecentMBsToPrint; i < mMBsToTrack; i++)
   {
      mMBs[i].Draw(mSymbol, mTimeFrame);
   } 
}

void CMBTracker::DrawMBs(int mostRecentMBsToDraw)
{
   
   if (mostRecentMBsToDraw == -1 || mostRecentMBsToDraw > mCurrentMBs)
   {
      mostRecentMBsToDraw = mCurrentMBs;
   }
   
   for (int i = mMBsToTrack - mostRecentMBsToDraw; i < mMBsToTrack; i++)
   {
      mMBs[i].Draw(mSymbol, mTimeFrame);
   } 
}

void CMBTracker::DrawZones(int mostRecentMBsToDrawZonesFor)
{
   if (mostRecentMBsToDrawZonesFor == -1 || mostRecentMBsToDrawZonesFor > mCurrentMBs)
   {
      mostRecentMBsToDrawZonesFor = mCurrentMBs;
   }
   
   for (int i = mMBsToTrack - mostRecentMBsToDrawZonesFor; i < mMBsToTrack; i++)
   {
      mMBs[i].DrawZones(mSymbol, mTimeFrame);
   } 
}
