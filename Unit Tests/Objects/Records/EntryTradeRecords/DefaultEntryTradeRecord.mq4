//+------------------------------------------------------------------+
//|                                      DefaultEntryTradeRecord.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

#include <SummitCapital\Framework\Constants\Index.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\DefaultEntryTradeRecord.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/Records/EntryTradeRecords/DefaultEntryTradeRecord/";
const int NumberOfAsserts = 10;

CSVRecordWriter<DefaultEntryTradeRecord> *writer = new CSVRecordWriter<DefaultEntryTradeRecord>(Directory + "Records/", "Records.csv");

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
    DefaultEntryTradeRecord *record = new DefaultEntryTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = Symbol();
    record.OrderType = "BUY";
    record.AccountBalanceBefore = 10.86;
    record.Lots = 2.3;
    record.EntryTime = TimeCurrent();
    record.EntryPrice = 456.7;
    record.EntryStopLoss = 500.4;

    writer.WriteRecord(record);

    actual = true;
    return Results::UNIT_TEST_RAN;
}