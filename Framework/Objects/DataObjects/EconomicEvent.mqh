//+------------------------------------------------------------------+
//|                                                      EconomicEvent.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ObjectRecords\EconomicEventRecord.mqh>

enum ImpactEnum
{
    Unset = 0,
    LowImpact = 1,
    MediumImpact = 2,
    HighImpact = 3,
    Holiday = 4
};

class EconomicEvent
{
private:
    string mId;
    datetime mDate;
    bool mAllDay;
    string mTitle;
    string mSymbol;
    ImpactEnum mImpact;
    string mForecast;
    string mPrevious;

public:
    EconomicEvent(EconomicEventRecord &record);
    EconomicEvent(EconomicEvent &e);
    ~EconomicEvent();

    string Id() { return mId; }
    datetime Date() { return mDate; }
    bool AllDay() { return mAllDay; }
    string Title() { return mTitle; }
    string Symbol() { return mSymbol; }
    ImpactEnum Impact() { return mImpact; }
    string Forecast() { return mForecast; }
    string Previous() { return mPrevious; }
};

EconomicEvent::EconomicEvent(EconomicEventRecord &record)
{
    mId = record.Id;
    mDate = record.Date;
    mAllDay = record.AllDay;
    mTitle = record.Title;
    mSymbol = record.Symbol;
    mImpact = record.Impact;
    mForecast = record.Forecast;
    mPrevious = record.Previous;
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
