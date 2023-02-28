//+------------------------------------------------------------------+
//|                                            DonchianChannel.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Helpers\MQLHelper.mqh>

class DonchianChannel
{
private:
    string mObjectNamePrefix;
    int mBarsCalculated;
    int mBarsDrawn;

    int mPeriod;
    List<double> *mUpperChannel;
    List<double> *mMiddleChannel;
    List<double> *mLowerChannel;

    void Update();
    void Calculate(int barIndex);

public:
    DonchianChannel(int period);
    ~DonchianChannel();

    double UpperChannel(int index) { return mUpperChannel[index]; }
    double MiddleChannel(int index) { return mMiddleChannel[index]; }
    double LowerChannel(int index) { return mLowerChannel[index]; }

    void Draw();
};

DonchianChannel::DonchianChannel(int period)
{
    mObjectNamePrefix = "DonchianChannel-";
    mBarsCalculated = 0;
    mBarsDrawn = 0;
    mPeriod = period;

    mUpperChannel = new List<double>();
    mMiddleChannel = new List<double>();
    mLowerChannel = new List<double>();

    Update();
}

DonchianChannel::~DonchianChannel()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);

    delete mUpperChannel;
    delete mMiddleChannel;
    delete mLowerChannel;
}

void DonchianChannel::Update()
{
    int totalBars = iBars(Symbol(), Period());
    int start = totalBars - mBarsCalculated;

    for (int i = start; i > 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void DonchianChannel::Calculate(int barIndex)
{
    double highest = 0.0;
    double lowest = 0.0;
    if (!MQLHelper::GetHighestHighBetween(Symbol(), Period(), barIndex + mPeriod, barIndex, true, highest))
    {
        return;
    }

    if (!MQLHelper::GetLowestLowBetween(Symbol(), Period(), barIndex + mPeriod, barIndex, true, lowest))
    {
        return;
    }

    mUpperChannel.Push(highest);
    mMiddleChannel.Push((highest + lowest) / 2);
    mLowerChannel.Push(lowest);
}

void DonchianChannel::Draw()
{
    Update();

    int barsToDraw = mBarsCalculated - mBarsDrawn;
    for (int i = barsToDraw; i > 0; i--)
    {
        // can't do -1 to bars to draw or else we won't ever draw our most recent line
        if (i >= mUpperChannel.Size())
        {
            continue;
        }

        datetime nextBarTime = iTime(Symbol(), Period(), i - 1);
        datetime barTime = iTime(Symbol(), Period(), i);
        string barName = mObjectNamePrefix + TimeToString(barTime);

        string upperName = barName + "Upper";
        ObjectCreate(ChartID(), upperName, OBJ_TREND, 0, barTime, mUpperChannel[i], nextBarTime, mUpperChannel[i - 1]);
        ObjectSetInteger(ChartID(), upperName, OBJPROP_COLOR, clrAqua);
        ObjectSetInteger(ChartID(), upperName, OBJPROP_RAY_RIGHT, false);

        string middleName = barName + "Middle";
        ObjectCreate(ChartID(), middleName, OBJ_TREND, 0, barTime, mMiddleChannel[i], nextBarTime, mMiddleChannel[i - 1]);
        ObjectSetInteger(ChartID(), middleName, OBJPROP_COLOR, clrOrange);
        ObjectSetInteger(ChartID(), middleName, OBJPROP_RAY_RIGHT, false);

        string lowerName = barName + "Lower";
        ObjectCreate(ChartID(), lowerName, OBJ_TREND, 0, barTime, mLowerChannel[i], nextBarTime, mLowerChannel[i - 1]);
        ObjectSetInteger(ChartID(), lowerName, OBJPROP_COLOR, clrAqua);
        ObjectSetInteger(ChartID(), lowerName, OBJPROP_RAY_RIGHT, false);
    }

    mBarsDrawn = mBarsCalculated;
}
