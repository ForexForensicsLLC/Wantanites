//+------------------------------------------------------------------+
//|                                               GetHighestHigh.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Constants\Index.mqh>

#include <WantaCapital\Framework\Helpers\MQLHelper.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/MQLHelper/GetHighestHigh/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1pXbyVVGFd4I75Ms7d6KH6AYrrbuS7dBL/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountZeroReturnsFalseUnitTest;

// https://drive.google.com/file/d/1JpJ0mB8jatggnJAkFvsJq0aEDC0PDJ-B/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountOneReturnsTrueUnitTest;

// https://drive.google.com/file/d/1rfYHNFSIwxhgL0nKA7j6szdnFzkDzqsd/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *CorectHighestHighUnitTest;

int OnInit()
{
    CountZeroReturnsFalseUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Count Zero Returns False", "Should Return False When A Count Of Zero Is passed In",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, CountZeroReturnsFalse);

    CountOneReturnsTrueUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Count One Returns True", "Should Return True When A Count Of One Is passed In",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, CountOneReturnsTrue);

    CorectHighestHighUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Corect Highets High Value", "Should Return Equal Values With iHigh(iHighest())",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorectHighestHighExpected, CorectHighestHigh);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CountZeroReturnsFalseUnitTest;
    delete CountOneReturnsTrueUnitTest;

    delete CorectHighestHighUnitTest;
}

void OnTick()
{
    CountZeroReturnsFalseUnitTest.Assert();
    CountOneReturnsTrueUnitTest.Assert();

    CorectHighestHighUnitTest.Assert();
}

int CountZeroReturnsFalse(bool &actual)
{
    int count = 0;
    double high;
    actual = MQLHelper::GetHighestHigh(Symbol(), Period(), count, 0, high);

    return Results::UNIT_TEST_RAN;
}

int CountOneReturnsTrue(bool &actual)
{
    int count = 1;
    double high;
    actual = MQLHelper::GetHighestHigh(Symbol(), Period(), count, 0, high) && high > 0;

    return Results::UNIT_TEST_RAN;
}

int CorectHighestHighExpected()
{
    return MathFloor(iHigh(Symbol(), Period(), iHighest(Symbol(), Period(), MODE_HIGH, 10, 0)) * MathPow(10, _Digits));
}

int CorectHighestHigh(int &actual)
{
    int count = 10;
    double high;

    bool passed = MQLHelper::GetHighestHigh(Symbol(), Period(), count, 0, high);
    if (!passed)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = MathFloor(high * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}