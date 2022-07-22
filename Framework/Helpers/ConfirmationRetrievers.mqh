//+------------------------------------------------------------------+
//|                                           ConfirmationHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class ConfirmationRetrievers
{
   public:
      static bool Hammer(string symbol, int timeFrame);
      static bool HammerBreak(string symbol, int timeFrame, bool useBody);
      
      static bool ShootingStar(string symbol, int timeFrame);
      static bool ShootingStarBreak(string symbol, int timeFrame, bool useBody);
};

// bullish candlestick pattern where a candle wick liquidates the candle low before it
// hopint to see price break up after
static bool ConfirmationRetrievers::Hammer(string symbol,int timeFrame)
{
   bool HighNotAbovePreviuos = iHigh(symbol, timeFrame, 0) < iHigh(symbol, timeFrame, 1);
   bool bodyNotBelowPrevious = MathMin(iOpen(symbol, timeFrame, 0), iClose(symbol, timeFrame, 0)) > iLow(symbol, timeFrame, 1);
   bool wickBelowPreviuos = iLow(symbol, timeFrame, 0) < iLow(symbol, timeFrame, 1);
   
   return HighNotAbovePreviuos && bodyNotBelowPrevious && wickBelowPreviuos;
}

static bool ConfirmationRetrievers::HammerBreak(string symbol, int timeFrame, bool useBody)
{
   bool HighNotAbovePreviuos = iHigh(symbol, timeFrame, 1) < iHigh(symbol, timeFrame, 2);
   bool bodyNotBelowPrevious = MathMin(iOpen(symbol, timeFrame, 1), iClose(symbol, timeFrame, 1)) > iLow(symbol, timeFrame, 2);
   bool wickBelowPreviuos = iLow(symbol, timeFrame, 1) < iLow(symbol, timeFrame, 2);
   bool breakHigher = (useBody && MathMax(iOpen(symbol, timeFrame, 0), iClose(symbol, timeFrame, 0)) > iHigh(symbol, timeFrame, 1)) || (!useBody && iHigh(symbol, timeFrame, 0) > iHigh(symbol, timeFrame, 1));
   
   return HighNotAbovePreviuos && bodyNotBelowPrevious && wickBelowPreviuos && breakHigher;
}

// bearish candlestick pattern where a candle wick liqudiates the candle high before it
// hopint to see price break down after 
static bool ConfirmationRetrievers::ShootingStar(string symbol,int timeFrame)
{
   bool lowNotBelowPrevious = iLow(symbol, timeFrame, 0) > iLow(symbol, timeFrame, 1);
   bool bodyNotAbovePrevious = MathMax(iOpen(symbol, timeFrame, 0), iClose(symbol, timeFrame, 0)) < iHigh(symbol, timeFrame, 1);
   bool wickAbovePrevious = iHigh(symbol, timeFrame, 0) > iHigh(symbol, timeFrame, 1);
   
   return lowNotBelowPrevious && bodyNotAbovePrevious && wickAbovePrevious;
}

static bool ConfirmationRetrievers::ShootingStarBreak(string symbol,int timeFrame,bool useBody)
{
   bool lowNotBelowPrevious = iLow(symbol, timeFrame, 1) > iLow(symbol, timeFrame, 2);
   bool bodyNotAbovePrevious = MathMax(iOpen(symbol, timeFrame, 1), iClose(symbol, timeFrame, 1)) < iHigh(symbol, timeFrame, 2);
   bool wickAbovePrevious = iHigh(symbol, timeFrame, 1) > iHigh(symbol, timeFrame, 2);
   bool breakLower = (useBody && MathMin(iOpen(symbol, timeFrame, 0), iClose(symbol, timeFrame, 0)) < iLow(symbol, timeFrame, 1)) || (!useBody && iLow(symbol, timeFrame, 0) < iLow(symbol, timeFrame, 1));
   
   return lowNotBelowPrevious && bodyNotAbovePrevious && wickAbovePrevious && breakLower;
}
