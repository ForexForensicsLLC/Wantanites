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

    int mMaxUpperLevel;
    int mMaxLowerLevel;

    double mLevelDistance;

    int mCurrentLevel;
    double mBasePrice;

    void Init(int maxUpperLevels, int maxLowerLevels, double levelPips);

public:
    GridTracker(int maxLevels, double levelPips);
    GridTracker(int maxUpperLevels, int maxLowerLevels, double levelPips);
    ~GridTracker();

    double LevelDistance() { return mLevelDistance; }

    int MaxUpperLevels() { return mMaxUpperLevel; }
    int MaxLowerLevels() { return mMaxLowerLevel; }
    virtual bool AtMaxLevel();

    virtual double BasePrice() { return mBasePrice; }

    virtual double LevelPrice(int level);
    virtual int CurrentLevel();

    void Draw();
    virtual void Reset();
};

GridTracker::GridTracker(int maxLevels, double levelPips)
{
    Init(maxLevels, maxLevels, levelPips);
}

GridTracker::GridTracker(int maxUpperLevels, int maxLowerLevels, double levelPips)
{
    Init(maxUpperLevels, maxLowerLevels, levelPips);
}

GridTracker::~GridTracker()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

void GridTracker::Init(int maxUpperLevel, int maxLowerLevel, double levelPips)
{
    mDrawn = false;

    mMaxUpperLevel = maxUpperLevel;
    mMaxLowerLevel = maxLowerLevel;

    mLevelDistance = OrderHelper::PipsToRange(levelPips);
}

bool GridTracker::AtMaxLevel()
{
    int currentLevel = CurrentLevel();
    return currentLevel >= mMaxUpperLevel || currentLevel <= mMaxLowerLevel;
}

int GridTracker::CurrentLevel()
{
    if (mBasePrice == 0.0)
    {
        return 0;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
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

    if (mCurrentLevel > mMaxUpperLevel)
    {
        return mMaxUpperLevel;
    }
    else if (mCurrentLevel < mMaxLowerLevel)
    {
        return mMaxLowerLevel;
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