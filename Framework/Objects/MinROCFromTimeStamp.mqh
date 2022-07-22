//+------------------------------------------------------------------+
//|                                          MinROCFromTimeStamp.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class MinROCFromTimeStamp
{
   private:    
      string mSymbol;
      int mTimeFrame;
      
      int mServerHourStartTime;
      int mServerHourEndTime;
      int mServerMinuteStartTime;
      int mServerMinuteEndTime;
      double mMinROCPercent;
      
      double mOpenPrice;
      datetime mOpenTime;
      datetime mMinROCAchievedTime;
      bool mHadMinROC;
      
      bool mDrawnMinROCAchievedTime;
      
      void CalculateMinROC();
      
      string mOpenPriceDrawingName;
      string mMinROCAchievedDrawingName;
   
   public:
      bool HadMinROC() { return mHadMinROC; }
      string Symbol() { return mSymbol; }
      int TimeFrame() { return mTimeFrame; }
      
      MinROCFromTimeStamp(string symbol, int timeFrame, int serverHourStartTime, int serverHourEndTime, int serverMinuteStartTime, int serverMinuteEndTime, double minROCPercent);
      ~MinROCFromTimeStamp();
      
      datetime MinROCAchievedTime();
      double OpenPrice();
      bool CrossedOpenPriceAfterMinROC();
      
      void Draw();
};

void MinROCFromTimeStamp::CalculateMinROC()
{
   if (Hour() >= mServerHourStartTime && Minute() >= mServerMinuteStartTime && Hour() <= mServerHourEndTime && Minute() < mServerMinuteEndTime && DayOfWeek() > 0 && DayOfWeek() < 6) 
   {
      if (mOpenPrice == 0.0)
      {
         mOpenPrice = iOpen(mSymbol, mTimeFrame, 0);
         mOpenTime = iTime(mSymbol, mTimeFrame, 0);
      }
      
      double value = 0.0; 
      if (iClose(mSymbol, mTimeFrame, 0) > mOpenPrice)
      {
         value = MathMax(iHigh(mSymbol, mTimeFrame, 0), iLow(mSymbol, mTimeFrame, 0));
      } 
      else
      {
         value = MathMin(iHigh(mSymbol, mTimeFrame, 0), iLow(mSymbol, mTimeFrame, 0));
      }
      
      double roc = ((value - mOpenPrice) / mOpenPrice) * 100;
      bool isMinROC = roc >= mMinROCPercent || roc <= -1 * mMinROCPercent;
      if (isMinROC && mMinROCAchievedTime == NULL)
      {
         Print("Min ROC. Achieved");
         mMinROCAchievedTime = TimeCurrent();
         mHadMinROC = true;
      }    
   }
   else 
   {  
      mOpenPrice = 0.0;
      mMinROCAchievedTime = NULL;
   }
}


MinROCFromTimeStamp::MinROCFromTimeStamp(string symbol, int timeFrame, int serverHourStartTime, int serverHourEndTime, int serverMinuteStartTime, int serverMinuteEndTime, double minROCPercnet)
{ 
   mSymbol = symbol;
   mTimeFrame = timeFrame;
   
   mServerHourStartTime = serverHourStartTime;
   mServerHourEndTime = serverHourEndTime;
   mServerMinuteStartTime = serverMinuteStartTime;
   mServerMinuteEndTime = serverMinuteEndTime;
   mMinROCPercent = minROCPercnet;
   
   mOpenPrice = 0.0;
   mMinROCAchievedTime = NULL;
   mHadMinROC = false;
   
   mOpenPriceDrawingName = "Open Price for " + mSymbol + " " + IntegerToString(mTimeFrame);
   mMinROCAchievedDrawingName = "Min ROC. for " + mSymbol + " " + IntegerToString(mTimeFrame);
}

MinROCFromTimeStamp::~MinROCFromTimeStamp()
{
   ObjectDelete(ChartID(), mOpenPriceDrawingName);
   ObjectDelete(ChartID(), mMinROCAchievedDrawingName);
}

datetime MinROCFromTimeStamp::MinROCAchievedTime()
{
   CalculateMinROC();
   return mMinROCAchievedTime;
}

double MinROCFromTimeStamp::OpenPrice()
{
   CalculateMinROC();
   return mOpenPrice;
}

bool MinROCFromTimeStamp::CrossedOpenPriceAfterMinROC()
{
   if (mOpenPrice > 0.0 && mHadMinROC)
   {
      return (iLow(mSymbol, mTimeFrame, 1) > mOpenPrice && iLow(mSymbol, mTimeFrame, 0) < mOpenPrice) || (iHigh(mSymbol, mTimeFrame, 1) < mOpenPrice && iHigh(mSymbol, mTimeFrame, 0) > mOpenPrice);
   }
   
   return false;
}

void MinROCFromTimeStamp::Draw()
{
   if (mOpenPrice > 0.0)
   {
      ObjectCreate(ChartID(), mOpenPriceDrawingName, OBJ_HLINE, 0, mOpenTime, mOpenPrice, iTime(mSymbol, mTimeFrame, 0), mOpenPrice);
      ObjectSetInteger(ChartID(), mOpenPriceDrawingName, OBJPROP_COLOR, clrYellow);
   }
   
   if (!mDrawnMinROCAchievedTime && mHadMinROC)
   {
      ObjectCreate(ChartID(), mMinROCAchievedDrawingName, OBJ_VLINE, 0, mMinROCAchievedTime, mOpenPrice);
      ObjectSetInteger(ChartID(), mMinROCAchievedDrawingName, OBJPROP_COLOR, clrPurple);
      ObjectSetInteger(ChartID(), mMinROCAchievedDrawingName, OBJPROP_STYLE, STYLE_DASH);
   }
}