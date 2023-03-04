//+------------------------------------------------------------------+
//|                                                   PipsChanged.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataStructures\List.mqh>

class PipsChanged
{
private:
    string mObjectNamePrefix;
    int mBarsCalculated;

    string mSymbol;
    int mTimeFrame;

    int mMAPeriod;
    color mPlotClr;

    List<double> *mPipsChanged;

    void Calculate(int barIndex);
    void Draw();

public:
    PipsChanged(string symbol, int timeFrame, int maPeriod, color plotClr);
    PipsChanged(PipsChanged &pc);
    ~PipsChanged();

    void Update();
};

PipsChanged::PipsChanged(string symbol, int timeFrame, int maPeriod, color plotClr)
{
    mObjectNamePrefix = "PipsChanged-" + symbol;
    mBarsCalculated = 0;

    mSymbol = symbol;
    mTimeFrame = timeFrame;

    mMAPeriod = maPeriod;
    mPlotClr = plotClr;

    mPipsChanged = new List<double>();

    Update();
}

PipsChanged::PipsChanged(PipsChanged &pc)
{
}

PipsChanged::~PipsChanged()
{
    delete mPipsChanged;
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix, 1);
}

void PipsChanged::Update()
{
    int totalBars = iBars(mSymbol, mTimeFrame);
    int barsToCalcualte = totalBars - mBarsCalculated;

    for (int i = barsToCalcualte; i > 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void PipsChanged::Calculate(int barIndex)
{
    double pipChange = iOpen(mSymbol, mTimeFrame, barIndex) - iClose(mSymbol, mTimeFrame, barIndex);
    mPipsChanged.Push(pipChange);

    Draw();
}

void PipsChanged::Draw()
{
    if (mPipsChanged.Size() <= mMAPeriod)
    {
        return;
    }

    double ma = 0.0;
    for (int i = 0; i < mMAPeriod; i++)
    {
        ma += mPipsChanged[i];
    }

    ma /= mMAPeriod;

    string name = mObjectNamePrefix + "_" + TimeToStr(TimeCurrent());
    ObjectCreate(ChartID(), name, OBJ_TREND, 1, TimeCurrent(), ma);
}
