//+------------------------------------------------------------------+
//|                                                  RangeToPips.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/RangeToPips/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

IntUnitTest<DefaultUnitTestRecord> *NasCorrectRangeToPipsUnitTest;
IntUnitTest<DefaultUnitTestRecord> *EurusdCorrectRangeToPipsUnitTest;

int OnInit()
{
    NasCorrectRangeToPipsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "NAS Range To Pips", "Correctly Converts Range To Pips On NAS",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        10, NASCorrectRangeToPips);

    EurusdCorrectRangeToPipsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "EURUSD Range To Pips", "Correctly Converts Range To Pips On EURUSD",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        100000, EURUSDCorrectRangeToPips);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NasCorrectRangeToPipsUnitTest;
    delete EurusdCorrectRangeToPipsUnitTest;
}

void OnTick()
{
    NasCorrectRangeToPipsUnitTest.Assert();
    EurusdCorrectRangeToPipsUnitTest.Assert();
}

int NASCorrectRangeToPips(int &actual)
{
    if (Symbol() != "US100.cash")
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderHelper::RangeToPips(1.0);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int EURUSDCorrectRangeToPips(int &actual)
{
    if (Symbol() != "EURUSD")
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderHelper::RangeToPips(1.0);
    return UnitTestConstants::UNIT_TEST_RAN;
}