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

#include <Wantanites\Framework\Objects\DataStructures\List.mqh>
#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>
#include <Wantanites\Framework\Objects\DataObjects\EconomicEvent.mqh>

class EconomicCalendarHelper
{
private:
    static string Directory() { return "EconomicCalendar/"; }
    static string EventPath(datetime date);
    static string EventsDocument() { return "Events.Events.csv"; }

    template <typename TRecord>
    static void ReadEvents(string calendar, datetime utcStart, datetime utcEnd, datetime utcCurrent, ObjectList<EconomicEvent> *&economicEvents, List<string> *&titles,
                           List<string> *&symbols, List<int> *&impacts, bool ignoreDuplicateTimes);

public:
    template <typename TRecord>
    static void GetEventsBetween(string calendar, datetime utcStart, datetime utcEnd, ObjectList<EconomicEvent> *&economicEvents, List<string> *&titles,
                                 List<string> *&symbols, List<int> *&impacts, bool ignoreDuplicateTimes);
};

// returns a string in the format of /yyyy/MM/dd
string EconomicCalendarHelper::EventPath(datetime date)
{
    MqlDateTime dt = DateTimeHelper::ToMQLDateTime(date);
    return "/" + IntegerToString(dt.year) + "/" +
           DateTimeHelper::FormatAsTwoDigits(dt.mon) + "/" +
           DateTimeHelper::FormatAsTwoDigits(dt.day) + "/";
}

template <typename TRecord>
void EconomicCalendarHelper::ReadEvents(string calendar, datetime utcStart, datetime utcEnd, datetime utcCurrent, ObjectList<EconomicEvent> *&economicEvents,
                                        List<string> *&titles, List<string> *&symbols, List<int> *&impacts, bool ignoreDuplicateTimes)
{
    CSVRecordWriter<TRecord> *csvRecordWriter = new CSVRecordWriter<TRecord>(Directory() + calendar + EventPath(utcCurrent), EventsDocument(),
                                                                             true, false, false);
    csvRecordWriter.SeekToStart();

    TRecord *record = new TRecord();
    while (!FileIsEnding(csvRecordWriter.FileHandle()))
    {
        record.ReadRow(csvRecordWriter.FileHandle());

        // for some reason the Id header is read as some weird characters.
        // This finds it, and the first empty cell, by assuming all other Ids have their time appended to them (which they do)
        if (StringFind(record.Id, ".") == -1)
        {
            continue;
        }

        // Filter by Title
        if (!titles.IsEmpty() && !titles.Contains(record.Title))
        {
            continue;
        }

        // Filter by Symbol
        if (!symbols.IsEmpty() && !symbols.Contains(record.Symbol))
        {
            continue;
        }

        // Filter by Impact
        if (!impacts.IsEmpty() && !impacts.Contains(record.Impact))
        {
            continue;
        }

        // mql time is always in UTC+2 time
        record.Date = DateTimeHelper::UTCToMQLTime(record.Date);

        if (ignoreDuplicateTimes)
        {
            bool hasDuplicateTime = false;
            for (int i = 0; i < economicEvents.Size(); i++)
            {
                if (record.Date == economicEvents[i].Date())
                {
                    hasDuplicateTime = true;
                    break;
                }
            }

            if (hasDuplicateTime)
            {
                continue;
            }
        }

        EconomicEvent *tempEvent = new EconomicEvent(record);
        economicEvents.Add(tempEvent);
    }

    delete record;
    delete csvRecordWriter;
}

template <typename TRecord>
void EconomicCalendarHelper::GetEventsBetween(string calendar, datetime utcStart, datetime utcEnd, ObjectList<EconomicEvent> *&economicEvents, List<string> *&titles,
                                              List<string> *&symbols, List<int> *&impacts, bool ignoreDuplicateTimes = true)
{
    datetime currentDate = utcStart;
    while (DateTimeHelper::ToDay(currentDate) < DateTimeHelper::ToDay(utcEnd))
    {
        ReadEvents<TRecord>(calendar, utcStart, utcEnd, currentDate, economicEvents, titles, symbols, impacts, ignoreDuplicateTimes);
        currentDate += (60 * 60 * 24); // add one day in seconds
    }
}