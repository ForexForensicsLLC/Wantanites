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
#include <Wantanites\Framework\Objects\DataObjects\CandleStick.mqh>
#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>

static class CandleStickTracker
{
private:
    int mCurrentDay;
    ObjectList<CandleStick> *mTodaysCandleSticks;
    CSVRecordWriter<CandleStickRecord> *mCandleStickWriter;

    string Directory() { return "CandleStickRecords/"; }

    void Update();
    void ReadTodaysCandleSticks();

    CandleStickTracker();

public:
    ObjectList<CandleStick> *GetTodaysCandleSticks();
};

void CandleStickTracker::Update()
{
    int day = DateTimeHelper::CurrentDay();
    if (day != mCurrentDay)
    {
        mCurrentDay = day;

        mTodaysCandleSticks.Clear();
        ReadTodaysCandleSticks();
    }
}

void CandleStickTracker::ReadTodaysCandleSticks()
{
    CandleStickRecord *record = new CandleStickRecord();
    mCandleStickWriter.SeekToStart();

    while (!FileIsEnding(mCandleStickWriter.FileHandle()))
    {
        record.ReadRow();
        MqlDateTime dt = DateTimeHelper::ToMQLDateTime(record.Date);

        if (dt.day < mCurrentDay)
        {
            continue;
        }
        else if (dt.day > mCurrentDay)
        {
            break;
        }

        CandleStick *cs = new CandleStick(record);
        mTodaysCandleSticks.Add(cs);
    }
}

CandleStickTracker::CandleStickTracker()
{
    mCurrentDay = ConstantValues::EmptyInt;
    mTodaysCandleSticks = new ObjectList<CandleStick>();
    mCandleStickWriter = new CSVRecordWriter<CandleStickRecord>(Directory(), IntegerToString(Period()) + ".csv", FileOperation::ReadingExisting, false, false);
}

ObjectList<CandleStick> *CandleStickTracker::GetTodaysCandleSticks()
{
    Update();
    return mTodaysCandleSticks;
}