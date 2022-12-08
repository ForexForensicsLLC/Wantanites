//+------------------------------------------------------------------+
//|                                               FractalTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
class FractalTracker
{
private:
    int mBarsCalculated;
    int mPeriod;

    void Calculate(int barIndex);
    void Update();
    void DrawFractals();

public:
    FractalTracker();
    ~FractalTracker();

    bool HasImpulse();
};

FractalTracker::FractalTracker(int period)
{
    mPeriod = period;
    Update();
}

FractalTracker::~FractalTracker()
{
    ObjectsDeleteAll(ChartID(), "Fractal");
}

void FractalTracker::Update()
{
    int currentBars = iBars(Symbol(), Period());
    int barIndex = currentBars - mBarsCalculated;

    if (barIndex <= 0)
    {
        return;
    }

    for (int i = barIndex; i > 0; i--)
    {
        if (i + mNumberOfCandles + 1 > currentBars)
        {
            continue;
        }

        Calculate(i);
    }

    mBarsCalculated = currentBars;
}

void FractalTracker::Calculate(int barIndex)
{
}