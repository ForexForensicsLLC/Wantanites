//+------------------------------------------------------------------+
//|                                                     Indi2csv.mq4 |
//|                                                  Heaton Research |
//|                              http://www.heatonresearch.com/encog |
//|                                simplified by Mustafa Doruk Basar |
//+------------------------------------------------------------------+
#property copyright "Heaton Research"
#property link      "http://www.heatonresearch.com/encog"
#property strict
#property indicator_separate_window

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
      "accelerator-decelerator",
      "accumulation-distribution",
      "accumulation-distribution movement index-main",
      "accumulation-distribution movement index-+D",
      "accumulation-distribution movement index--D",
      "alligator-jaw",
      "alligator-teeth",
      "alligator-lips",
      "awesome oscillator",
      "atr",
      "bears-power",
      "bollinger bands-main",
      "bollinger bands-upper",
      "bollinger bands-lower",
      "bulls power",
      "commodity channel index",
      "fractal-upper",
      "fractal-lower",
      "gator osciallator-upper",
      "gator osciallator-lower",
      "ichimoku-tenkansen",
      "ichimoku-kijunsen",
      "ichimoku-senkouspan-a",
      "ichimoku-senkouspan-b",
      "ichimoku-chikouspan",
      "market facilation index",
      "momentum",
      "money flow index",
      "ema-9",
      "ema-14",
      "ema-21",
      "ema-50",
      "ema-200",
      "moving average of oscillator",
      "macd-main",
      "macd-signal",
      "on balance volume",
      "parabolic sar",
      "rsi",
      "standard deviation",
      "stoch-main",
      "stoch-signal",
      "williams percent range");

   return(0);
   
  }

//+------------------------------------------------------------------+

int deinit()
  {
      if(fileh>0) 
      {
         FileClose(fileh);
      }
   
   Print("Completed exporting data 2");
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
   Print("Completed exporting data 1");
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
                        
   // add indicators at will (do not forget to update line 31!
   FileWrite(fileh, 
         inditime,
			Close[barind],
			Open[barind],
			iAC(Symbol(),0,barind),
			iAD(Symbol(),0,barind),
			iADX(Symbol(),0,14,PRICE_HIGH,0,barind),
			iADX(Symbol(),0,14,PRICE_HIGH,1,barind),
			iADX(Symbol(),0,14,PRICE_HIGH,2,barind),
			iAlligator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_CLOSE,MODE_GATORJAW,barind),
			iAlligator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_CLOSE,MODE_GATORTEETH,barind),
			iAlligator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_CLOSE,MODE_GATORLIPS,barind),
			iAO(Symbol(),0,barind),
			iATR(Symbol(),0,14,barind),
			iBearsPower(Symbol(),0,13,PRICE_CLOSE,barind),
			iBands(Symbol(),0,20,2,0,PRICE_CLOSE,0,barind),
			iBands(Symbol(),0,20,2,0,PRICE_CLOSE,1,barind),
			iBands(Symbol(),0,20,2,0,PRICE_CLOSE,2,barind),
			iBullsPower(Symbol(),0,13,PRICE_CLOSE,barind),
			iCCI(Symbol(),0,14,PRICE_CLOSE,barind),
			iFractals(Symbol(),0,MODE_UPPER,barind),
			iFractals(Symbol(),0,MODE_LOWER,barind),
			iGator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_UPPER,barind),
			iGator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,barind),
			iIchimoku(Symbol(),0,9,26,52,MODE_TENKANSEN,barind),
			iIchimoku(Symbol(),0,9,26,52,MODE_KIJUNSEN,barind),
			iIchimoku(Symbol(),0,9,26,52,MODE_SENKOUSPANA,barind),
			iIchimoku(Symbol(),0,9,26,52,MODE_SENKOUSPANB,barind),
			iIchimoku(Symbol(),0,9,26,52,MODE_CHIKOUSPAN,barind),
			iBWMFI(Symbol(),0,barind),
			iMomentum(Symbol(),0,12,PRICE_CLOSE,barind),
			iMFI(Symbol(),0,14,barind),
			iMA(Symbol(),0,9,0,MODE_EMA,PRICE_CLOSE,barind),
			iMA(Symbol(),0,14,0,MODE_EMA,PRICE_CLOSE,barind),
			iMA(Symbol(),0,21,0,MODE_EMA,PRICE_CLOSE,barind),
			iMA(Symbol(),0,50,0,MODE_EMA,PRICE_CLOSE,barind),
			iMA(Symbol(),0,200,0,MODE_EMA,PRICE_CLOSE,barind),
			iOsMA(Symbol(),0,12,26,9,PRICE_CLOSE,barind),
			iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,0,barind),
			iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,1,barind),
			iOBV(Symbol(),0,PRICE_CLOSE,barind),
			iSAR(Symbol(),0,0.02,0.2,barind),
			iRSI(Symbol(),0,14,PRICE_CLOSE,barind),
			iStdDev(Symbol(),0,10,0,MODE_EMA,PRICE_CLOSE,barind),
			iStochastic(Symbol(),0,5,3,3,MODE_EMA,0,0,barind),
			iStochastic(Symbol(),0,5,3,3,MODE_EMA,0,1,barind),
			iWPR(Symbol(),0,14,barind)
			);
			
}
