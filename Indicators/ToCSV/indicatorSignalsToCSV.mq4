//+------------------------------------------------------------------+
//|                                                     Indi2csv.mq4 |
//|                                                  Heaton Research |
//|                              http://www.heatonresearch.com/encog |
//|                                simplified by Mustafa Doruk Basar |
//+------------------------------------------------------------------+
#property copyright "Heaton Research"
#property link      "http://www.heatonresearch.com/encog"
#property strict
#property indicator_chart_window

extern string file_name = "Indi2csv.csv";

int fileh =-1;
int lasterror;

//+------------------------------------------------------------------+

int init()
  {
 
   IndicatorShortName("Indicators2CSV");

   fileh = FileOpen(file_name,FILE_CSV|FILE_WRITE,',');
   if(fileh<1)
   {
      lasterror = GetLastError();
      Print("Error updating file: ",lasterror);
      return(false);
   }
   
   // file header - need to be the identifiers of the indicators to be exported   
   FileWrite(fileh,
      "time",
      "close",
      "open",
      "high",
      "low",
      "volume",
      "14/21 EMA Crossover",
      "14/21 EMA Crossunder",
      "Above 50 EMA",
      "Above 200 EMA",
      "RSI Overbought",
      "RSI Oversold",
      "Parabolic SAR Above",
      "Alligator Lips Above Teeth",
      "Alligator Lips Above Jaw",
      "Alligator Lips Crossover Teeth",
      "Alligator Lips Crossunder Teeth",
      "Alligator Lips Crossover Jaw",
      "Alligator Lips Crossunder Jas",
      "Upper Fractal",
      "Lower Fractal",
      "MACD Crossover",
      "MACD Crossunder",
      "Stoch Crossover",
      "Stoch Crossunder",
      "Stoch Main Overbought",
      "Stoch Signal Overbought",
      "Stoch Main Oversold",
      "Stoch Signal Oversold",
      "Outside Upper Bollinger Band",
      "Oustide Lower Bollinger Band",
      "Bullish Engulfing",
      "Bearish Engulfing",
      "Doji"
      );

   return(0);
   
  }

//+------------------------------------------------------------------+

int deinit()
  {
      if(fileh>0) 
      {
         FileClose(fileh);
      }
   
   return(0);
   
  }
  
//+------------------------------------------------------------------+
  
int start()
  {
   int barcount = IndicatorCounted();
   if (barcount<0) return(-1);
   if (barcount>0) barcount--;
   
   int barind=Bars-barcount-1;
   
      while(barind>1)
      {
         ExportIndiData(barind);
         barind--;
      }

   return(0);
   
  }
//+------------------------------------------------------------------+

void ExportIndiData(int barind) 
{
   datetime t = Time[barind];
   string inditime =  
      StringConcatenate(TimeYear(t)+"_"+
                        TimeMonth(t)+"_"+
                        TimeDay(t)+"_"+
                        TimeHour(t)+"_"+
                        TimeMinute(t)+"_"+
                        TimeSeconds(t));
                        
   // MAs
   double previousFasterEMA = iMA(Symbol(), 0, 14, 0, MODE_EMA, PRICE_CLOSE, barind - 1);
   double previousSlowerEMA = iMA(Symbol(), 0, 21, 0, MODE_EMA, PRICE_CLOSE, barind - 1);
   double currentFasterEMA = iMA(Symbol(), 0, 14, 0, MODE_EMA, PRICE_CLOSE, barind);
   double currentSlowerEMA = iMA(Symbol(), 0, 21, 0, MODE_EMA, PRICE_CLOSE, barind);
   
   double fiftyEMA = iMA(Symbol(), 0, 50, 0, MODE_EMA, PRICE_CLOSE, barind);
   double twoHundredEMA = iMA(Symbol(), 0, 200, 0, MODE_EMA, PRICE_CLOSE, barind);
   
   bool maCrossover = previousFasterEMA < previousSlowerEMA && currentFasterEMA > currentSlowerEMA;
   bool maCrossunder = previousFasterEMA > previousSlowerEMA && currentFasterEMA < currentSlowerEMA;
   bool aboveFiftyEMA = Close[barind] > fiftyEMA;
   bool aboveTwoHundredEMA = Close[barind] > twoHundredEMA;
   
   // rsi
   double rsi = iRSI(Symbol(), 0, 14, PRICE_CLOSE, barind);
   
   bool rsiOverbought = rsi >= 70;
   bool rsiOversold = rsi <= 30;
   
   // parabolic sar
   double sar = iSAR(Symbol(), 0, 0.02, 0.2, barind);
   
   bool parabolicSarAbove = sar > Close[barind];
   
   // Willams Alligator
   double previousLips = iAlligator(Symbol(), 0, 13, 8 , 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_GATORLIPS, barind - 1);
   double previousTeeth = iAlligator(Symbol(), 0, 13, 8 , 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_GATORTEETH, barind - 1);
   double previousJaw = iAlligator(Symbol(), 0, 13, 8 , 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_GATORJAW, barind - 1);
   
   double currentLips = iAlligator(Symbol(), 0, 13, 8 , 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_GATORLIPS, barind);
   double currentTeeth = iAlligator(Symbol(), 0, 13, 8 , 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_GATORTEETH, barind);
   double currentJaw = iAlligator(Symbol(), 0, 13, 8 , 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_GATORJAW, barind);
   
   bool lipsAboveTeeth = currentLips > currentTeeth;
   bool lipsAboveJaw = currentLips > currentJaw;
   
   bool lipsCrossoverTeeth = previousLips < previousTeeth && currentLips > currentTeeth;
   bool lipsCrossunderTeeth = previousLips > previousTeeth && currentLips < currentTeeth;
   bool lipsCrossoverJaw = previousLips < previousJaw && currentLips > currentJaw;
   bool lipsCrossunderJaw = previousLips > previousJaw && currentLips < previousJaw;
   
   
   // Gator Osciallator
   double jawTeethDifference = iGator(Symbol(), 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_UPPER, barind);
   double teethLipsDifference = iGator(Symbol(), 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_CLOSE, MODE_LOWER, barind);
   
   // Fractal
   double upperFractal = iFractals(Symbol(), 0, MODE_UPPER, barind);
   double lowerFractal = iFractals(Symbol(), 0, MODE_LOWER, barind);
   
   // MACD
   double previousMacdMain = iMACD(Symbol(), 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, barind - 1);
	double previousMacdSignal = iMACD(Symbol(), 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, barind - 1);
	
	double currentMacdMain = iMACD(Symbol(), 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, barind);
	double currentMacdSignal = iMACD(Symbol(), 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, barind);
	
	bool macdCrossover = previousMacdSignal < previousMacdMain && currentMacdSignal > currentMacdMain;
	bool macdCrossunder = previousMacdSignal > previousMacdMain && currentMacdSignal < currentMacdMain;
	
	// Stochastic
	double previousStochMain = iStochastic(Symbol(), 0, 5, 3, 3, MODE_EMA, 0, MODE_MAIN, barind);
	double previousStochSignal = iStochastic(Symbol(), 0, 5, 3, 3, MODE_EMA, 0, MODE_SIGNAL, barind);
	
	double currentStochMain = iStochastic(Symbol(), 0, 5, 3, 3, MODE_EMA, 0, MODE_MAIN, barind);
	double currentStochSignal = iStochastic(Symbol(), 0, 5, 3, 3, MODE_EMA, 0, MODE_SIGNAL, barind);
	
	bool stochCrossover = previousStochSignal < previousStochMain && currentStochSignal > currentStochMain;
	bool stochCrossunder = previousStochSignal > previousStochMain && currentStochSignal < currentStochMain;
	
	bool stochMainOverbought = currentStochMain >= 70;
	bool stochSignalOverbought = currentStochSignal >= 70;
	
	bool stochMainOversold = currentStochMain <= 30;
	bool stochSignalOversold = currentStochSignal <= 30;
	
	// Bollinger Bands
	double upperBB = iBands(Symbol(), 0, 20, 2, 0, 0, MODE_UPPER, barind);
	double lowerBB = iBands(Symbol(), 0, 20, 2, 0, 0, MODE_LOWER, barind);
	
	bool priceOutsideUpperBand = High[barind] > upperBB;
	bool priceOustideLoweerBand = Low[barind] < lowerBB;
	
	// candlestick patterns
	bool bullishEngulfing = Open[barind] <= Open[barind - 1] && Close[barind] > Close[barind - 1];
	bool bearishEngulfing = Open[barind] >= Open[barind - 1] && Close[barind] < Close[barind - 1];
	
	double candleBodyHigh = MathMax(Close[barind], Open[barind]);
   double candleBodyLow = MathMin(Close[barind], Open[barind]);
   double candleBody = candleBodyHigh - candleBodyLow;
   double candleRange = High[barind] - Low[barind];
   double dojiBodyPercent = 5.0;
   bool doji = candleRange > 0 && candleBody <= candleRange * dojiBodyPercent / 100;
	
   FileWrite(fileh, 
         inditime,
			Close[barind],
			Open[barind],
			High[barind],
			Low[barind],
			Volume[barind],
		   maCrossover,
		   macdCrossunder,
		   aboveFiftyEMA,
		   aboveTwoHundredEMA,
		   rsiOverbought,
		   rsiOversold,
		   parabolicSarAbove,
		   lipsAboveTeeth,
		   lipsAboveJaw,
		   lipsCrossoverTeeth,
		   lipsCrossunderTeeth,
		   lipsCrossoverJaw,
		   lipsCrossunderJaw,
		   upperFractal,
		   lowerFractal,
		   macdCrossover,
		   macdCrossunder,
		   stochCrossover,
		   stochCrossunder,
		   stochMainOverbought,
		   stochSignalOverbought,
		   stochMainOversold,
		   stochSignalOversold,
		   priceOutsideUpperBand,
		   priceOustideLoweerBand,
		   bullishEngulfing,
		   bearishEngulfing,
		   doji
			);
			
}
