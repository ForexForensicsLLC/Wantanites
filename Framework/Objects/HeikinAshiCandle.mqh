//+------------------------------------------------------------------+
//|                                                         HeikinAshiCandle.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class HeikinAshiCandle
{
private:
    int mType;
    datetime mCandleTime;

    double mOpen;
    double mClose;
    double mHigh;
    double mLow;

    bool mDrawn;

public:
    HeikinAshiCandle();
    HeikinAshiCandle(int type, int index, double open, double close, double high, double low);
    HeikinAshiCandle(HeikinAshiCandle &candle);
    ~HeikinAshiCandle();

    int Type() { return mType; }
    int Index() { return iBarShift(Symbol(), Period(), mCandleTime); }
    datetime CandleTime() { return mCandleTime; }

    double Open() { return mOpen; }
    double Close() { return mClose; }
    double High() { return mHigh; }
    double Low() { return mLow; }

    void Draw();
};
HeikinAshiCandle::HeikinAshiCandle()
{
}

HeikinAshiCandle::HeikinAshiCandle(int type, int index, double open, double close, double high, double low)
{
    mType = type;
    mCandleTime = iTime(Symbol(), Period(), index);

    mOpen = open;
    mClose = close;
    mHigh = high;
    mLow = low;

    mDrawn = false;
}

// this is just here so we can use HeikinAshiCandle in an ObjectList<>
HeikinAshiCandle::HeikinAshiCandle(HeikinAshiCandle &fractal)
{
}

HeikinAshiCandle::~HeikinAshiCandle()
{
}

void HeikinAshiCandle::Draw()
{
    if (mDrawn)
    {
        return;
    }

    mDrawn = true;
}