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
    typedef int (*TActualBoolFunc)(bool &actual);
    typedef int (*TActualUnitTestBoolFunc)(BoolUnitTest &ut, bool &actual);

    bool mExpected;

    TActualBoolFunc mActualBoolFunc;
    TActualUnitTestBoolFunc mActualUnitTestBoolFunc;

    void Init(bool expected, TActualBoolFunc actualBoolFunc, TActualUnitTestBoolFunc actualUnitTestBoolFunc);

public:
    BoolUnitTest(string directory, string testName, string description, int maxAsserts, bool expected, TActualBoolFunc actual);
    BoolUnitTest(string directory, string testName, string description, int maxAsserts, bool expected, TActualUnitTestBoolFunc actual);

    ~BoolUnitTest();

    virtual void Assert(bool equals);
};

template <typename TRecord>
void BoolUnitTest::Init(bool expected, TActualBoolFunc actualBoolFunc, TActualUnitTestBoolFunc actualUnitTestBoolFunc)
{
    mExpected = expected;

    mActualBoolFunc = actualBoolFunc;
    mActualUnitTestBoolFunc = actualUnitTestBoolFunc;
}

template <typename TRecord>
BoolUnitTest::BoolUnitTest(string directory, string testName, string description, int maxAsserts, bool expected, TActualBoolFunc actual)
    : UnitTest(directory, testName, description, maxAsserts)
{
    Init(expected, actual, NULL);
}

template <typename TRecord>
BoolUnitTest::BoolUnitTest(string directory, string testName, string description, int maxAsserts, bool expected, TActualUnitTestBoolFunc actual)
    : UnitTest(directory, testName, description, maxAsserts)
{
    Init(expected, NULL, actual);
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
    int testStatus;

    if (mActualBoolFunc != NULL)
    {
        testStatus = mActualBoolFunc(actual);
    }
    else
    {
        testStatus = mActualUnitTestBoolFunc(this, actual);
    }

    if ((testStatus != Results::UNIT_TEST_RAN && testStatus != Results::UNIT_TEST_DID_NOT_RUN) && mRecordErrors)
    {
        UnitTest<bool, TRecord>::RecordError(testStatus);
        return;
    }

    if (testStatus == Results::UNIT_TEST_DID_NOT_RUN)
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
