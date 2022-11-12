//+------------------------------------------------------------------+
//|                                                     Strategy.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class Strategy
{
public:
    int mCurrentSetupTicket;
    ObjectList<Ticket> *mPreviousSetupTickets;

    int *mStrategyMagicNumbers[];

    int mMaxCurrentSetupTradesAtOnce;
    int mMaxTradesPerDay;
    double mStopLossPaddingPips;
    double mMaxSpreadPips;

public:
    Strategy();
    ~Strategy();

    double RiskPercent();
};

Strategy::Strategy()
{
}

Strategy::~Strategy()
{
}
