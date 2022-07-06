//+------------------------------------------------------------------+
//|                                                           MB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

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
      
      // --- MB Structure Tracking ---      
      int mCurrentBullishRetracementIndex;
      int mCurrentBearishRetracementIndex;
      
      bool mPendingBullishMB;
      bool mPendingBearishMB;
      
      int mPendingBullishMBLowIndex;
      int mPendingBearishMBHighIndex;
      
      int mMBType[];
      int mMBStartIndex[];
      int mMBEndIndex[];
      int mMBHighIndex[];
      int mMBLowIndex[];
      
      // --- MB Range Tracking
      double mMBRangeHigh;
      double mMBRangeLow;
      
      // --- Imbalance Tracking --- 
      //double mImbalances[][];
          
      // --- Methods
      void Update();
      void CalculateMB(int barIndex);
      void CheckSetRetracement(int startingIndex, int mbType, int prevMBType);
      void CheckSetPendingMB(int startingIndex, int mbType);
      void CreateMB(int mbType, int startIndex, int endIndex, int highIndex, int lowIndex);
      void ResetTracking();

   public:
      CMBTracker();
      CMBTracker(string symbol, ENUM_TIMEFRAMES timeFrame, int mbsToTrack);
      ~CMBTracker();
      
      void init(string symbol, ENUM_TIMEFRAMES timeFrame, int mbsToTrack);
      bool GetMBs(int startIndex, int endIndex, bool initialFetch, int &mbArray[][]);
      void PrintMBs(int startIndex, int endIndex);
      void PrintArrayLengths(int startIndex, int endIndex);
      void DrawMBs(int startIndex, int endIndex);
};

CMBTracker::CMBTracker()
{
   init(Symbol(), 0, 3);
}

CMBTracker::CMBTracker(string symbol, ENUM_TIMEFRAMES timeFrame,int mbsToTrack)
{
   init(symbol, timeFrame, mbsToTrack);
}

CMBTracker::~CMBTracker()
{
   ObjectsDeleteAll(ChartID());
}

void CMBTracker::init(string symbol,ENUM_TIMEFRAMES timeFrame, int mbsToTrack)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   mPrevCalculated = 0;
   mFirstBarTime = 0;
   
   mMBsToTrack = mbsToTrack;
   
   mCurrentBullishRetracementIndex = -1;
   mCurrentBearishRetracementIndex = -1;
    
   ArrayResize(mMBType, mbsToTrack);
   ArrayResize(mMBStartIndex, mbsToTrack);
   ArrayResize(mMBEndIndex, mbsToTrack);
   ArrayResize(mMBHighIndex, mbsToTrack);
   ArrayResize(mMBLowIndex, mbsToTrack);
   
   ArrayFill(mMBType, 0, mbsToTrack, -1);
   ArrayFill(mMBStartIndex,0, mbsToTrack, -1);
   ArrayFill(mMBEndIndex, 0, mbsToTrack, -1);
   ArrayFill(mMBHighIndex, 0, mbsToTrack, -1);
   ArrayFill(mMBLowIndex, 0, mbsToTrack, -1);
   
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
   if (mMBType[mMBsToTrack - 1] == -1)
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
   else if (mMBType[mMBsToTrack - mCurrentMBs] == OP_BUY)
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
         else if (iLow(mSymbol, mTimeFrame, barIndex) < iLow(mSymbol, mTimeFrame, mMBLowIndex[mMBsToTrack - mCurrentMBs]))
         {
            int highestIndex = iHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBStartIndex[mMBsToTrack - mCurrentMBs] - barIndex, barIndex);
            CreateMB(OP_SELL, mMBLowIndex[mMBsToTrack - mCurrentMBs], barIndex, highestIndex, mMBLowIndex[mMBsToTrack - mCurrentMBs]);
            ResetTracking();
         }
      }
   }
   // prev mb was bearish
   else if (mMBType[mMBsToTrack - mCurrentMBs] == OP_SELL)
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
         else if (iHigh(mSymbol, mTimeFrame, barIndex) > iHigh(mSymbol, mTimeFrame, mMBHighIndex[mMBsToTrack - mCurrentMBs]))
         {
            int lowestIndex = iLowest(mSymbol, mTimeFrame, MODE_LOW, mMBStartIndex[mMBsToTrack - mCurrentMBs] - barIndex, barIndex);
            CreateMB(OP_BUY, mMBHighIndex[mMBsToTrack - mCurrentMBs], barIndex, mMBHighIndex[mMBsToTrack - mCurrentMBs], lowestIndex);
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
            mCurrentBullishRetracementIndex = iHighest(mSymbol, mTimeFrame, MODE_HIGH, mMBEndIndex[mMBsToTrack - mCurrentMBs] - startingIndex + 1, startingIndex);
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
            mCurrentBearishRetracementIndex = iLowest(mSymbol, mTimeFrame, MODE_LOW, mMBEndIndex[mMBsToTrack - mCurrentMBs] - startingIndex + 1, startingIndex);
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
        ArrayCopy(mMBType, mMBType, 0, 1, mMBsToTrack - 1);
        ArrayCopy(mMBStartIndex, mMBStartIndex, 0, 1, mMBsToTrack - 1);
        ArrayCopy(mMBEndIndex, mMBEndIndex, 0, 1, mMBsToTrack - 1);
        ArrayCopy(mMBHighIndex, mMBHighIndex, 0, 1, mMBsToTrack - 1);
        ArrayCopy(mMBLowIndex, mMBLowIndex, 0, 1, mMBsToTrack - 1);

        mMBType[0] = mbType;
        mMBStartIndex[0] = startIndex;
        mMBEndIndex[0] = endIndex;
        mMBHighIndex[0] = highIndex;
        mMBLowIndex[0] = lowIndex;
    }
    else
    {
        mMBType[(mMBsToTrack - 1) - mCurrentMBs] = mbType;
        mMBStartIndex[(mMBsToTrack - 1) - mCurrentMBs] = startIndex;
        mMBEndIndex[(mMBsToTrack - 1) - mCurrentMBs] = endIndex;
        mMBHighIndex[(mMBsToTrack - 1) - mCurrentMBs] = highIndex;
        mMBLowIndex[(mMBsToTrack - 1) - mCurrentMBs] = lowIndex;
        
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

// Sets Mbs from start index -> end index in the provided 2 dimensional array mbArray[endIndex - startIndex][5]
// returns true if values were updated, false otherwise
bool CMBTracker::GetMBs(int startIndex, int endIndex, bool initalFetch, int &mbArray[][])
{
   int tempMBStartIndex[];
   ArrayCopy(tempMBStartIndex, mMBStartIndex);
   
   Update();
   
   if (initalFetch || ArrayCompare(tempMBStartIndex, mMBStartIndex) != 0)
   {
      startIndex = MathMax(0, mMBsToTrack - mCurrentMBs);
      if (endIndex < startIndex)
      {
         Print("Ending Index is less than starting index. Starting Index: ", startIndex, ", Ending Index: ", endIndex);
      }
      
      for (int i = startIndex; i <= endIndex; i++)
      {
         mbArray[i][0] = mMBType[i];
         mbArray[i][1] = mMBStartIndex[i];
         mbArray[i][2] = mMBEndIndex[i];
         mbArray[i][3] = mMBHighIndex[i];
         mbArray[i][4] = mMBLowIndex[i];
      }
      
      return true;
   }
   
   return false;
}

void CMBTracker::PrintMBs(int startIndex, int endIndex)
{
   startIndex = MathMax(0, mMBsToTrack - mCurrentMBs);
   if (endIndex < startIndex)
   {
      Print("Ending Index is less than starting index. Starting Index: ", startIndex, ", Ending Index: ", endIndex);
   }
   
   for (int i = startIndex; i <= endIndex; i++)
   {
      Print("MB: ", i, " at hour: ", Hour(), ", minute: ", Minute(), ", second: ", Seconds());
      Print("Type: ", mMBType[i]);
      Print("Start Index: ", mMBStartIndex[i]);
      Print("End Index: ", mMBEndIndex[i]);
      Print("High Index: ", mMBHighIndex[i]);
      Print("Low Index: ", mMBLowIndex[i]);
   }
}

void CMBTracker::DrawMBs(int startIndex, int endIndex)
{
   startIndex = MathMax(0, mMBsToTrack - mCurrentMBs);
   if (endIndex < startIndex)
   {
      Print("Ending Index is less than starting index. Starting Index: ", startIndex, ", Ending Index: ", endIndex);
   }
   
   for (int i = startIndex; i <= endIndex; i++)
   {
      color clr = mMBType[i] == OP_BUY ? clrYellow : clrPurple;  
      string name = "Type: " + mMBType[i] + ", Start: " + mMBStartIndex[i] + ", End: " + mMBEndIndex[i] + ", High: " + mMBEndIndex[i] + ", Low: " + mMBLowIndex[i];
      
      if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, Time[mMBStartIndex[i]], High[mMBHighIndex[i]], Time[mMBEndIndex[i]], Low[mMBLowIndex[i]]))
      {
         // TODO: FIX
         // Print("Object Creation Failed: ", GetLastError());
      }
      ObjectSetDouble(0, name, OBJPROP_PRICE1, High[mMBHighIndex[i]]);
      ObjectSetDouble(0, name,OBJPROP_PRICE2, Low[mMBLowIndex[i]]);
      ObjectSetInteger(0, name, OBJPROP_TIME1, Time[mMBStartIndex[i]]);
      ObjectSetInteger(0, name, OBJPROP_TIME2, Time[mMBEndIndex[i]]); 
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_FILL, false);
      //ObjectSetInteger(0,name,OBJPROP_COLOR,clrRed);//ChartGetInteger(0,CHART_COLOR_BACKGROUND));
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   } 
}

void CMBTracker::PrintArrayLengths(int startIndex, int endIndex)
{
   int mbTypeTotal = 0;
   int mbStartIndexTotal = 0;
   int mbEndIndexTotal = 0;
   int mbHighIndexTotal = 0;
   int mbLowIndexTotal = 0;
   
   startIndex = MathMax(0, mMBsToTrack - mCurrentMBs);
   if (endIndex < startIndex)
   {
      Print("Ending Index is less than starting index. Starting Index: ", startIndex, ", Ending Index: ", endIndex);
   }
   
   for (int i = startIndex; i <= endIndex; i++)
   {
      if (mMBType[i] != -1)
      {
         mbTypeTotal += 1;
      }
      
      if (mMBStartIndex[i] != -1)
      {
         mbStartIndexTotal += 1;
      }
      
      if (mMBEndIndex[i] != -1)
      {
         mbEndIndexTotal += 1;
      }
      
      if (mMBHighIndex[i] != -1)
      {
         mbHighIndexTotal += 1;
      }
      
      if (mMBLowIndex[i] != -1)
      {
         mbLowIndexTotal += 1;
      }
   }
   
   Print("mCurrentMBs :", mCurrentMBs, ", mMBsToTrack: ", mMBsToTrack);
   Print("Total MB Types: ", mbTypeTotal, ", Total Start Indexs: ", mbStartIndexTotal, ", Total End Indexs: ", mbEndIndexTotal, ", Total High Indexs: ", mbHighIndexTotal, ", Total Low Indexs: ", mbLowIndexTotal);
}

