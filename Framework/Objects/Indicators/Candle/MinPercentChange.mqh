//+------------------------------------------------------------------+
//|                                             MinPercentChange.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class MinPercentChange
{
private:
    int mBarsCalcualted;
    double mMinPercentChange;
    bool mAllowImbalanceChain;

    void Update();
    void Calculate(int barIndex);

public:
    MinPercentChange(double minPercentChange);
    ~MinPercentChange();
};

MinPercentChange::MinPercentChange(double minPercentChange)
{
    mBarsCalcualted = 0;
    mMinPercentChange = minPercentChange;
    mAllowImbalanceChain = true;

    Update();
}

MinPercentChange::~MinPercentChange()
{
    ObjectsDeleteAll(ChartID(), "Percent Change");
}

void MinPercentChange::Update()
{
    int currentBars = iBars(Symbol(), Period());
    int start = currentBars - mBarsCalcualted;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }

    mBarsCalcualted = currentBars;
}

void MinPercentChange::Calculate(int barIndex)
{
    if (iOpen(Symbol(), Period(), barIndex) == 0)
    {
        return;
    }

    double percentChanged = 0.0;
    int count = 0;
    while (true)
    {
        bool bullish = iClose(Symbol(), Period(), barIndex + count) < iOpen(Symbol(), Period(), barIndex + count);
        percentChanged += MathAbs((iOpen(Symbol(), Period(), barIndex + count) - iClose(Symbol(), Period(), barIndex + count)) / iOpen(Symbol(), Period(), barIndex + count));

        if (bullish)
        {
            // no imbalance
            if (iHigh(Symbol(), Period(), barIndex + count + 2) > iLow(Symbol(), Period(), barIndex + count))
            {
                break;
            }
        }
        else
        {
            // no imbalance
            if (iLow(Symbol(), Period(), barIndex + count + 2) < iHigh(Symbol(), Period(), barIndex + count))
            {
                break;
            }
        }

        count += 1;
    }

    // double percentChanged = (iOpen(Symbol(), Period(), barIndex) - iClose(Symbol(), Period(), barIndex)) / iOpen(Symbol(), Period(), barIndex);
    if (MathAbs(percentChanged) >= (mMinPercentChange / 100))
    {
        datetime barTime = iTime(Symbol(), Period(), barIndex);
        string name = "Percent Change" + TimeToString(barTime);

        ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrBlue);
    }
}