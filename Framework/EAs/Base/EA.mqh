//+------------------------------------------------------------------+
//|                                                           EA.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EAs\Base\IEA.mqh>

class EA : IEA
{
protected:
    bool mStopTrading;
    bool mHasSetup;
    bool mWasReset;

    int mMaxTradesPerStrategy;
    int mStopLossPaddingPips;
    int mMaxSpreadPips;
    double mRiskPercent;

    int mStrategyMagicNumbers[];

public:
    EA(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent);
    ~EA();

    virtual void FillStrategyMagicNumber();
    virtual void Manage();
    virtual void CheckInvalidateSetup();
    virtual bool AllowedToTrade();
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void CheckSetSetup();
    virtual void Reset();
    virtual void Run();
};

EA::EA(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent)
{
    mStopTrading = false;
    mHasSetup = false;
    mWasReset = false;

    mMaxTradesPerStrategy = maxTradesPerStrategy;
    mStopLossPaddingPips = stopLossPaddingPips;
    mMaxSpreadPips = maxSpreadPips;
    mRiskPercent = riskPercent;
}
