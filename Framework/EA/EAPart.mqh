//+------------------------------------------------------------------+
//|                                                       EAPart.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class EAPart
{
private:
    bool mOnlyCalculateOnNewBar;
    int mBarsCalculated;

    bool mTicketWasActivatedSinceLastCheck;
    bool mTicketWasClosedSinceLastCheck;

public:
    EAPart(bool onlyCalculateOnNewBar);
    ~EAPart();

    bool HasNewBar();
};

EAPart::EAPart(bool onlyCalculateOnNewBar)
{
    mOnlyCalculateOnNewBar = onlyCalculateOnNewBar;
}

EAPart::~EAPart()
{
}

bool EAPart::HasNewBar(string symbol, int timeFrame)
{
}
