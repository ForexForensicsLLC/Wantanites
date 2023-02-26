//+------------------------------------------------------------------+
//|                                           Min ROC. From Time.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#property show_inputs
#property indicator_separate_window
#property indicator_buffers 6

input int MAPeriod = 12;

input string SymbolOneHeader = "==== Symbol One ====";
input string SymbolOne = "USDJPY";
input color SymbolOneColor = clrBlue;

input string SymbolTwoHeader = "==== Symbol Two ====";
input string SymbolTwo = "EURUSD";
input color SymbolTwoColor = clrOrange;

input string SymbolThreeHeader = "==== Symbol Three ====";
input string SymbolThree = "GBPUSD";
input color SymbolThreeColor = clrYellow;

input string SymbolFourHeader = "==== Symbol Four ====";
input string SymbolFour = "AUDUSD";
input color SymbolFourColor = clrGreen;

input string SymbolFiveHeader = "==== Symbol Five ====";
input string SymbolFive = "USDCAD";
input color SymbolFiveColor = clrPurple;

input string SymbolSixHeader = "==== Symbol Six ====";
input string SymbolSix = "NZDUSD";
input color SymbolSixColor = clrPink;

double SymbolOneBuffer[];
double SymbolTwoBuffer[];
double SymbolThreeBuffer[];
double SymbolFourBuffer[];
double SymbolFiveBuffer[];
double SymbolSixBuffer[];

#define SymbolOneBufferIndex 0
#define SymbolTwoBufferIndex 1
#define SymbolThreeBufferIndex 2
#define SymbolFourBufferIndex 3
#define SymbolFiveBufferIndex 4
#define SymbolSixBufferIndex 5

const int NumberOfSymbols = 6;
string Symbols[];

int OnInit()
{
    SetIndexBuffer(SymbolOneBufferIndex, SymbolOneBuffer);
    SetIndexLabel(SymbolOneBufferIndex, SymbolOne);
    IndicatorSetInteger(SymbolOneBufferIndex, INDICATOR_LEVELCOLOR, SymbolOneColor);

    SetIndexBuffer(SymbolTwoBufferIndex, SymbolTwoBuffer);
    SetIndexLabel(SymbolTwoBufferIndex, SymbolTwo);

    SetIndexBuffer(SymbolThreeBufferIndex, SymbolThreeBuffer);
    SetIndexLabel(SymbolThreeBufferIndex, SymbolThree);

    SetIndexBuffer(SymbolFourBufferIndex, SymbolFourBuffer);
    SetIndexLabel(SymbolFourBufferIndex, SymbolFour);

    SetIndexBuffer(SymbolFiveBufferIndex, SymbolFiveBuffer);
    SetIndexLabel(SymbolFiveBufferIndex, SymbolFive);

    SetIndexBuffer(SymbolSixBufferIndex, SymbolSixBuffer);
    SetIndexLabel(SymbolSixBufferIndex, SymbolSix);

    ArrayResize(Symbols, NumberOfSymbols);
    Symbols[0] = SymbolOne;
    Symbols[1] = SymbolTwo;
    Symbols[2] = SymbolThree;
    Symbols[3] = SymbolFour;
    Symbols[4] = SymbolFive;
    Symbols[5] = SymbolSix;

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
    while (i > 0)
    {
        // only calc if we have a valid symbol
        if (SymbolOne != "")
        {
            double value = 0.0;
            int symbolBars = iBars(SymbolOne, Period());

            // only calc if we have candles on the symbol we are trying to calc for
            if (symbolBars > i)
            {
                double distance = iOpen(SymbolOne, Period(), i) - iClose(SymbolOne, Period(), i);
                double pips = RangeToPips(SymbolOne, distance);
                // make sure we have enough previous values for our MA
                if (symbolBars - i > MAPeriod)
                {
                    double ma = 0.0;
                    for (int j = i; j < i + MAPeriod - 1; j++)
                    {
                        ma += SymbolOneBuffer[j];
                        Print("Buffer Value ", j, " ", SymbolOneBuffer[j]);
                    }

                    ma += pips;
                    ma /= MAPeriod;

                    value = ma;
                }
                else
                {
                    value = pips;
                }
            }

            SymbolOneBuffer[i] = value;
        }

        i -= 1;
    }

    return (rates_total);
}

double RangeToPips(string symbol, double range)
{
    return range * MathPow(10, MarketInfo(symbol, MODE_DIGITS) - 1);
}