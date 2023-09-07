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

CSVRecordWriter<CandleStickRecord> *Writer;
int BarCount;
int CurrentDay;

int OnInit()
{
    BarCount = 0;
    CurrentDay = Day();

    InitWriter();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
    if (Day() != CurrentDay)
    {
        delete Writer;
        InitWriter();

        CurrentDay = Day();
    }

    int bars = iBars(Symbol(), Period());
    if (bars > BarCount)
    {
        CandleStickRecord *record = new CandleStickRecord();

        record.Date = iTime(Symbol(), Period(), 1);
        record.Open = iOpen(Symbol(), Period(), 1);
        record.Close = iClose(Symbol(), Period(), 1);
        record.High = iHigh(Symbol(), Period(), 1);
        record.Low = iLow(Symbol(), Period(), 1);

        Writer.WriteRecord(record);

        delete record;

        BarCount = bars;
    }
}

void InitWriter()
{
    string Directory = "CandleStickRecords/" + Symbol() + "/" + Period() + "/";
    string CSVName = IntegerToString(Year()) + "/" + IntegerToString(Month()) + "/" + IntegerToString(Day()) + ".csv";

    Writer = new CSVRecordWriter<CandleStickRecord>(Directory, CSVName);
}