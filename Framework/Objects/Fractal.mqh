//+------------------------------------------------------------------+
//|                                                         Fractal.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

enum FractalType
{
    Up,
    Down
};

class Fractal
{
private:
    string mObjectPrefix;

    datetime mCandleTime;
    FractalType mType;

    bool mDrawn;

public:
    Fractal(int index, FractalType type);
    Fractal(Fractal &fractal);
    ~Fractal();

    datetime CandleTime() { return mCandleTime; }
    FractalType Type() { return mType; }
    bool Drawn() { return mDrawn; }

    void Draw();
};

Fractal::Fractal(int index, FractalType type)
{
    mCandleTime = iTime(Symbol(), Period(), index);
    mType = type;
    mDrawn = false;

    mObjectPrefix = "Fractal " + TimeToString(mCandleTime);
}

// this is just here so we can use Fractal in an ObjectList<>
Fractal::Fractal(Fractal &fractal)
{
}

Fractal::~Fractal()
{
    ObjectsDeleteAll(ChartID(), mObjectPrefix);
}

void Fractal::Draw()
{
    if (mDrawn)
    {
        return;
    }

    int index = iBarShift(Symbol(), Period(), mCandleTime);
    double arrowOffset = 10 * MarketInfo(Symbol(), MODE_TICKSIZE);

    if (mType == FractalType::Up)
    {
        ObjectCreate(ChartID(), mObjectPrefix, OBJ_ARROW, 0, mCandleTime, iHigh(Symbol(), Period(), index) + arrowOffset);
        ObjectSetInteger(ChartID(), mObjectPrefix, OBJPROP_COLOR, clrChartreuse);
        ObjectSetInteger(ChartID(), mObjectPrefix, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
        ObjectSet(mObjectPrefix, OBJPROP_ARROWCODE, 241);
    }
    else if (mType == FractalType::Down)
    {
        ObjectCreate(ChartID(), mObjectPrefix, OBJ_ARROW, 0, mCandleTime, iLow(Symbol(), Period(), index) - arrowOffset);
        ObjectSetInteger(ChartID(), mObjectPrefix, OBJPROP_COLOR, clrOrangeRed);
        ObjectSetInteger(ChartID(), mObjectPrefix, OBJPROP_ANCHOR, ANCHOR_TOP);
        ObjectSet(mObjectPrefix, OBJPROP_ARROWCODE, 242);
    }

    mDrawn = true;
}