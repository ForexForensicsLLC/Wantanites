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

class CandleStickTracker
{
private:
    static int mCurrentDay;
    static ObjectList<CandleStick> *mTodaysCandleSticks;
    static CSVRecordWriter<CandleStickRecord> *mCandleStickWriter;

    static string Directory() { return "CandleStickRecords/" + Symbol() + "/"; }

    static void Update();
    static void ReadTodaysCandleSticks();
    ~CandleStickTracker();

public:
    static ObjectList<CandleStick> *GetTodaysCandleSticks();
};

int CandleStickTracker::mCurrentDay = ConstantValues::EmptyInt;
ObjectList<CandleStick> *CandleStickTracker::mTodaysCandleSticks = new ObjectList<CandleStick>();
CSVRecordWriter<CandleStickRecord> *CandleStickTracker::mCandleStickWriter = new CSVRecordWriter<CandleStickRecord>(Directory(), IntegerToString(Period()) + ".csv", FileOperation::ReadingExisting, false, false);

CandleStickTracker::~CandleStickTracker()
{
    delete mTodaysCandleSticks;
    delete mCandleStickWriter;
}

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
        record.ReadRow(mCandleStickWriter.FileHandle());
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

    delete record;
}

ObjectList<CandleStick> *CandleStickTracker::GetTodaysCandleSticks()
{
    Update();
    return mTodaysCandleSticks;
}