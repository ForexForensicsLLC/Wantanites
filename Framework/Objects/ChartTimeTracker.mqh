//+------------------------------------------------------------------+
//|                                             ChartTimeTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class ChartTimeTracker
{
private:
    int mBarsCalcualted;

    int mHours[];
    int mMinutes[];

    void Update();
    void Calculate(int barIndex);

public:
    ChartTimeTracker();
    ~ChartTimeTracker();

    void AddTime(int hour, int minute);
};

ChartTimeTracker::ChartTimeTracker()
{
    mBarsCalcualted = 0;
    ArrayResize(mHours, 0);
    ArrayResize(mMinutes, 0);
}

ChartTimeTracker::~ChartTimeTracker()
{
    ObjectsDeleteAll(ChartID(), "Time");
}

void ChartTimeTracker::AddTime(int hour, int minute)
{
    ArrayResize(mHours, ArraySize(mHours) + 1);
    mHours[ArraySize(mHours) - 1] = hour;

    ArrayResize(mMinutes, ArraySize(mMinutes) + 1);
    mMinutes[ArraySize(mMinutes) - 1] = minute;

    mBarsCalcualted = 0;

    Update();
}

void ChartTimeTracker::Update()
{
    int currentBars = iBars(Symbol(), Period());
    int start = currentBars - mBarsCalcualted;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }
}

void ChartTimeTracker::Calculate(int barIndex)
{
    datetime barTime = iTime(Symbol(), Period(), barIndex);

    for (int i = 0; i < ArraySize(mHours); i++)
    {
        if (TimeHour(barTime) == mHours[i] && TimeMinute(barTime) == mMinutes[i])
        {
            string name = "Time" + TimeToString(barTime);

            ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
            ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrBlack);
        }
    }
}