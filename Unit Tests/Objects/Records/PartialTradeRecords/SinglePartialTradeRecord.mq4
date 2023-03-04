//+------------------------------------------------------------------+
//|                                    DefaultPartialTradeRecord.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordWriter.mqh>

#include <Wantanites\Framework\Constants\Index.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\PartialTradeRecords\SinglePartialTradeRecord.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Records/PartialTradeRecords/SinglePartialTradeRecord/";
const int NumberOfAsserts = 10;

CSVRecordWriter<SinglePartialTradeRecord> *writer = new CSVRecordWriter<SinglePartialTradeRecord>(Directory + "Records/", "Records.csv");

BoolUnitTest<DefaultUnitTestRecord> *WriteRecordUnitTest;

int OnInit()
{
    WriteRecordUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "WriteRecord", "Should correctly write the record",
        NumberOfAsserts, true, WriteRecord);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete writer;
    delete WriteRecordUnitTest;
}

void OnTick()
{
    WriteRecordUnitTest.Assert();
}

int WriteRecord(bool &actual)
{
    SinglePartialTradeRecord *record = new SinglePartialTradeRecord();

    record.TicketNumber = 1;
    record.PartialOneTicketNumber = 2;
    record.PartialOneRR = 7.5;

    writer.WriteRecord(record);

    actual = true;
    return Results::UNIT_TEST_RAN;
}
