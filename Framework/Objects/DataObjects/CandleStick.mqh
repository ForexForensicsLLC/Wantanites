//+------------------------------------------------------------------+
//|                                                      CandleStick.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ObjectRecords\CandleStickRecord.mqh>

class CandleStick
{
private:
    datetime mDate;
    double mOpen;
    double mClose;
    double mHigh;
    double mLow;

public:
    CandleStick(CandleStickRecord &record);
    CandleStick(datetime date, double open, double close, double high, double low);
    ~CandleStick();

    string DisplayName() { return "CandleStick"; }

    datetime Date() { return mDate; }
    double Open() { return mOpen; }
    double Close() { return mClose; }
    double High() { return mHigh; }
    double Low() { return mLow; }
};

CandleStick::CandleStick(CandleStickRecord &record)
{
    mDate = record.Date;
    mOpen = record.Open;
    mClose = record.Close;
    mHigh = record.High;
    mLow = record.Low;
}

CandleStick::CandleStick(datetime date, double open, double close, double high, double low)
{
    mDate = date;
    mOpen = open;
    mClose = close;
    mHigh = high;
    mLow = low;
}

CandleStick::~CandleStick()
{
}
