//+------------------------------------------------------------------+
//|                                     WriteTradeRecordOpenData.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVTradeRecordWriter.mqh>

#include <Wantanites\Framework\Constants\Index.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\Index.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/CSVRecordWriter/WriteTradeRecordOpenData/";
const int NumberOfAsserts = 10;

const string DefaulTradeRecordTestName = "DefaultTradeRecord";
const string DefaultTradeRecordWriterDirectory = Directory + DefaulTradeRecordTestName + "/";

const string SingleTimeFrameTradeRecordTestName = "SingleTFTradeRecord";
const string SingleTimeFrameTraceRecordWriterDirectory = Directory + SingleTimeFrameTradeRecordTestName + "/";

const string SinglePartialMultiTimeFrameTradeRecordTestName = "SinglePartialMTFTradeRecord";
const string SinglePartialMultiTimeFrameTradeRecordWriterDirectory = Directory + SinglePartialMultiTimeFrameTradeRecordTestName + "/";

CSVTradeRecordWriter *DefaultTradeRecordWriter = new CSVTradeRecordWriter(DefaultTradeRecordWriterDirectory, "Records.csv");
CSVTradeRecordWriter *SingleTimeFrameTradeRecordWriter = new CSVTradeRecordWriter(SingleTimeFrameTraceRecordWriterDirectory, "Records.csv");
CSVTradeRecordWriter *SinglePartialMultiTimeFrameTradeRecordWriter = new CSVTradeRecordWriter(SinglePartialMultiTimeFrameTradeRecordWriterDirectory, "Records.csv");

BoolUnitTest<DefaultUnitTestRecord> *DefaultTradeRecordUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *SingleTimeFrameTradeRecordUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *SinglePartialMultiTimeFrameTradeRecordUnitTest;

int OnInit()
{
    DefaultTradeRecordUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, DefaulTradeRecordTestName, "Should correctly write the record open data",
        NumberOfAsserts, true, DefaultTradeRecordFunction);

    SingleTimeFrameTradeRecordUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, SingleTimeFrameTradeRecordTestName, "Should correctly write the record open data",
        NumberOfAsserts, true, SingleTimeFrameTradeRecordFunction);

    SinglePartialMultiTimeFrameTradeRecordUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, SinglePartialMultiTimeFrameTradeRecordTestName, "Should correctly write the record open data",
        NumberOfAsserts, true, SinglePartialMultiTimeFrameTradeRecordFunction);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete DefaultTradeRecordWriter;
    delete SingleTimeFrameTradeRecordWriter;
    delete SinglePartialMultiTimeFrameTradeRecordWriter;

    delete DefaultTradeRecordUnitTest;
    delete SingleTimeFrameTradeRecordUnitTest;
    delete SinglePartialMultiTimeFrameTradeRecordUnitTest;
}

void OnTick()
{
    DefaultTradeRecordUnitTest.Assert();
    SingleTimeFrameTradeRecordUnitTest.Assert();
    SinglePartialMultiTimeFrameTradeRecordUnitTest.Assert();
}

int DefaultTradeRecordFunction(bool &actual)
{
    DefaultTradeRecord *record = new DefaultTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = "EU";
    record.OrderType = "Buy";
    record.AccountBalanceBefore = 1000000.0;
    record.Lots = 10.5;
    record.EntryTime = TimeCurrent();
    record.EntryPrice = 1.45323;
    record.EntryStopLoss = 1.45123;

    DefaultTradeRecordWriter.WriteTradeRecordOpenData<DefaultTradeRecord>(record);
    delete record;

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int SingleTimeFrameTradeRecordFunction(bool &actual)
{
    SingleTimeFrameTradeRecord *record = new SingleTimeFrameTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = "EU";
    record.OrderType = "Buy";
    record.AccountBalanceBefore = 1000000.0;
    record.Lots = 10.5;
    record.EntryTime = TimeCurrent();
    record.EntryPrice = 1.45323;
    record.EntryStopLoss = 1.45123;
    record.EntryImage = "img";

    SingleTimeFrameTradeRecordWriter.WriteTradeRecordOpenData<SingleTimeFrameTradeRecord>(record);
    delete record;

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int SinglePartialMultiTimeFrameTradeRecordFunction(bool &actual)
{
    SinglePartialMultiTimeFrameTradeRecord *record = new SinglePartialMultiTimeFrameTradeRecord();

    record.TicketNumber = 1;
    record.Symbol = "EU";
    record.OrderType = "Buy";
    record.AccountBalanceBefore = 1000000.0;
    record.Lots = 10.5;
    record.EntryTime = TimeCurrent();
    record.EntryPrice = 1.45323;
    record.EntryStopLoss = 1.45123;
    record.HigherTimeFrameEntryImage = "himg";
    record.LowerTimeFrameEntryImage = "limg";

    SinglePartialMultiTimeFrameTradeRecordWriter.WriteTradeRecordOpenData<SinglePartialMultiTimeFrameTradeRecord>(record);
    delete record;

    actual = true;
    return Results::UNIT_TEST_RAN;
}
