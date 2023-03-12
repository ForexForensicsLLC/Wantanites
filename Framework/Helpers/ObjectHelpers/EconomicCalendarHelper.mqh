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

#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>
#include <Wantanites\Framework\Objects\DataObjects\EconomicEvent.mqh>

class EconomicCalendarHelper
{
private:
    static string Directory() { return "EconomicCalendar/"; }
    static string EventPath(datetime date);
    static string EventsDocument() { return "Events.Events.csv"; }

    static void ReadEvents(datetime utcStart, datetime utcEnd, datetime utcCurrent, ObjectList<EconomicEvent> *&economicEvents, string symbol, ImpactEnum impact);

public:
    static void GetEventsBetween(datetime utcStart, datetime utcEnd, ObjectList<EconomicEvent> *&economicEvents, string symbol, ImpactEnum impact);
};

// returns a string in the format of yyyy/MM/dd
string EconomicCalendarHelper::EventPath(datetime date)
{
    return IntegerToString(TimeYear(date)) + "/" +
           DateTimeHelper::FormatAsTwoDigits(TimeMonth(date)) + "/" +
           DateTimeHelper::FormatAsTwoDigits(TimeDay(date)) + "/";
}

void EconomicCalendarHelper::ReadEvents(datetime utcStart, datetime utcEnd, datetime utcCurrent, ObjectList<EconomicEvent> *&economicEvents, string symbol, ImpactEnum impact)
{
    CSVRecordWriter<EconomicEventRecord> *csvRecordWriter = new CSVRecordWriter<EconomicEventRecord>(Directory() + EventPath(utcCurrent), EventsDocument());
    csvRecordWriter.SeekToStart();

    EconomicEventRecord *record = new EconomicEventRecord();
    while (!FileIsEnding(csvRecordWriter.FileHandle()))
    {
        record.ReadRow(csvRecordWriter.FileHandle());

        // for some reason the Id header is read as some weird characters.
        // This finds it, and the first empty cell by assuming all other Ids have the time appended to them (which they do)
        if (StringFind(record.Id, ".") == -1)
        {
            continue;
        }

        // Filter by Symbol
        if (symbol != "" && record.Symbol != symbol)
        {
            continue;
        }

        // Filter by Impact
        if (impact != ImpactEnum::Unset && record.Impact != impact)
        {
            continue;
        }

        EconomicEvent *tempEvent = new EconomicEvent(record);
        economicEvents.Add(tempEvent);
    }

    delete record;
    delete csvRecordWriter;
}

void EconomicCalendarHelper::GetEventsBetween(datetime utcStart, datetime utcEnd, ObjectList<EconomicEvent> *&economicEvents, string symbol = "", ImpactEnum impact = 0)
{
    datetime currentDate = utcStart;
    while (TimeDay(currentDate) < TimeDay(utcEnd))
    {
        ReadEvents(utcStart, utcEnd, currentDate, economicEvents, symbol, impact);
        currentDate += (60 * 60 * 24); // add one day in seconds
    }
}