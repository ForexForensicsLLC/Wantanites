//+------------------------------------------------------------------+
//|                                            HeikinAshiTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\ObjectList.mqh>
#include <Wantanites\Framework\Objects\HeikinAshiCandle.mqh>

class HeikinAshiTracker
{
private:
    int mBarsCalculated;

    // using an array here instead of an objectlist because I couldn't get the Push() method working on object list. TODO: could be a fun project to do on a rainy day
    HeikinAshiCandle *mCandles[];

    void Update();
    void Calculate(int barIndex);

    void CreateHeikinAshiCandle(int type, int index, double open, double close, double high, double low);

public:
    HeikinAshiTracker();
    ~HeikinAshiTracker();

    // --BEWARE-- this will be off by one in respect to the current actual bar index i.e [0] will be for the 1st previous bar
    HeikinAshiCandle *operator[](int index);
};

HeikinAshiTracker::HeikinAshiTracker()
{
    mBarsCalculated = 0;
    ArrayResize(mCandles, 0);

    Update();
}

HeikinAshiTracker::~HeikinAshiTracker()
{
    for (int i = 0; i < ArraySize(mCandles); i++)
    {
        delete mCandles[i];
    }
}

HeikinAshiCandle *HeikinAshiTracker::operator[](int index)
{
    Update();
    return mCandles[index];
}

void HeikinAshiTracker::Update()
{
    int currentBars = iBars(Symbol(), Period());
    int barIndex = currentBars - mBarsCalculated;

    for (int i = barIndex; i > 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = currentBars;
}

void HeikinAshiTracker::Calculate(int barIndex)
{
    int type = EMPTY;
    double barOpen = iOpen(Symbol(), Period(), barIndex);
    double barClose = iClose(Symbol(), Period(), barIndex);
    double barHigh = iHigh(Symbol(), Period(), barIndex);
    double barLow = iLow(Symbol(), Period(), barIndex);

    double heikinAshiOpen = 0.0;
    double heikinAshiClose = 0.0;
    double heikinAshiHigh = 0.0;
    double heikinAshiLow = 0.0;

    // first candle, can't use previous to calculate so i'll just set it to whatever the actual bar is
    if (ArraySize(mCandles) == 0)
    {
        type = barOpen > barClose ? OP_SELL : OP_BUY;
        CreateHeikinAshiCandle(type, barIndex, barOpen, barClose, barHigh, barLow);
    }
    else
    {
        heikinAshiOpen = NormalizeDouble((mCandles[0].Open() + mCandles[0].Close()) / 2, Digits);
        heikinAshiClose = NormalizeDouble((barOpen + barClose + barHigh + barLow) / 4, Digits);
        heikinAshiHigh = MathMax(barHigh, MathMax(heikinAshiOpen, heikinAshiClose));
        heikinAshiLow = MathMin(barLow, MathMin(heikinAshiOpen, heikinAshiClose));
        type = heikinAshiOpen > heikinAshiClose ? OP_SELL : OP_BUY;

        CreateHeikinAshiCandle(type, barIndex, heikinAshiOpen, heikinAshiClose, heikinAshiHigh, heikinAshiLow);
    }
}

void HeikinAshiTracker::CreateHeikinAshiCandle(int type, int index, double open, double close, double high, double low)
{
    // this only works because I don't calculate on tick, just on completed bars
    HeikinAshiCandle *candle = new HeikinAshiCandle(type, index, open, close, high, low);

    ArrayResize(mCandles, ArraySize(mCandles) + 1);
    ArrayCopy(mCandles, mCandles, 1, 0);
    mCandles[0] = candle;
}
