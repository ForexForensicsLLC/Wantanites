//+------------------------------------------------------------------+
//|                                                    GetLowest.mq4 |
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

const string Directory = "/UnitTests/Helpers/MQLHelper/GetLowest/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1CEyqe2uJ6hOg91Wz2D4vjg0tnSP8ZQ0o/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountZeroReturnsFalseUnitTest;

// https://drive.google.com/file/d/1L1Fu0B6NHb3kGq0VknH_NCNDZ_2DvG34/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountOneReturnsTrueUnitTest;

// https://drive.google.com/file/d/1PPrAZv25z5t-l1S-pjUytwzpGm89NxrU/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ExclusiveCorectLowestUnitTest;

// https://drive.google.com/file/d/1NddbJLLtVNOVn9kcPGKbGUe5rhssi3FP/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *InclusiveCorectLowestUnitTest;

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

    ExclusiveCorectLowestUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Exclusive Corect Lowest Index", "Should Return Equal Values With iLowest",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExclusiveCorectLowestExpected, ExclusiveCorectLowest);

    InclusiveCorectLowestUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Inclusive Corect Lowest Index", "Should Return Equal Values With iLowest",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        InclusiveCorectLowestExpected, InclusiveCorectLowest);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CountZeroReturnsFalseUnitTest;
    delete CountOneReturnsTrueUnitTest;

    delete ExclusiveCorectLowestUnitTest;
    delete InclusiveCorectLowestUnitTest;
}

void OnTick()
{
    CountZeroReturnsFalseUnitTest.Assert();
    CountOneReturnsTrueUnitTest.Assert();

    ExclusiveCorectLowestUnitTest.Assert();
    InclusiveCorectLowestUnitTest.Assert();
}

int CountZeroReturnsFalse(bool &actual)
{
    int count = 0;
    int lowIndex;
    actual = MQLHelper::GetLowest(Symbol(), Period(), MODE_LOW, count, 0, false, lowIndex);

    return Results::UNIT_TEST_RAN;
}

int CountOneReturnsTrue(bool &actual)
{
    int count = 1;
    int lowIndex;
    actual = MQLHelper::GetLowest(Symbol(), Period(), MODE_LOW, count, 0, false, lowIndex) && lowIndex >= 0;

    return Results::UNIT_TEST_RAN;
}

int ExclusiveCorectLowestExpected()
{
    return iLowest(Symbol(), Period(), MODE_LOW, 10, 0);
}

int ExclusiveCorectLowest(int &actual)
{
    int count = 10;
    bool passed = MQLHelper::GetLowest(Symbol(), Period(), MODE_LOW, count, 0, false, actual);
    if (!passed)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    return Results::UNIT_TEST_RAN;
}

int InclusiveCorectLowestExpected()
{
    return iLowest(Symbol(), Period(), MODE_LOW, 11, 0);
}

int InclusiveCorectLowest(int &actual)
{
    int count = 10;
    bool passed = MQLHelper::GetLowest(Symbol(), Period(), MODE_LOW, count, 0, true, actual);
    if (!passed)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    return Results::UNIT_TEST_RAN;
}