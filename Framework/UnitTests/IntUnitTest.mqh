//+------------------------------------------------------------------+
//|                                                  IntUnitTest.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/UnitTests/UnitTest.mqh>

template <typename TRecord>
class IntUnitTest : public UnitTest<int, TRecord>
{
private:
    typedef int (*TActualIntFunc)(int &actual);
    typedef int (*TActualUnitTestIntFunc)(IntUnitTest<TRecord> &ut, int &actual);
    typedef int (*TExpectedIntFunc)(IntUnitTest<TRecord> &ut);

    int mExpectedValue;
    TExpectedIntFunc mExpectedFunc;

    TActualIntFunc mActualIntFunc;
    TActualUnitTestIntFunc mActualUnitTestIntFunc;

    void Init(int expected, TExpectedIntFunc expectedFunc, TActualIntFunc actualIntFunc, TActualUnitTestIntFunc actualUnitTestIntFunc);

public:
    IntUnitTest(string directory, string testName, string description, int maxAsserts, int expected, TActualIntFunc actual);
    IntUnitTest(string directory, string testName, string description, int maxAsserts, int expected, TActualUnitTestIntFunc actual);
    IntUnitTest(string directory, string testName, string description, int maxAsserts, TExpectedIntFunc expected, TActualIntFunc actual);
    IntUnitTest(string directory, string testName, string description, int maxAsserts, TExpectedIntFunc expected, TActualUnitTestIntFunc actual);

    ~IntUnitTest();

    virtual void Assert(bool equals);
};

template <typename TRecord>
void IntUnitTest::Init(int expected, TExpectedIntFunc expectedFunc, TActualIntFunc actualIntFunc, TActualUnitTestIntFunc actualUnitTestIntFunc)
{
    mExpectedValue = expected;
    mExpectedFunc = expectedFunc;

    mActualIntFunc = actualIntFunc;
    mActualUnitTestIntFunc = actualUnitTestIntFunc;
}

template <typename TRecord>
IntUnitTest::IntUnitTest(string directory, string testName, string description, int maxAsserts, int expected, TActualIntFunc actual)
    : UnitTest(directory, testName, description, maxAsserts)
{
    Init(expected, NULL, actual, NULL);
}

template <typename TRecord>
IntUnitTest::IntUnitTest(string directory, string testName, string description, int maxAsserts, int expected, TActualUnitTestIntFunc actual)
    : UnitTest(directory, testName, description, maxAsserts)
{
    Init(expected, NULL, NULL, actual);
}

template <typename TRecord>
IntUnitTest::IntUnitTest(string directory, string testName, string testMessage, int maxAsserts, TExpectedIntFunc expected, TActualIntFunc actual)
    : UnitTest(directory, testName, testMessage, maxAsserts)
{
    Init(NULL, expected, actual, NULL);
}

template <typename TRecord>
IntUnitTest::IntUnitTest(string directory, string testName, string testMessage, int maxAsserts, TExpectedIntFunc expected, TActualUnitTestIntFunc actual)
    : UnitTest(directory, testName, testMessage, maxAsserts)
{
    Init(NULL, expected, NULL, actual);
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
    int testStatus;

    if (mActualIntFunc != NULL)
    {
        testStatus = mActualIntFunc(actual);
    }
    else
    {
        testStatus = mActualUnitTestIntFunc(this, actual);
    }

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
        expected = mExpectedFunc(this);
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
