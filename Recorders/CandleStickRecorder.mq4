//+------------------------------------------------------------------+
//|                                                   MBRecorder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ObjectRecords\CandleStickRecord.mqh>

#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>

string Directory = "CandleStickRecords/" + Symbol() + "/";
string CSVName = IntegerToString(Period()) + ".csv";
CSVRecordWriter<CandleStickRecord> *CandleStickWriter;

int BarCount;

int OnInit()
{
    BarCount = 0;
    CandleStickWriter = new CSVRecordWriter<CandleStickRecord>(Directory, CSVName);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CandleStickWriter;
}

void OnTick()
{
    int bars = iBars(Symbol(), Period());
    if (bars > BarCount)
    {
        CandleStickRecord *record = new CandleStickRecord();

        record.Date = iTime(Symbol(), Period(), 1);
        record.Open = iOpen(Symbol(), Period(), 1);
        record.Close = iClose(Symbol(), Period(), 1);
        record.High = iHigh(Symbol(), Period(), 1);
        record.Low = iLow(Symbol(), Period(), 1);

        CandleStickWriter.WriteRecord(record);
        delete record;

        BarCount = bars;
    }
}