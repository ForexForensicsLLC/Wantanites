//+------------------------------------------------------------------+
//|                                            PriceGridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\DateTimeHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class PriceGridTracker
{
private:
    string mObjectNamePrefix;

    bool mDrawn;

    int mMaxLevels;
    double mLevelDistance;

    int mCurrentLevel;
    double mBasePrice;

public:
    PriceGridTracker(int maxLevels, double levelPips);
    ~PriceGridTracker();

    void SetStartingPrice(double price);
    void SetStartingPriceAndLevelPips(double startingPrice, double levelPips);

    double LevelPrice(int level);
    int CurrentLevel();

    void Draw();
    void Reset();
};

PriceGridTracker::PriceGridTracker(int maxLevels, double levelPips)
{
    mObjectNamePrefix = "PriceGrid";

    mMaxLevels = maxLevels;
    mLevelDistance = OrderHelper::PipsToRange(levelPips);

    Reset();
}

PriceGridTracker::~PriceGridTracker()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

void PriceGridTracker::SetStartingPrice(double price)
{
    Reset();
    mBasePrice = price;
}

void PriceGridTracker::SetStartingPriceAndLevelPips(double startingPrice, double levelPips)
{
    Reset();
    mBasePrice = startingPrice;
    mLevelDistance = OrderHelper::PipsToRange(levelPips);
}

int PriceGridTracker::CurrentLevel()
{
    if (mBasePrice == 0.0)
    {
        Print("No Base Price");
        return 0;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        Print("Can't get tick");
        return 0;
    }

    double currentPlace = (currentTick.bid - mBasePrice) / mLevelDistance;
    if (currentPlace >= mCurrentLevel + 1)
    {
        mCurrentLevel += 1;
    }
    else if (currentPlace <= mCurrentLevel - 1)
    {
        mCurrentLevel -= 1;
    }

    if (mCurrentLevel > mMaxLevels)
    {
        return mMaxLevels;
    }
    else if (mCurrentLevel < -mMaxLevels)
    {
        return -mMaxLevels;
    }

    return mCurrentLevel;
}

double PriceGridTracker::LevelPrice(int level)
{
    if (mBasePrice == 0.0)
    {
        return 0.0;
    }

    return mBasePrice + (mLevelDistance * level);
}

void PriceGridTracker::Reset()
{
    mBasePrice = 0.0;
    mCurrentLevel = 0;

    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
    mDrawn = false;
}

void PriceGridTracker::Draw()
{
    if (mDrawn || mBasePrice == 0)
    {
        return;
    }

    double linePriceUpper = 0.0;
    double linePriceLower = 0.0;

    datetime startTime = iTime(Symbol(), Period(), 0);
    datetime endTime = iTime(Symbol(), Period(), -30);

    for (int i = 1; i <= mMaxLevels; i++)
    {
        linePriceUpper = mBasePrice + (mLevelDistance * i);
        linePriceLower = mBasePrice - (mLevelDistance * i);

        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(i), OBJ_TREND, 0, startTime, linePriceUpper, endTime, linePriceUpper);
        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(-i), OBJ_TREND, 0, startTime, linePriceLower, endTime, linePriceLower);
    }

    mDrawn = true;
}