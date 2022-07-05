//+------------------------------------------------------------------+
//|                                           Min ROC. From Time.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property show_inputs
#property indicator_buffers 2

input int ServerHourStartTime = 16; 
input int ServerMinuteStartTime = 30;
input int ServerHourEndTime = 16 ; 
input int ServerMinuteEndTime = 33;
input double MinROCPercent = 0.18;

double OpenPrice = 0.0;
string MinROCVLine = "Min ROC. Candle";

double OpenPriceBuffer[];
double MinROCBuffer[];

#define OpenPriceBufferIndex 0
#define MinROCBufferIndex 1

int OnInit()
  {
   SetIndexBuffer(OpenPriceBufferIndex, OpenPriceBuffer);
   SetIndexLabel(OpenPriceBufferIndex, "Open Price");
   
   SetIndexBuffer(MinROCBufferIndex, MinROCBuffer);
   SetIndexLabel(MinROCBufferIndex, "Min. ROC from Time");
   
   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
      int i = Bars - IndicatorCounted() - 1;
      while (i >= 0)
      {     
         if (Hour() >= ServerHourStartTime && Minute() >= ServerMinuteStartTime && Hour() <= ServerHourEndTime && Minute() < ServerMinuteEndTime && DayOfWeek() > 0 && DayOfWeek() < 6) 
         {
            if (OpenPrice == 0.0) 
            {
               OpenPrice = Open[0];
            }
            
            double value = 0.0; 
            if (Close[0] > OpenPrice)
            {
               value = MathMax(High[0], Low[0]);
            } 
            else
            {
               value = MathMin(High[0], Low[0]);
            }
            
            double roc = ((value - OpenPrice) / OpenPrice) * 100;
            bool isMinROC = roc >= (MinROCPercent / 100) || roc <= -1 * (MinROCPercent / 100);
            if (isMinROC)
            {
               MinROCBuffer[i] = Close[0];
               ObjectCreate(ChartID(), MinROCVLine, OBJ_VLINE, 0, TimeCurrent(), Close[0]);
               ObjectSetInteger(ChartID(), MinROCVLine, OBJPROP_COLOR, clrPurple);
            }           
            else
            {
               MinROCBuffer[0] = NULL;
            }
            
            OpenPriceBuffer[i] = OpenPrice;
         }
         else 
         {
            OpenPrice = 0.0;
            MinROCBuffer[i] = NULL;
            OpenPriceBuffer[i] = NULL;
         } 
         
         i--;
      }
   return(rates_total);
  }
