//+------------------------------------------------------------------+
//|                                                      EconomicEvent.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataStructures\JSON.mqh>

class EconomicEvent
{
private:
    datetime mDate;
    bool mAllDay;
    string mTitle;
    string mSymbol;
    int mImpact;
    string mForecast;
    string mPrevious;

public:
    EconomiceEvent(JSON &json);
    EconomicEvent(EconomicEvent &e);
    ~EconomicEvent();

    datetime Date() { return mDate; }
    bool AllDay() { return mAllDay; }
    string Title() { return mTitle; }
    string Symbol() { return mSymbol; }
    int Impact() { return mImpact; }
    string Forecast() { return mForecast; }
    string Previous() { return mPrevious; }
};

EconomicEvent::EconomiceEvent(JSON &json)
{
}

EconomicEvent::EconomicEvent(EconomicEvent &e)
{
    mDate = e.Date();
    mAllDay = e.AllDay();
    mTitle = e.Title();
    mSymbol = e.Symbol();
    mImpact = e.Impact();
    mForecast = e.Forecast();
    mPrevious = e.Previous();
}

EconomicEvent::~EconomicEvent()
{
}
