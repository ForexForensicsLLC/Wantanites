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
#property indicator_buffers 3

input int Period = 9;
input double BandOffset = 200;

double EMABuffer[];
double UpperBandBuffer[];
double LowerBandBuffer[];

#define EMABufferIndex 0
#define UpperBandBufferIndex 1
#define LowerBandBufferIndex 2

int OnInit()
{
    SetIndexBuffer(EMABufferIndex, EMABuffer);
    SetIndexLabel(EMABufferIndex, "EMA");

    SetIndexBuffer(UpperBandBufferIndex, UpperBandBuffer);
    SetIndexLabel(UpperBandBufferIndex, "Upper Band");

    SetIndexBuffer(LowerBandBufferIndex, LowerBandBuffer);
    SetIndexLabel(LowerBandBufferIndex, "Lower Band");

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
    while (i >= 0)
    {
        double ema = iMA(Symbol(), Period(), 9, 0, MODE_EMA, PRICE_CLOSE, i);

        EMABuffer[i] = ema;
        UpperBandBuffer[i] = ema + BandOffset;
        LowerBandBuffer[i] = ema - BandOffset;

        i--;
    }
    return (rates_total);
}
