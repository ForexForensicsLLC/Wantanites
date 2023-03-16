//+------------------------------------------------------------------+
//|                                                   MBRecorder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\ObjectHelpers\EconomicCalendarHelper.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\Index.mqh>

string Directory = "Recorders/NewsCandleRecorder/";

CSVRecordWriter<DefaultErrorRecord> *NewsCandlesWriter;

ObjectList<EconomicEvent> *Events;
List<string> *Symbols;

int CurrentDay = EMPTY;

int OnInit()
{
    NewsCandlesWriter = new CSVRecordWriter<DefaultErrorRecord>(Directory, "NewsCandles.csv");
    Events = new ObjectList<EconomicEvent>();
    Symbols = new List<string>();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NewsCandlesWriter;
    delete Symbols;
    delete NewsCandlesWriter;
}

void OnTick()
{
    if (Day() != CurrentDay)
    {
        RecordEvents();
        Events.Clear();
        LoadNewEvents();
        CurrentDay = Day();
    }
}

void RecordEvents()
{
    if (Events.IsEmpty())
    {
        return;
    }

    DefaultErrorRecord *record = new DefaultErrorRecord();

    for (int i = 0; i < Events.Size(); i++)
    {
        int barIndex = iBarShift(Symbol(), Period(), Events[i].Date());
        record.ErrorTime = Events[i].Date();
        record.Symbol = Events[i].Symbol();
        record.AdditionalInformation = Events[i].Title() + " $ " + DoubleToString((iClose(Symbol(), Period(), barIndex) - iOpen(Symbol(), Period(), barIndex)), Digits());

        NewsCandlesWriter.WriteRecord(record);
    }

    delete record;
}

void LoadNewEvents()
{
    // strip away hour and minute
    datetime startTime = DateTimeHelper::DayMonthYearToDateTime(TimeDay(TimeGMT()), TimeMonth(TimeGMT()), TimeYear(TimeGMT()));
    datetime endTime = startTime + (60 * 60 * 24);

    EconomicCalendarHelper::GetEventsBetween(startTime, endTime, Events, Symbols, ImpactEnum::HighImpact, false);
}