//+------------------------------------------------------------------+
//|                                                 GetLowestLow.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Helpers\MQLHelper.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/MQLHelper/GetLowestLow/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1Ea7caSXo0J86IxKDULQM3ecYHIUVGR9K/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountZeroReturnsFalseUnitTest;

// https://drive.google.com/file/d/1-8lSA6-Yb_wBm_pcqTPv83JFLYme5w7j/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CountOneReturnsTrueUnitTest;

// https://drive.google.com/file/d/1uxBBVIWT5RhyzL645YGIGsSlLfPEt1s5/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *CorectLowestLowUnitTest;

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

    CorectLowestLowUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Corect Lowest Low Value", "Should Return Equal Values With iLow(iLowest())",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorectLowestLowExpected, CorectLowestLow);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CountZeroReturnsFalseUnitTest;
    delete CountOneReturnsTrueUnitTest;

    delete CorectLowestLowUnitTest;
}

void OnTick()
{
    CountZeroReturnsFalseUnitTest.Assert();
    CountOneReturnsTrueUnitTest.Assert();

    CorectLowestLowUnitTest.Assert();
}

int CountZeroReturnsFalse(bool &actual)
{
    int count = 0;
    double low;
    actual = MQLHelper::GetLowestLow(Symbol(), Period(), count, 0, low);

    return Results::UNIT_TEST_RAN;
}

int CountOneReturnsTrue(bool &actual)
{
    int count = 1;
    double low;
    actual = MQLHelper::GetLowestLow(Symbol(), Period(), count, 0, low) && low > 0;

    return Results::UNIT_TEST_RAN;
}

int CorectLowestLowExpected()
{
    return MathFloor(iLow(Symbol(), Period(), iLowest(Symbol(), Period(), MODE_LOW, 10, 0)) * MathPow(10, _Digits));
}

int CorectLowestLow(int &actual)
{
    int count = 10;
    double low;

    bool passed = MQLHelper::GetLowestLow(Symbol(), Period(), count, 0, low);
    if (!passed)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = MathFloor(low * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}