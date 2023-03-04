//+------------------------------------------------------------------+
//|                               MultiTimeFrameExitTradeRecord.mq4 |
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

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\CloseTradeRecords\MultiTimeFrameExitTradeRecord.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Records/CloseTradeRecords/MultiTimeFrameExitTradeRecord/";
const int NumberOfAsserts = 10;

CSVRecordWriter<MultiTimeFrameExitTradeRecord> *writer = new CSVRecordWriter<MultiTimeFrameExitTradeRecord>(Directory + "Records/", "Records.csv");

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
    MultiTimeFrameExitTradeRecord *record = new MultiTimeFrameExitTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = Symbol();
    record.EntryTimeFrame = 1;
    record.AccountBalanceAfter = 67.34;
    record.ExitTime = TimeCurrent();
    record.ExitPrice = 789.54;
    record.ExitStopLoss = 5423.4;
    record.HigherTimeFrameEntryImage = "HImage";
    record.LowerTimeFrameEntryImage = "LImage";

    writer.WriteRecord(record);

    actual = true;
    return Results::UNIT_TEST_RAN;
}