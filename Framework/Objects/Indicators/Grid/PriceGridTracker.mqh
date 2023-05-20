//+------------------------------------------------------------------+
//|                                            PriceGridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\GridTracker.mqh>

#include <Wantanites\Framework\MQLVersionSpecific\Helpers\DateTimeHelper\DateTimeHelper.mqh>
#include <Wantanites\Framework\Helpers\OrderHelper.mqh>

class PriceGridTracker : public GridTracker
{
private:
public:
    PriceGridTracker();
    PriceGridTracker(int maxLevels, double levelPips);
    ~PriceGridTracker();

    void SetStartingPrice(double price);
    void SetStartingPriceMaxLevelsAndLevelPips(double startingPrice, double maxLevels, double levelPips);
    void SetStartingPriceUpperLevelsLowerLevelAndLevelPips(double startingPrice, int maxUpperLevels, int maxLowerlevels, double levelPips);
};

PriceGridTracker::PriceGridTracker() {}

PriceGridTracker::PriceGridTracker(int maxLevels, double levelPips) : GridTracker(maxLevels, levelPips)
{
    mObjectNamePrefix = "PriceGrid";
    Reset();
}

PriceGridTracker::~PriceGridTracker()
{
}

void PriceGridTracker::SetStartingPrice(double price)
{
    Reset();
    mBasePrice = price;
}

void PriceGridTracker::SetStartingPriceMaxLevelsAndLevelPips(double startingPrice, double maxLevels, double levelPips)
{
    Reset();
    Init(maxLevels, maxLevels, levelPips);
    mBasePrice = startingPrice;
}

void PriceGridTracker::SetStartingPriceUpperLevelsLowerLevelAndLevelPips(double startingPrice, int maxUpperLevels, int maxLowerlevels, double levelPips)
{
    Reset();
    Init(maxUpperLevels, maxLowerlevels, levelPips);
    mBasePrice = startingPrice;
}