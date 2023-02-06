//+------------------------------------------------------------------+
//|                                                  RangeToPips.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Helpers\OrderHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/RangeToPips/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1vFJH51mP2bmmXCPE_HsPecp_-JbHgFJj/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *NasCorrectRangeToPipsUnitTest;

// https://drive.google.com/file/d/1vYB5Bru3SDTjSqm1W0yyvXmrJeNGYGHm/view?usp=sharing
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
        10000, EURUSDCorrectRangeToPips);

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
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderHelper::RangeToPips(1.0);
    return Results::UNIT_TEST_RAN;
}

int EURUSDCorrectRangeToPips(int &actual)
{
    if (Symbol() != "EURUSD")
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderHelper::RangeToPips(1.0);
    return Results::UNIT_TEST_RAN;
}