//+------------------------------------------------------------------+
//|                                                      EconomicCalendarDB.mqh |
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

class EconomicCalendarDB
{
private:
    string Directory() { return "C:/Users/WantaTyler/source/repos/EconomicCalendar/WebScraper/Database/Data/"; }
    string DateToPath(datetime date);
    string EventsDocument() { return "Events.csv"; }

    string DateToPath(datetime date);
    void ReadEvents(datetime utcStart, datetime utcEnd, datetime utcCurrent, ObjectList<EconomicEvent> *&events, string symbol, ImpactEnum impact);

public:
    EconomicCalendarDB();
    ~EconomicCalendarDB();

    ObjectList<EconomicEvent> *GetEventsFrom(datetime utcStart, string symbol, ImpactEnum impact);
    ObjectList<EconomicEvent> *GetEventsBetween(datetime utcStart, datetime utcEnd, string symbol, ImpactEnum impact);
};

EconomicCalendarDB::EconomicCalendarDB()
{
}

EconomicCalendarDB::~EconomicCalendarDB()
{
}

// returns a string in the format of yyyy/MM/dd
string EconomicCalendarDB::DateToPath(datetime date)
{
    string path = IntegerToString(TimeYear(date)) + "/" +
                  DateTimeHelper::FormatAsTwoDigits(TimeMonth(date)) + "/" +
                  DateTimeHelper::FormatAsTwoDigits(TimeDay(date));
}

void EconomicCalendarDB::ReadEvents(datetime utcStart, datetime utcEnd, datetime utcCurrent, ObjectList<EconomicEvent> *&events, string symbol, ImpactEnum impact)
{
    CSVRecordWriter<EconomicEvent> csvRecordWriter = new CSVRecordWriter(Directory + DateToPath(utcCurrent), EventsDocument());
    csvRecordWriter.SeekToStart();

    EconomicEventRecord *record = new EconomicEventRecord();

    while (!FileIsEnding(csvRecordWriter.FileHandle()))
    {
        record.ReadRow(csvRecordWriter.FileHandle());

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

ObjectList<EconomicEvent> *EconomicCalendarDB::GetEventsFrom(datetime utcStart, string symbol = "", ImpactEnum impact = 0)
{
    return GetEventsBetween(utcStart, TimeGMT(), symbol, impact);
}

ObjectList<EconomicEvent> *EconomicCalendarDB::GetEventsBetween(datetime utcStart, datetime utcEnd, string symbol = "", ImpactEnum impact = 0)
{
    ObjectList<EconomicEvent> *events = new ObjectList<EconomicEvent>();

    datetime currentDate = utcStart;
    while (currentDate <= utcEnd)
    {
        ReadEvents(utcStart, utcEnd, currentDate, events, symbol, impact);
        currentDate += (60 * 60 * 24); // add one day in seconds
    }

    return events;
}