//+------------------------------------------------------------------+
//|                                            GridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class GridTracker
{
protected:
    bool mDrawn;
    string mObjectNamePrefix;

    double mBasePrice;
    int mCurrentLevel;

    int mMaxUpperLevel;
    int mMaxLowerLevel;

    double mUpperLevelDistance;
    double mLowerLevelDistance;

    void InternalInit(double basePrice, int maxUpperLevels, int maxLowerLevels, double upperLevelDistance, double lowerLevelDistance);

public:
    GridTracker();
    GridTracker(int maxLevels, double levelPips);
    GridTracker(int maxUpperLevels, int maxLowerLevels, double levelPips);
    ~GridTracker();

    void ReInit(double basePrice, int maxUpperLevels, int maxLowerLevel, double upperLevelDistance, double lowerLevelDistance);

    int MaxUpperLevels() { return mMaxUpperLevel; }
    int MaxLowerLevels() { return mMaxLowerLevel; }
    virtual bool AtMaxLevel();

    double UpperLevelDistance() { return mUpperLevelDistance; }
    double LowerLevelDistance() { return mLowerLevelDistance; }

    virtual double BasePrice() { return mBasePrice; }

    virtual double LevelPrice(int level);
    virtual int CurrentLevel();

    void Draw();
    virtual void Reset();
};

GridTracker::GridTracker()
{
    Reset();
}

GridTracker::GridTracker(int maxLevels, double levelPips)
{
    InternalInit(0.0, maxLevels, maxLevels, levelPips, levelPips);
}

GridTracker::GridTracker(int maxUpperLevels, int maxLowerLevels, double levelPips)
{
    InternalInit(0.0, maxUpperLevels, maxLowerLevels, levelPips, levelPips);
}

GridTracker::~GridTracker()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

void GridTracker::InternalInit(double basePrice, int maxUpperLevels, int maxLowerLevels, double upperLevelDistance, double lowerLevelDistance)
{
    Reset();

    mBasePrice = basePrice;

    mMaxUpperLevel = maxUpperLevels;
    mMaxLowerLevel = -maxLowerLevels;

    mUpperLevelDistance = upperLevelDistance;
    mLowerLevelDistance = lowerLevelDistance;
}

void GridTracker::ReInit(double basePrice, int maxUpperLevels, int maxLowerLevel, double upperLevelDistance, double lowerLevelDistance)
{
    InternalInit(basePrice, maxUpperLevels, maxLowerLevel, upperLevelDistance, lowerLevelDistance);
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

    double currentPlace = 0;
    if (currentTick.bid == mBasePrice)
    {
        mCurrentLevel = 0;
    }
    else if (currentTick.bid > mBasePrice)
    {
        currentPlace = (currentTick.bid - mBasePrice) / mUpperLevelDistance;
        if (currentPlace >= mCurrentLevel + 1 && currentPlace <= mMaxUpperLevel)
        {
            mCurrentLevel += 1;
        }
    }
    else if (currentTick.bid < mBasePrice)
    {
        currentPlace = (currentTick.bid - mBasePrice) / mLowerLevelDistance;
        if (currentPlace <= mCurrentLevel - 1 && currentPlace >= mMaxLowerLevel)
        {
            mCurrentLevel -= 1;
        }
    }

    return mCurrentLevel;
}

double GridTracker::LevelPrice(int level)
{
    if (mBasePrice == 0.0)
    {
        return 0.0;
    }

    double price = 0.0;
    if (level == 0)
    {
        price = mBasePrice;
    }
    else if (level > 0)
    {
        price = mBasePrice + (mUpperLevelDistance * level);
    }
    else if (level < 0)
    {
        price = mBasePrice + (mLowerLevelDistance * level);
    }

    return price;
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

    ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(0), OBJ_TREND, 0, startTime, mBasePrice, endTime, mBasePrice);
    ObjectSet(mObjectNamePrefix + IntegerToString(0), OBJPROP_COLOR, clrAqua);

    for (int i = 1; i <= mMaxUpperLevel; i++)
    {
        linePriceUpper = mBasePrice + (mUpperLevelDistance * i);
        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(i), OBJ_TREND, 0, startTime, linePriceUpper, endTime, linePriceUpper);
    }

    for (int i = 1; i <= -mMaxLowerLevel; i++)
    {
        linePriceLower = mBasePrice - (mLowerLevelDistance * i);
        ObjectCreate(NULL, mObjectNamePrefix + IntegerToString(-i), OBJ_TREND, 0, startTime, linePriceLower, endTime, linePriceLower);
    }

    mDrawn = true;
}

void GridTracker::Reset()
{
    mBasePrice = 0.0;
    mCurrentLevel = 0;

    mMaxUpperLevel = 0;
    mMaxLowerLevel = 0;

    mUpperLevelDistance = 0.0;
    mLowerLevelDistance = 0.0;

    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
    mDrawn = false;
}