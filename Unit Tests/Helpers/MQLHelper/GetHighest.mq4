//+------------------------------------------------------------------+
//|                                                   GetHighest.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Helpers\MQLHelper.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/MQLHelper/GetHighest/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1PK21TvRIkH4lWd2dGtf9uSS_m541HVLZ/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountZeroReturnsFalseUnitTest;

// https://drive.google.com/file/d/1frskalXj-y7BjMz-VdvF4icvKxYEdovG/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountOneReturnsTrueUnitTest;

// https://drive.google.com/file/d/1qpPOpWJMxs0jg0GRQTrvAxieRO-llaua/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ExclusiveCorectHighestUnitTest;

// https://drive.google.com/file/d/1xenUDY7n0R3dqGpCspcSfTeTtI2e-z4U/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *InclusiveCorrectHighestUnitTest;

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

    ExclusiveCorectHighestUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Exclusive Corect Highest Index", "Should Return Equal Values With iHighest",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExclusiveCorectHighestExpected, ExclusiveCorectHighest);

    InclusiveCorrectHighestUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Invlusive Corect Highest Index", "Should Return Equal Values With iHighest",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        InclusiveCorectHighestExpected, InclusiveCorectHighest);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CountZeroReturnsFalseUnitTest;
    delete CountOneReturnsTrueUnitTest;

    delete ExclusiveCorectHighestUnitTest;
    delete InclusiveCorrectHighestUnitTest;
}

void OnTick()
{
    CountZeroReturnsFalseUnitTest.Assert();
    CountOneReturnsTrueUnitTest.Assert();

    ExclusiveCorectHighestUnitTest.Assert();
    InclusiveCorrectHighestUnitTest.Assert();
}

int CountZeroReturnsFalse(bool &actual)
{
    int count = 0;
    int highIndex;
    actual = MQLHelper::GetHighest(Symbol(), Period(), MODE_HIGH, count, 0, false, highIndex);

    return Results::UNIT_TEST_RAN;
}

int CountOneReturnsTrue(bool &actual)
{
    int count = 1;
    int highIndex;
    actual = MQLHelper::GetHighest(Symbol(), Period(), MODE_HIGH, count, 0, false, highIndex) && highIndex >= 0;

    return Results::UNIT_TEST_RAN;
}

int ExclusiveCorectHighestExpected()
{
    return iHighest(Symbol(), Period(), MODE_HIGH, 10, 0);
}

int ExclusiveCorectHighest(int &actual)
{
    int count = 10;
    bool passed = MQLHelper::GetHighest(Symbol(), Period(), MODE_HIGH, count, 0, false, actual);
    if (!passed)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    return Results::UNIT_TEST_RAN;
}

int InclusiveCorectHighestExpected()
{
    return iHighest(Symbol(), Period(), MODE_HIGH, 11, 0);
}

int InclusiveCorectHighest(int &actual)
{
    int count = 10;
    bool passed = MQLHelper::GetHighest(Symbol(), Period(), MODE_HIGH, count, 0, true, actual);
    if (!passed)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    return Results::UNIT_TEST_RAN;
}