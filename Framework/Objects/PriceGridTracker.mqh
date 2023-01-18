//+------------------------------------------------------------------+
//|                                            PriceGridTracker.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\GridTracker.mqh>

#include <SummitCapital\Framework\Helpers\DateTimeHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class PriceGridTracker : public GridTracker
{
private:
public:
    PriceGridTracker(int maxLevels, double levelPips);
    ~PriceGridTracker();

    void SetStartingPrice(double price);
    void SetStartingPriceMaxLevelsAndLevelPips(double startingPrice, double maxLevels, double levelPips);
};

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
    Init(maxLevels, levelPips);
    mBasePrice = startingPrice;
}