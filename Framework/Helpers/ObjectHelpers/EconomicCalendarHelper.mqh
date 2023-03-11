//+------------------------------------------------------------------+
//|                                                      EconomicCalendarHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ObjectRecords\EconomicEventRecord.mqh>

#include <Wantanites\Framwork\Objects\DataStructures\ObjectList.mqh>
#include <Wantanites\Framework\Objects\DataObjects\EcononmicEvent.mqh>

class EconomicCalendarHelper
{
private:
    static string Directory() { return "C:/Users/WantaTyler/source/repos/EconomicCalendar/Data/"; }
    static string EventPath(datetime date);
    static string EventsDocument() { return "Events.Events.csv"; }

    static string DateToPath(datetime date);
    static void ReadEvents(datetime utcStart, datetime utcEnd, datetime utcCurrent, string symbol, ImpactEnum impact, ObjectList<EconomicEvent> *&economicEvents);

public:
    static void GetEventsFrom(datetime utcStart, string symbol, ImpactEnum impact, ObjectList<EconomicEvent> *&economicEvents);
    static void GetEventsBetween(datetime utcStart, datetime utcEnd, string symbol, ImpactEnum impact, ObjectList<EconomicEvent> *&economicEvents);
};

EconomicCalendarHelper::EconomicCalendarHelper()
{
}

EconomicCalendarHelper::~EconomicCalendarHelper()
{
}

// returns a string in the format of yyyy/MM/dd
string EconomicCalendarHelper::EventPath(datetime date)
{
    string path = IntegerToString(TimeYear(date)) + "/" +
                  DateTimeHelper::FormatAsTwoDigits(TimeMonth(date)) + "/" +
                  DateTimeHelper::FormatAsTwoDigits(TimeDay(date)) + "/";
}

void EconomicCalendarHelper::ReadEvents(datetime utcStart, datetime utcEnd, datetime utcCurrent, string symbol, ImpactEnum impact, ObjectList<EconomicEvent> *&economicEvents)
{
    CSVRecordWriter<EconomicEvent> csvRecordWriter = new CSVRecordWriter(Directory + EventPath(utcCurrent), EventsDocument());
    csvRecordWriter.SeekToStart();

    EconomicEventRecord *record = new EconomicEventRecord();

    while (!FileIsEnding(csvRecordWriter.FileHandle()))
    {
        record.ReadRow(csvRecordWriter.FileHandle());

        // header row
        if (record.Id == "Id")
        {
            continue;
        }

        if (record.Date < utcStart || record.Date > utcEnd)
        {
            continue;
        }

        if (symbol != "" && record.Symbol != symbol)
        {
            continue;
        }

        if (impact != ImpactEnum::Unset && record.Impact != impact)
        {
            continue;
        }

        evnts.Add(new EconoimcEvent(record));
    }
}

void EconomicCalendarHelper::GetEventsFrom(datetime utcStart, string symbol = "", ImpactEnum impact = 0, ObjectList<EconomicEvent> *&economicEvents)
{
    return GetEventsBetween(utcStart, TimeGMT(), symbol, impact);
}

void EconomicCalendarHelper::GetEventsBetween(datetime utcStart, datetime utcEnd, string symbol = "", ImpactEnum impact = 0, ObjectList<EconomicEvent> *&economicEvents)
{
    datetime currentDate = utcStart;
    while (currentDate <= utcEnd)
    {
        ReadEvents(utcStart, utcEnd, currentDate, symbol, impact, economicEvents);
        currentDate += (60 * 60 * 24); // add one day in seconds
    }

    return events;
}