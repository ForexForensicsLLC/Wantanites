//+------------------------------------------------------------------+
//|                                                  IntUnitTest.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/UnitTests/UnitTest.mqh>

template <typename TRecord>
class IntUnitTest : public UnitTest<int, TRecord>
{
private:
    typedef int (*TActualIntFunc)(int &);
    typedef int (*TExpectedIntFunc)();

    int mExpectedValue;
    TExpectedIntFunc mExpectedFunc;
    TActualIntFunc mActual;

public:
    IntUnitTest(string directory, string testName, string description, int maxAsserts, int assertCooldownMinutes, bool recordScreenShot, bool recordErrors,
                int expected, TActualIntFunc actual);

    IntUnitTest(string directory, string testName, string description, int maxAsserts, int assertCooldownMinutes, bool recordScreenShot, bool recordErrors,
                TExpectedIntFunc expected, TActualIntFunc actual);

    ~IntUnitTest();

    virtual void Assert(bool equals);
};

template <typename TRecord>
IntUnitTest::IntUnitTest(string directory, string testName, string description, int maxAsserts, int assertCooldownMinutes, bool recordScreenShot, bool recordErrors,
                         int expected, TActualIntFunc actual)
    : UnitTest(directory, testName, description, maxAsserts, assertCooldownMinutes, recordScreenShot, recordErrors)
{
    mExpectedValue = expected;
    mActual = actual;

    mExpectedFunc = NULL;
}

template <typename TRecord>
IntUnitTest::IntUnitTest(string directory, string testName, string testMessage, int maxAsserts, int assertCooldownMinutes, bool recordScreenShot, bool recordErrors,
                         TExpectedIntFunc expected, TActualIntFunc actual)
    : UnitTest(directory, testName, testMessage, maxAsserts, assertCooldownMinutes, recordScreenShot, recordErrors)
{
    mExpectedFunc = expected;
    mActual = actual;

    mExpectedValue = NULL;
}

template <typename TRecord>
IntUnitTest::~IntUnitTest()
{
}

template <typename TRecord>
void IntUnitTest::Assert(bool equals = true)
{
    if (!UnitTest<int, TRecord>::CanAssert())
    {
        return;
    }

    int actual;
    int testStatus = mActual(actual);

    if ((testStatus != Results::UNIT_TEST_RAN && testStatus != Results::UNIT_TEST_DID_NOT_RUN) && mRecordErrors)
    {
        UnitTest<int, TRecord>::RecordError(testStatus);
        return;
    }

    if (testStatus == Results::UNIT_TEST_DID_NOT_RUN)
    {
        return;
    }

    int expected;
    if (mExpectedFunc != NULL)
    {
        expected = mExpectedFunc();
    }
    else
    {
        expected = mExpectedValue;
    }

    if (equals)
    {
        UnitTest<int, TRecord>::AssertEquals(expected, actual);
    }
    else
    {
        UnitTest<int, TRecord>::AssertNotEquals(expected, actual);
    }
}
