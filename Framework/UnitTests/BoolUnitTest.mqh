//+------------------------------------------------------------------+
//|                                                 BoolUnitTest.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/UnitTests/UnitTest.mqh>

template <typename TRecord>
class BoolUnitTest : public UnitTest<bool, TRecord>
{
private:
    typedef int (*TBoolFunc)(bool &actual);

    bool mExpected;
    TBoolFunc mActual;

public:
    BoolUnitTest(string directory, string testName, string testMessage, int maxAsserts, int assertCooldownMinutes, bool recordScreenShot, bool recordErrors,
                 bool expected, TBoolFunc actual);

    ~BoolUnitTest();

    virtual void Assert(bool equals);
};

template <typename TRecord>
BoolUnitTest::BoolUnitTest(string directory, string testName, string testMessage, int maxAsserts, int assertCooldownMinutes, bool recordScreenShot, bool recordErrors,
                           bool expected, TBoolFunc actual)
    : UnitTest(directory, testName, testMessage, maxAsserts, assertCooldownMinutes, recordScreenShot, recordErrors)
{
    mExpected = expected;
    mActual = actual;
}

template <typename TRecord>
BoolUnitTest::~BoolUnitTest()
{
}

template <typename TRecord>
void BoolUnitTest::Assert(bool equals = true)
{
    if (!UnitTest<bool, TRecord>::CanAssert())
    {
        return;
    }

    bool actual;
    int testStatus = mActual(actual);

    if ((testStatus != UnitTestConstants::UNIT_TEST_RAN || testStatus != UnitTestConstants::UNIT_TEST_DID_NOT_RUN) && mRecordErrors)
    {
        UnitTest<bool, TRecord>::RecordError(testStatus);
        return;
    }

    if (testStatus == UnitTestConstants::UNIT_TEST_DID_NOT_RUN)
    {
        return;
    }

    if (equals)
    {
        UnitTest<bool, TRecord>::AssertEquals(mExpected, actual);
    }
    else
    {
        UnitTest<bool, TRecord>::AssertNotEquals(mExpected, actual);
    }
}
