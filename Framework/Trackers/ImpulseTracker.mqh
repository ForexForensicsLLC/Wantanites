//+------------------------------------------------------------------+
//|                                               ImpulseTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
class ImpulseTracker
{
private:
    int mBarsCalculated;

    double mMinPercentChange;
    int mNumberOfCandles;

    bool mHasImpulse;

    void Calculate(int barIndex);
    void Update();

public:
    ImpulseTracker(double minPercentChange, int numberOfCandles);
    ~ImpulseTracker();

    bool HasImpulse();
};

ImpulseTracker::ImpulseTracker(double minPercentChange, int numberOfCandles)
{
    mMinPercentChange = minPercentChange;
    mNumberOfCandles = numberOfCandles;

    Update();
}

ImpulseTracker::~ImpulseTracker()
{
    ObjectsDeleteAll(ChartID(), "Impulse");
}

void ImpulseTracker::Update()
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

void ImpulseTracker::Calculate(int barIndex)
{
    int start = barIndex + mNumberOfCandles;

    double impulseDownStart = MathMax(iOpen(Symbol(), Period(), start), iClose(Symbol(), Period(), start));
    double impulseUpStart = MathMin(iOpen(Symbol(), Period(), start), iClose(Symbol(), Period(), start));

    double impulseDownEnd = MathMin(iOpen(Symbol(), Period(), barIndex), iClose(Symbol(), Period(), barIndex));
    double impulseUpEnd = MathMax(iOpen(Symbol(), Period(), barIndex), iClose(Symbol(), Period(), barIndex));

    double impulseDownChange = MathAbs((impulseDownStart - impulseDownEnd) / impulseDownStart);
    double impulseUpChange = MathAbs((impulseUpStart - impulseUpEnd) / impulseUpStart);

    mHasImpulse = (impulseDownChange > (mMinPercentChange / 100)) || (impulseUpChange > (mMinPercentChange / 100));

    if (mHasImpulse)
    {
        datetime barTime = iTime(Symbol(), Period(), barIndex);
        string name = "Impulse " + TimeToString(barTime);

        if (!ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask))
        {
            Print(GetLastError());
        }
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrAqua);
    }
}

bool ImpulseTracker::HasImpulse()
{
    Update();
    return mHasImpulse;
}