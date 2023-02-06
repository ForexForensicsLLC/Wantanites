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

    int type = EMPTY;
    for (int i = start; i >= barIndex; i--)
    {
        if (i == start)
        {
            if (iOpen(Symbol(), Period(), i) > iClose(Symbol(), Period(), i))
            {
                type = OP_SELL;
            }
            else
            {
                type = OP_BUY;
            }
        }
        else
        {
            if (type == OP_BUY)
            {
                // have a bearish candle, return
                if (iOpen(Symbol(), Period(), i) > iClose(Symbol(), Period(), i))
                {
                    return;
                }
            }
            else if (type == OP_SELL)
            {
                // have a bullish candle, return
                if (iOpen(Symbol(), Period(), i) < iClose(Symbol(), Period(), i))
                {
                    return;
                }
            }
        }
    }

    bool hasImpulse = false;
    if (type == OP_BUY)
    {
        double impulseUpStart = MathMin(iOpen(Symbol(), Period(), start), iClose(Symbol(), Period(), start));
        double impulseUpEnd = MathMax(iOpen(Symbol(), Period(), barIndex), iClose(Symbol(), Period(), barIndex));
        double impulseUpChange = MathAbs((impulseUpStart - impulseUpEnd) / impulseUpStart);

        if (impulseUpChange > (mMinPercentChange / 100))
        {
            datetime barTime = iTime(Symbol(), Period(), barIndex);
            string name = "Impulse " + TimeToString(barTime);

            if (!ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask))
            {
                Print(GetLastError());
            }
            ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrYellow);
        }
    }
    else if (type == OP_SELL)
    {
        double impulseDownStart = MathMax(iOpen(Symbol(), Period(), start), iClose(Symbol(), Period(), start));
        double impulseDownEnd = MathMin(iOpen(Symbol(), Period(), barIndex), iClose(Symbol(), Period(), barIndex));
        double impulseDownChange = MathAbs((impulseDownStart - impulseDownEnd) / impulseDownStart);

        if (impulseDownChange > (mMinPercentChange / 100))
        {
            datetime barTime = iTime(Symbol(), Period(), barIndex);
            string name = "Impulse " + TimeToString(barTime);

            if (!ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask))
            {
                Print(GetLastError());
            }
            ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrPurple);
        }
    }
}

bool ImpulseTracker::HasImpulse()
{
    Update();
    return mHasImpulse;
}