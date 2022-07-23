//+------------------------------------------------------------------+
//|                                          MinROCFromTimeStamp.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
/*

       _           _                 _   _
    __| | ___  ___| | __ _ _ __ __ _| |_(_) ___  _ __
   / _` |/ _ \/ __| |/ _` | '__/ _` | __| |/ _ \| '_ \
  | (_| |  __/ (__| | (_| | | | (_| | |_| | (_) | | | |
   \__,_|\___|\___|_|\__,_|_|  \__,_|\__|_|\___/|_| |_|


*/
// ClearedForUse
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
   bool mCrossedOpenPriceAfterMinROC;

   bool mDrawnMinROCAchievedTime;

   string mOpenPriceDrawingName;
   string mMinROCAchievedDrawingName;

   // Tested
   void Update();

public:
   // ==========================================================================
   // Constructor / destructor
   // ==========================================================================
   MinROCFromTimeStamp(string symbol, int timeFrame, int serverHourStartTime, int serverHourEndTime, int serverMinuteStartTime, int serverMinuteEndTime, double minROCPercent);
   ~MinROCFromTimeStamp();

   // ==========================================================================
   // Getters
   // ==========================================================================
   bool HadMinROC() { return mHadMinROC; }
   string Symbol() { return mSymbol; }
   int TimeFrame() { return mTimeFrame; }

   // ==========================================================================
   // Computed Properties
   // ==========================================================================
   // Tested
   // CallsUpdate
   double OpenPrice();

   // Tested
   // CallsUpdate
   datetime MinROCAchievedTime();

   // Tested
   // CallsUpdate
   bool CrossedOpenPriceAfterMinROC();

   // ==========================================================================
   // Display Methods
   // ==========================================================================
   // Tested
   // CallsUpdate
   void Draw();
};
/*

              _            _                        _   _               _
   _ __  _ __(_)_   ____ _| |_ ___   _ __ ___   ___| |_| |__   ___   __| |___
  | '_ \| '__| \ \ / / _` | __/ _ \ | '_ ` _ \ / _ \ __| '_ \ / _ \ / _` / __|
  | |_) | |  | |\ V / (_| | ||  __/ | | | | | |  __/ |_| | | | (_) | (_| \__ \
  | .__/|_|  |_| \_/ \__,_|\__\___| |_| |_| |_|\___|\__|_| |_|\___/ \__,_|___/
  |_|

*/

/**
 * @brief Calculates the rate of change if passed the specified time
 *
 */
void MinROCFromTimeStamp::Update()
{
   if (Hour() >= mServerHourStartTime && Minute() >= mServerMinuteStartTime && Hour() <= mServerHourEndTime && Minute() < mServerMinuteEndTime && DayOfWeek() > 0 /*&& DayOfWeek() < 6 */)
   {
      Print("time");

      if (mOpenPrice == 0.0)
      {
         Print("Setting open Price");
         mOpenPrice = iOpen(mSymbol, mTimeFrame, 0);
         mOpenTime = iTime(mSymbol, mTimeFrame, 0);
      }

      double value = 0.0;
      if (iClose(mSymbol, mTimeFrame, 0) > mOpenPrice)
      {
         Print("Setting to high ");
         value = MathMax(iHigh(mSymbol, mTimeFrame, 0), iLow(mSymbol, mTimeFrame, 0));
      }
      else
      {
         Print("Setting to low");
         value = MathMin(iHigh(mSymbol, mTimeFrame, 0), iLow(mSymbol, mTimeFrame, 0));
      }

      double roc = ((value - mOpenPrice) / mOpenPrice) * 100;
      bool isMinROC = roc >= mMinROCPercent || roc <= -1 * mMinROCPercent;
      Print("ROC: ", roc, ", Threshold: ", mMinROCPercent);
      if (isMinROC && mMinROCAchievedTime == NULL)
      {
         Print("Min ROC. Achieved");
         mMinROCAchievedTime = TimeCurrent();
         mHadMinROC = true;
      }
   }
   else
   {
      Print("Not time");
      mOpenPrice = 0.0;
      mMinROCAchievedTime = NULL;
   }
}

/*

    ____                _                   _                  __  ____            _                   _
   / ___|___  _ __  ___| |_ _ __ _   _  ___| |_ ___  _ __     / / |  _ \  ___  ___| |_ _ __ _   _  ___| |_ ___  _ __
  | |   / _ \| '_ \/ __| __| '__| | | |/ __| __/ _ \| '__|   / /  | | | |/ _ \/ __| __| '__| | | |/ __| __/ _ \| '__|
  | |__| (_) | | | \__ \ |_| |  | |_| | (__| || (_) | |     / /   | |_| |  __/\__ \ |_| |  | |_| | (__| || (_) | |
   \____\___/|_| |_|___/\__|_|   \__,_|\___|\__\___/|_|    /_/    |____/ \___||___/\__|_|   \__,_|\___|\__\___/|_|


*/
/**
 * @brief Construct a new MinROCFromTimeStamp::MinROCFromTimeStamp object
 *
 * @param symbol
 * @param timeFrame
 * @param serverHourStartTime
 * @param serverHourEndTime
 * @param serverMinuteStartTime
 * @param serverMinuteEndTime
 * @param minROCPercnet
 */
MinROCFromTimeStamp::MinROCFromTimeStamp(string symbol, int timeFrame, int serverHourStartTime, int serverHourEndTime, int serverMinuteStartTime, int serverMinuteEndTime, double minROCPercnet)
{
   mSymbol = symbol;
   mTimeFrame = timeFrame;

   mServerHourStartTime = serverHourStartTime;
   mServerHourEndTime = serverHourEndTime;
   mServerMinuteStartTime = serverMinuteStartTime;
   mServerMinuteEndTime = serverMinuteEndTime;
   mMinROCPercent = minROCPercnet;

   mHadMinROC = false;
   mCrossedOpenPriceAfterMinROC = false;

   mOpenPrice = 0.0;
   mMinROCAchievedTime = NULL;

   mOpenPriceDrawingName = "Open Price for " + mSymbol + " " + IntegerToString(mTimeFrame);
   mMinROCAchievedDrawingName = "Min ROC. for " + mSymbol + " " + IntegerToString(mTimeFrame);
}
/**
 * @brief Destroy the MinROCFromTimeStamp::MinROCFromTimeStamp object and remove all drawings
 *
 */
MinROCFromTimeStamp::~MinROCFromTimeStamp()
{
   ObjectDelete(ChartID(), mOpenPriceDrawingName);
   ObjectDelete(ChartID(), mMinROCAchievedDrawingName);
}
/*

    ____                            _           _   ____                            _   _
   / ___|___  _ __ ___  _ __  _   _| |_ ___  __| | |  _ \ _ __ ___  _ __   ___ _ __| |_(_) ___  ___
  | |   / _ \| '_ ` _ \| '_ \| | | | __/ _ \/ _` | | |_) | '__/ _ \| '_ \ / _ \ '__| __| |/ _ \/ __|
  | |__| (_) | | | | | | |_) | |_| | ||  __/ (_| | |  __/| | | (_) | |_) |  __/ |  | |_| |  __/\__ \
   \____\___/|_| |_| |_| .__/ \__,_|\__\___|\__,_| |_|   |_|  \___/| .__/ \___|_|   \__|_|\___||___/
                       |_|                                         |_|

*/
datetime MinROCFromTimeStamp::MinROCAchievedTime()
{
   Update();
   return mMinROCAchievedTime;
}
double MinROCFromTimeStamp::OpenPrice()
{
   Update();
   return mOpenPrice;
}
bool MinROCFromTimeStamp::CrossedOpenPriceAfterMinROC()
{
   if (!mCrossedOpenPriceAfterMinROC)
   {
      if (mOpenPrice > 0.0 && mHadMinROC && iTime(mSymbol, mTimeFrame, 0) > mMinROCAchievedTime)
      {
         mCrossedOpenPriceAfterMinROC = (iLow(mSymbol, mTimeFrame, 1) > mOpenPrice && iLow(mSymbol, mTimeFrame, 0) < mOpenPrice) ||
                                        (iHigh(mSymbol, mTimeFrame, 1) < mOpenPrice && iHigh(mSymbol, mTimeFrame, 0) > mOpenPrice);
      }
   }

   return mCrossedOpenPriceAfterMinROC;
}
/*

   ____  _           _               __  __      _   _               _
  |  _ \(_)___ _ __ | | __ _ _   _  |  \/  | ___| |_| |__   ___   __| |___
  | | | | / __| '_ \| |/ _` | | | | | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  | |_| | \__ \ |_) | | (_| | |_| | | |  | |  __/ |_| | | | (_) | (_| \__ \
  |____/|_|___/ .__/|_|\__,_|\__, | |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
              |_|            |___/

*/
void MinROCFromTimeStamp::Draw()
{
   Update();

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