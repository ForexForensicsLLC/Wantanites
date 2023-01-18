//+------------------------------------------------------------------+
//|                                            GridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\DateTimeHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class GridTracker
{
protected:
    string mObjectNamePrefix;

    bool mDrawn;

    int mMaxLevel;
    double mLevelDistance;

    int mCurrentLevel;
    double mBasePrice;

    void Init(int maxLevels, double levelPips);

public:
    GridTracker(int maxLevels, double levelPips);
    ~GridTracker();

    int MaxLevel() { return mMaxLevel; }
    bool AtMaxLevel() { return MathAbs(CurrentLevel()) >= mMaxLevel; }

    double LevelPrice(int level);
    int CurrentLevel();

    void Draw();
    virtual void Reset();
};

GridTracker::GridTracker(int maxLevels, double levelPips)
{
    Init(maxLevels, levelPips);
}

GridTracker::~GridTracker()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

void GridTracker::Init(int maxLevels, double levelPips)
{
    mDrawn = false;

    mMaxLevel = maxLevels;
    mLevelDistance = OrderHelper::PipsToRange(levelPips);
}

int GridTracker::CurrentLevel()
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

    if (mCurrentLevel > mMaxLevel)
    {
        return mMaxLevel;
    }
    else if (mCurrentLevel < -mMaxLevel)
    {
        return -mMaxLevel;
    }

    return mCurrentLevel;
}

double GridTracker::LevelPrice(int level)
{
    if (mBasePrice == 0.0)
    {
        return 0.0;
    }

    return mBasePrice + (mLevelDistance * level);
}

void GridTracker::Draw()
{
    if (mDrawn || mBasePrice == 0)
    {
        return;
    }

    double linePriceUpper = 0.0;
    double linePriceLower = 0.0;

    datetime startTime = iTime(Symbol(), Period(), 0);
    datetime endTime = iTime(Symbol(), Period(), -30);

    for (int i = 1; i <= mMaxLevel; i++)
    {
        linePriceUpper = mBasePrice + (mLevelDistance * i);
        linePriceLower = mBasePrice - (mLevelDistance * i);

        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(i), OBJ_TREND, 0, startTime, linePriceUpper, endTime, linePriceUpper);
        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(-i), OBJ_TREND, 0, startTime, linePriceLower, endTime, linePriceLower);
    }

    mDrawn = true;
}

void GridTracker::Reset()
{
    mBasePrice = 0.0;
    mCurrentLevel = 0;

    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
    mDrawn = false;
}