//+------------------------------------------------------------------+
//|                                                      Partial.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class Partial
{
public:
    double mRR;
    double mPercent;
    bool mWasTaken;

public:
    Partial(double rr, double percent);
    Partial(Partial &partial);
    ~Partial();

    double PercentAsDecimal() { return mPercent / 100; }
};

Partial::Partial(double rr, double percent)
{
    mRR = rr;
    mPercent = percent;
    mWasTaken = false;
}

Partial::Partial(Partial &partial)
{
    mRR = partial.mRR;
    mPercent = partial.mPercent;
    mWasTaken = partial.mWasTaken;
}

Partial::~Partial()
{
}
