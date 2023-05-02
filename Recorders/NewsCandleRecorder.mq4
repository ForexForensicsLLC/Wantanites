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
#include <Wantanites\Framework\Helpers\ObjectHelpers\EconomicCalendarHelper.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ObjectRecords\EconomicEventAndCandleRecord.mqh>

#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>

string Directory = "EconomicCalendar/EventsAndCandles/" + Symbol() + "/";
string CSVName = "Events.Events.csv";

ObjectList<EconomicEvent> *Events;
List<string> *Symbols;
List<string> *Titles;
List<int> *Impacts;

int CurrentDay = EMPTY;
datetime CurrentEventsDate = 0;

int OnInit()
{
    Events = new ObjectList<EconomicEvent>();
    Symbols = new List<string>();
    Titles = new List<string>();
    Impacts = new List<int>();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete Events;
    delete Symbols;
    delete Titles;
    delete Impacts;
}

void OnTick()
{
    if (Day() != CurrentDay)
    {
        RecordEvents();

        Events.Clear();
        CurrentEventsDate = 0;

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

    string datePath = TimeYear(CurrentEventsDate) + "/" +
                      DateTimeHelper::FormatAsTwoDigits(TimeMonth(CurrentEventsDate)) + "/" +
                      DateTimeHelper::FormatAsTwoDigits(TimeDay(CurrentEventsDate)) + "/";

    CSVRecordWriter<EconomicEventAndCandleRecord> *NewsCandleWriter = new CSVRecordWriter<EconomicEventAndCandleRecord>(Directory + datePath, CSVName);

    EconomicEventAndCandleRecord *record = new EconomicEventAndCandleRecord();
    for (int i = 0; i < Events.Size(); i++)
    {
        int barIndex = iBarShift(Symbol(), Period(), Events[i].Date());

        record.Id = Events[i].Id();
        Print("Before Title: ", Events[i].Title(), ", Date: ", Events[i].Date());
        record.Date = DateTimeHelper::MQLTimeToUTC(Events[i].Date());
        Print("After Title: ", Events[i].Title(), ", Date: ", record.Date);
        record.AllDay = Events[i].AllDay();
        record.Title = Events[i].Title();
        record.Symbol = Events[i].Symbol();
        record.Impact = Events[i].Impact();
        record.Forecast = Events[i].Forecast();
        record.Previous = Events[i].Previous();

        record.Open = iOpen(Symbol(), Period(), barIndex);
        record.Close = iClose(Symbol(), Period(), barIndex);
        record.High = iHigh(Symbol(), Period(), barIndex);
        record.Low = iLow(Symbol(), Period(), barIndex);

        NewsCandleWriter.WriteRecord(record);
    }

    delete NewsCandleWriter;
    delete record;
}

void LoadNewEvents()
{
    CurrentEventsDate = TimeGMT();

    // strip away hour and minute
    datetime startTime = DateTimeHelper::DayMonthYearToDateTime(TimeDay(CurrentEventsDate), TimeMonth(CurrentEventsDate), TimeYear(CurrentEventsDate));
    datetime endTime = startTime + (60 * 60 * 24);

    EconomicCalendarHelper::GetEventsBetween("JustEvents", startTime, endTime, Events, Titles, Symbols, Impacts, false);
}