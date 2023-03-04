//+------------------------------------------------------------------+
//|                                      DefaultExitTradeRecord.mq4 |
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

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\CloseTradeRecords\DefaultExitTradeRecord.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Records/CloseTradeRecords/DefaultExitTradeRecord/";
const int NumberOfAsserts = 10;

CSVRecordWriter<DefaultExitTradeRecord> *writer = new CSVRecordWriter<DefaultExitTradeRecord>(Directory + "Records/", "Records.csv");

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
    DefaultExitTradeRecord *record = new DefaultExitTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = Symbol();
    record.EntryTimeFrame = 1;
    record.AccountBalanceAfter = 67.34;
    record.ExitTime = TimeCurrent();
    record.ExitPrice = 789.54;
    record.ExitStopLoss = 5423.4;

    writer.WriteRecord(record);

    actual = true;
    return Results::UNIT_TEST_RAN;
}
