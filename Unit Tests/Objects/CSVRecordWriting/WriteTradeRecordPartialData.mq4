//+------------------------------------------------------------------+
//|                                  WriteTradeRecordPartialData.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVTradeRecordWriter.mqh>

#include <WantaCapital\Framework\Constants\Index.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\Index.mqh>
#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/CSVRecordWriter/WriteTradeRecordPartialData/";
const int NumberOfAsserts = 10;

const string SinglePartialMultiTimeFrameTradeRecordTestName = "SinglePartialMTFTradeRecord";
const string SinglePartialMultiTimeFrameTradeRecordWriterDirectory = Directory + SinglePartialMultiTimeFrameTradeRecordTestName + "/";

const string SPMTFAlternatingRecordsTestName = "SPMTFAlternatingRecords";
const string SPMTFDirectory = Directory + SPMTFAlternatingRecordsTestName + "/";

CSVTradeRecordWriter *SinglePartialMultiTimeFrameTradeRecordWriter = new CSVTradeRecordWriter(SinglePartialMultiTimeFrameTradeRecordWriterDirectory, "Records.csv");
CSVTradeRecordWriter *SPMTFAlternatingRecordsWriter = new CSVTradeRecordWriter(SPMTFDirectory, "Records.csv");

BoolUnitTest<DefaultUnitTestRecord> *SinglePartialMultiTimeFrameTradeRecordUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *SPMTFAlternatingRecordsUnitTest;

int OnInit()
{
    SinglePartialMultiTimeFrameTradeRecordUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, SinglePartialMultiTimeFrameTradeRecordTestName, "Should correctly write the record open data",
        NumberOfAsserts, true, SinglePartialMultiTimeFrameTradeRecordFunction);

    SPMTFAlternatingRecordsUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, SPMTFAlternatingRecordsTestName, "Should correctly write the record open data",
        NumberOfAsserts, true, SPMTFAlternatingRecordsFunction);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SinglePartialMultiTimeFrameTradeRecordWriter;

    delete SinglePartialMultiTimeFrameTradeRecordUnitTest;
    delete SPMTFAlternatingRecordsUnitTest;
}

void OnTick()
{
    // SinglePartialMultiTimeFrameTradeRecordUnitTest.Assert();
    SPMTFAlternatingRecordsUnitTest.Assert();
}

int SinglePartialMultiTimeFrameTradeRecordFunction(bool &actual)
{
    static int count = 1;
    SinglePartialMultiTimeFrameTradeRecord *record = new SinglePartialMultiTimeFrameTradeRecord();

    record.TicketNumber = count;
    record.Symbol = "10";
    record.OrderType = "11";
    record.AccountBalanceBefore = 100000.5;
    record.Lots = 5.7;
    record.EntryTime = TimeCurrent();
    record.EntryPrice = 34;
    record.EntryStopLoss = 35;
    record.AccountBalanceAfter = 36;
    record.ExitTime = TimeCurrent() - 600000;
    record.ExitPrice = 37;
    record.ExitStopLoss = 38;

    record.HigherTimeFrameEntryImage = "12";
    record.LowerTimeFrameEntryImage = "13";
    record.HigherTimeFrameExitImage = "14";
    record.LowerTimeFrameExitImage = "15";

    record.PartialedTicketNumber = count;
    record.PartialOneRR = 8;

    SinglePartialMultiTimeFrameTradeRecordWriter.WriteTradeRecordOpenData<SinglePartialMultiTimeFrameTradeRecord>(record);
    SinglePartialMultiTimeFrameTradeRecordWriter.WriteTradeRecordPartialData<SinglePartialMultiTimeFrameTradeRecord>(record);

    delete record;

    count += 1;
    actual = true;
    return Results::UNIT_TEST_RAN;
}

int SPMTFAlternatingRecordsFunction(bool &actual)
{
    static int count = 1;
    if (count > 1)
    {
        return Results::UNIT_TEST_RAN;
    }

    SinglePartialMultiTimeFrameTradeRecord *recordOne = new SinglePartialMultiTimeFrameTradeRecord();
    SinglePartialMultiTimeFrameTradeRecord *recordTwo = new SinglePartialMultiTimeFrameTradeRecord();
    SinglePartialMultiTimeFrameTradeRecord *recordThree = new SinglePartialMultiTimeFrameTradeRecord();

    recordOne.TicketNumber = count;
    recordOne.PartialedTicketNumber = count;
    recordOne.PartialOneRR = count;

    count += 1;

    recordTwo.TicketNumber = count;
    recordTwo.PartialedTicketNumber = count;
    recordTwo.PartialOneRR = count;

    count += 1;

    SPMTFAlternatingRecordsWriter.WriteTradeRecordOpenData<SinglePartialMultiTimeFrameTradeRecord>(recordOne);
    SPMTFAlternatingRecordsWriter.WriteTradeRecordOpenData<SinglePartialMultiTimeFrameTradeRecord>(recordTwo);

    return Results::UNIT_TEST_RAN;

    recordThree.TicketNumber = count;
    recordThree.PartialedTicketNumber = count;
    recordThree.PartialOneRR = count;

    count += 1;

    SPMTFAlternatingRecordsWriter.WriteTradeRecordPartialData<SinglePartialMultiTimeFrameTradeRecord>(recordOne);
    SPMTFAlternatingRecordsWriter.WriteTradeRecordOpenData<SinglePartialMultiTimeFrameTradeRecord>(recordThree);
    SPMTFAlternatingRecordsWriter.WriteTradeRecordPartialData<SinglePartialMultiTimeFrameTradeRecord>(recordThree);

    SPMTFAlternatingRecordsWriter.WriteTradeRecordPartialData<SinglePartialMultiTimeFrameTradeRecord>(recordTwo);

    delete recordOne;
    delete recordTwo;
    delete recordThree;

    actual = true;
    return Results::UNIT_TEST_RAN;
}
