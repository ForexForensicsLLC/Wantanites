//+------------------------------------------------------------------+
//|                                               SuperTrend.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\List.mqh>

class SuperTrend
{
private:
    string mObjectNamePrefix;
    int mBarsCalculated;
    int mBarsDrawn;

    int mCurrentDirection;

    List<double> *mSuperTrendLine;
    List<double> *mUpperBand;
    List<double> *mLowerBand;

    int mATRPeriod;
    double mFactor;

    void Update();
    void Calculate(int barIndex);

public:
    SuperTrend(int atrPeriod, double factor);
    ~SuperTrend();

    // -- BEWARE -- these will be off by 1, i.e index 0 = bar 1 since I only calcuate on closed bars
    double UpperBand(int index);
    double LowerBand(int index);

    int Direction() { return mCurrentDirection; }

    void Draw();
};

SuperTrend::SuperTrend(int atrPeriod, double factor)
{
    mObjectNamePrefix = "SuperTrend";
    mBarsCalculated = 0;
    mBarsDrawn = 0;

    mCurrentDirection = EMPTY;

    mSuperTrendLine = new List<double>();
    mUpperBand = new List<double>();
    mLowerBand = new List<double>();

    mATRPeriod = atrPeriod;
    mFactor = factor;

    Update();
}

SuperTrend::~SuperTrend()
{
    delete mUpperBand;
    delete mLowerBand;
    delete mSuperTrendLine;

    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

double SuperTrend::UpperBand(int index)
{
    Update();
    return mUpperBand[index];
}

double SuperTrend::LowerBand(int index)
{
    Update();
    return mLowerBand[index];
}

void SuperTrend::Update()
{
    int currentBars = iBars(Symbol(), Period());
    int barIndex = currentBars - mBarsCalculated;

    for (int i = barIndex; i > 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = currentBars;
}

// this is only fine because I don't calcute on the current bar. otherwise this would add a new value for each tick and things would get messed up
void SuperTrend::Calculate(int barIndex)
{
    double medianPrice = (iHigh(Symbol(), Period(), barIndex) + iLow(Symbol(), Period(), barIndex)) / 2;
    double atr = iATR(Symbol(), Period(), mATRPeriod, barIndex);

    double upperBand = medianPrice + (mFactor * atr);
    double lowerBand = medianPrice - (mFactor * atr);

    // first point, just default everything
    if (mUpperBand.Size() == 0 && mLowerBand.Size() == 0 && mSuperTrendLine.Size() == 0)
    {
        mUpperBand.Push(upperBand);
        mLowerBand.Push(lowerBand);
        mSuperTrendLine.Push(upperBand);

        return;
    }

    if (iClose(Symbol(), Period(), barIndex) < mSuperTrendLine[0])
    {
        mCurrentDirection = OP_SELL;
    }
    else if (iClose(Symbol(), Period(), barIndex) > mSuperTrendLine[0])
    {
        mCurrentDirection = OP_BUY;
    }

    if (mCurrentDirection == OP_BUY)
    {
        if (upperBand > mUpperBand[0])
        {
            mUpperBand.Push(upperBand);
        }
        else
        {
            mUpperBand.Push(mUpperBand[0]);
        }

        if (lowerBand > mLowerBand[0])
        {
            mLowerBand.Push(lowerBand);
        }
        else
        {
            mLowerBand.Push(mLowerBand[0]);
        }

        mSuperTrendLine.Push(mLowerBand[0]);
    }
    else if (mCurrentDirection == OP_SELL)
    {
        if (lowerBand < mLowerBand[0])
        {
            mLowerBand.Push(lowerBand);
        }
        else
        {
            mLowerBand.Push(mLowerBand[0]);
        }

        if (upperBand < mUpperBand[0])
        {
            mUpperBand.Push(upperBand);
        }
        else
        {
            mUpperBand.Push(mUpperBand[0]);
        }

        mSuperTrendLine.Push(mUpperBand[0]);
    }
}

void SuperTrend::Draw()
{
    Update();

    int barsToDraw = mBarsCalculated - mBarsDrawn;

    for (int i = barsToDraw; i > 0; i--)
    {
        // can't do -1 to bars to draw or else we won't ever draw our most recent line
        if (i >= mSuperTrendLine.Size())
        {
            continue;
        }

        datetime nextBarTime = iTime(Symbol(), Period(), i - 1);
        datetime barTime = iTime(Symbol(), Period(), i);
        string name = mObjectNamePrefix + TimeToString(barTime);
        color clr = iClose(Symbol(), Period(), i) < mSuperTrendLine[i] ? clrOrangeRed : clrChartreuse;

        ObjectCreate(ChartID(), name, OBJ_TREND, 0, barTime, mSuperTrendLine[i], nextBarTime, mSuperTrendLine[i - 1]);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);

        ObjectSetInteger(ChartID(), name, OBJPROP_RAY_RIGHT, false);
    }

    mBarsDrawn = mBarsCalculated;
}
