//+------------------------------------------------------------------+
//|                                           Min ROC. From Time.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#property indicator_chart_window
#property show_inputs
#property indicator_buffers 1

double EMABuffer[];
#define EMABufferIndex 0

int OnInit()
{
    SetIndexBuffer(EMABufferIndex, EMABuffer);
    SetIndexLabel(EMABufferIndex, "EMA");

    return (INIT_SUCCEEDED);
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
    double ema = 0.0;
    while (i >= 0)
    {
        datetime candleTime = iTime(Symbol(), Period(), i);
        if (TimeHour(candleTime) >= 16 && TimeMinute(candleTime) >= 30)
        {
            string timeString = TimeYear(candleTime) + "." + TimeMonth(candleTime) + "." + TimeDay(candleTime) + " " + TimeHour(candleTime) + ":" + TimeMinute(candleTime);
            datetime startTime = StringToTime(timeString);
            int startIndex = iBarShift(Symbol(), Period(), startTime);
            if (startIndex > 0)
            {
                Print("Start index: ", startIndex);
            }
            ema = iMA(Symbol(), Period(), startIndex, 0, MODE_EMA, PRICE_CLOSE, i);
        }

        EMABuffer[i] = ema;

        i--;
    }
    return (rates_total);
}
