//+------------------------------------------------------------------+
//|                              SingleTimeFrameEntryTradeRecord.mq4 |
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

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\SingleTimeFrameEntryTradeRecord.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Records/EntryTradeRecords/SingleTimeFrameEntryTradeRecord/";
const int NumberOfAsserts = 10;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *writer = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Records/", "Records.csv");

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
    SingleTimeFrameEntryTradeRecord *record = new SingleTimeFrameEntryTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = Symbol();
    record.OrderType = "BUY";
    record.AccountBalanceBefore = 10.86;
    record.Lots = 2.3;
    record.EntryTime = TimeCurrent();
    record.EntryPrice = 456.7;
    record.EntryStopLoss = 500.4;
    record.EntryImage = "EImage";

    writer.WriteRecord(record);

    actual = true;
    return Results::UNIT_TEST_RAN;
}
