//+------------------------------------------------------------------+
//|                                            WriteEntireRecord.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

#include <WantaCapital\Framework\Constants\Index.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\DefaultErrorRecord.mqh>
#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/CSVRecordWriter/WriteEntireRecord/";
const int NumberOfAsserts = 10;

CSVRecordWriter *writer = new CSVRecordWriter(Directory + "Records/", "Records.csv");

BoolUnitTest<DefaultUnitTestRecord> *WriteEntireRecordUnitTest;

int OnInit()
{
    WriteEntireRecordUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Write Entire Record", "Should write the enire error record",
        NumberOfAsserts, true, WriteEntireRecord);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete writer;
    delete WriteEntireRecordUnitTest;
}

void OnTick()
{
    WriteEntireRecordUnitTest.Assert();
}

int WriteEntireRecord(bool &actual)
{
    DefaultErrorRecord *record = new DefaultErrorRecord();

    record.ErrorTime = TimeCurrent();
    record.Error = 123;
    record.LastState = 456;
    record.ErrorImage = "*iamge*";

    writer.WriteEntireRecord<DefaultErrorRecord>(record);

    actual = true;
    return Results::UNIT_TEST_RAN;
}
