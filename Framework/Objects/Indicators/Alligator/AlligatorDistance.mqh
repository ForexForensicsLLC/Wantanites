//+------------------------------------------------------------------+
//|                                            AlligatorDistance.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class AlligatorDistance
{
private:
    int mBarsCalculated;

    void Update();
    void Calculate(int barIndex);

public:
    AlligatorDistance();
    ~AlligatorDistance();
};

AlligatorDistance::AlligatorDistance()
{
    mBarsCalculated = 0;

    Update();
}

AlligatorDistance::~AlligatorDistance()
{
    ObjectsDeleteAll(ChartID(), "AlligatorDistance");
}

void AlligatorDistance::Update()
{
    int totalBars = iBars(Symbol(), Period());
    int start = totalBars - mBarsCalculated;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void AlligatorDistance::Calculate(int barIndex)
{
    double blueJaw = iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, barIndex);
    double redTeeth = iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, barIndex);
    double greenLips = iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, barIndex);

    double minGap = 0.00045;

    if (MathAbs(blueJaw - redTeeth) < minGap || MathAbs(redTeeth - greenLips) < minGap)
    {
        datetime barTime = iTime(Symbol(), Period(), barIndex);
        string name = "AlligatorDistance " + TimeToString(barTime);

        ObjectCreate(ChartID(), name, OBJ_VLINE, 0, barTime, Ask);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrRed);
        Print("Time: ", barTime, ", Blue Red Distance: ", MathAbs(blueJaw - redTeeth), ", Red Green Distance: ", MathAbs(redTeeth - greenLips));
    }
}
