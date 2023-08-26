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
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>
#include <Wantanites\Framework\Objects\Indicators\Candle\CandleStick.mqh>
#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>

class CandleStickTracker
{
private:
    MqlDateTime mLastRequestedDate;
    ObjectList<CandleStick> *mCandleSticks;

    string Directory() { return "CandleStickRecords/" + Symbol() + "/" + Period() + "/"; }
    string CSVName(MqlDateTime &requestedTime) { return IntegerToString(requestedTime.year) + "/" + IntegerToString(requestedTime.mon) + "/" + IntegerToString(requestedTime.day) + ".csv"; }

    void ReadCandleSticks(datetime requestedDate, ObjectList<CandleStick> *&tempCandleSticks);
    bool PriceReachesXBeforeYLoop(SignalType signalType, datetime requestedDateTime, double x, double y, ObjectList<CandleStick> *&tempCandleSticks);

public:
    CandleStickTracker();
    ~CandleStickTracker();

    bool PriceReachesXBeforeY(SignalType signalType, MqlDateTime &requestedDate, double x, double y);
};

CandleStickTracker::CandleStickTracker()
{
    mLastRequestedDate = DateTimeHelper::ToMQLDateTime(0);
    mCandleSticks = new ObjectList<CandleStick>();
}

CandleStickTracker::~CandleStickTracker()
{
    delete mCandleSticks;
}

void CandleStickTracker::ReadCandleSticks(datetime requestedDate, ObjectList<CandleStick> *&tempCandleSticks)
{
    MqlDateTime mqlDT = DateTimeHelper::ToMQLDateTime(requestedDate);

    CandleStickRecord *record = new CandleStickRecord();
    CSVRecordWriter<CandleStickRecord> *writer = new CSVRecordWriter<CandleStickRecord>(Directory(), CSVName(mqlDT), FileOperation::ReadingExisting, false, false);

    while (!FileIsEnding(writer.FileHandle()))
    {
        record.ReadRow(writer.FileHandle());

        // first record is an invalid one, just skip it
        if (record.Open == 0)
        {
            continue;
        }

        CandleStick *cs = new CandleStick(record);

        mCandleSticks.Add(cs);
        tempCandleSticks.Add(cs);
    }

    delete record;
    delete writer;
}

bool CandleStickTracker::PriceReachesXBeforeY(SignalType signalType, MqlDateTime &requestedDate, double x, double y)
{
    bool loadRequestedDateRecords = false;

    // new requested day is greater than previous day, we no longer need old records
    if (requestedDate.year > mLastRequestedDate.year)
    {
        mCandleSticks.Clear();
        loadRequestedDateRecords = true;
    }
    else if (requestedDate.year == mLastRequestedDate.year)
    {
        if (requestedDate.mon > mLastRequestedDate.mon)
        {
            mCandleSticks.Clear();
            loadRequestedDateRecords = true;
        }
        else if (requestedDate.mon == mLastRequestedDate.mon)
        {
            if (requestedDate.day > mLastRequestedDate.day)
            {
                mCandleSticks.Clear();
                loadRequestedDateRecords = true;
            }
        }
    }

    ObjectList<CandleStick> *tempCandleSticks = new ObjectList<CandleStick>();
    tempCandleSticks.CopyFrom(mCandleSticks);

    datetime requestedDateTime = DateTimeHelper::ToDatetime(requestedDate);

    // only load if we are requesting a date that is greater than we have before, not if we are equal or lower
    if (loadRequestedDateRecords)
    {
        ReadCandleSticks(requestedDateTime, tempCandleSticks);
    }

    bool priceReachedXBeforeY = PriceReachesXBeforeYLoop(signalType, requestedDateTime, x, y, tempCandleSticks);

    tempCandleSticks.Clear(false);
    delete tempCandleSticks;

    mLastRequestedDate = DateTimeHelper::ToMQLDateTime(requestedDateTime);
    return priceReachedXBeforeY;
}

bool CandleStickTracker::PriceReachesXBeforeYLoop(SignalType signalType, datetime requestedDateTime, double x, double y, ObjectList<CandleStick> *&tempCandleSticks)
{
    while (true)
    {
        if (signalType == SignalType::Bullish)
        {
            for (int i = 0; i < tempCandleSticks.Size(); i++)
            {
                if (tempCandleSticks[i].Date() <= requestedDateTime)
                {
                    continue;
                }
                else if (tempCandleSticks[i].Low() <= y)
                {
                    return false;
                }
                else if (tempCandleSticks[i].High() >= x)
                {
                    return true;
                }
            }
        }
        else if (signalType == SignalType::Bearish)
        {
            for (int i = 0; i < tempCandleSticks.Size(); i++)
            {
                if (tempCandleSticks[i].Date() <= requestedDateTime)
                {
                    continue;
                }
                else if (tempCandleSticks[i].High() >= y)
                {
                    return false;
                }
                else if (tempCandleSticks[i].Low() <= x)
                {
                    return true;
                }
            }
        }

        DateTimeHelper::MoveToNextWeekDay(requestedDateTime);

        // remove old candles so we don't loop through them again
        tempCandleSticks.Clear(false);
        ReadCandleSticks(requestedDateTime, tempCandleSticks);
    }
}