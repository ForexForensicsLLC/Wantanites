//+------------------------------------------------------------------+
//|                                                  PipsToRange.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/PipsToRange/";
const int NumberOfAsserts = 10;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1Sb-9rruOheVcTM2ET9fHNCFUnhG0NShY/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *NasCorrectRangeUnitTest;

// https://drive.google.com/file/d/1JPo4Y-8iK306Jc6Y_8quq_Gvl7cU1GF9/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *EurusdCorrectRangeUnitTest;

int OnInit()
{
    NasCorrectRangeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Nas Correct Pips To Range", "Checks ID Pips Were Converted To Range Correctly On NAS",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        1, NASDAQPipsToRange);

    EurusdCorrectRangeUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "EURUSD Correct Pips To Range", "Checks If Pips Were Converted To Range Correctly On EURUSD",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        1, EURUSDPipsToRange);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete NasCorrectRangeUnitTest;
    delete EurusdCorrectRangeUnitTest;
}

void OnTick()
{
    NasCorrectRangeUnitTest.Assert();
    EurusdCorrectRangeUnitTest.Assert();
}

int NASDAQPipsToRange(int &actual)
{
    if (Symbol() == "US100.cash")
    {
        actual = OrderHelper::PipsToRange(10);
        return Results::UNIT_TEST_RAN;
    }

    return Results::UNIT_TEST_DID_NOT_RUN;
}

int EURUSDPipsToRange(int &actual)
{
    if (Symbol() == "EURUSD")
    {
        actual = OrderHelper::PipsToRange(10000);
        return Results::UNIT_TEST_RAN;
    }

    return Results::UNIT_TEST_DID_NOT_RUN;
}
