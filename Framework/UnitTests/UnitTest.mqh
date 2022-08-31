//+------------------------------------------------------------------+
//|                                                     UnitTest.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

template <typename TUnitTest, typename TRecord>
class UnitTest : public CSVRecordWriter<TRecord>
{
private:
    bool mDone;

    bool mUseAssertCooldown;
    int mAssertCooldownMinutes;

    datetime mLastAssertTime;

    void SetAssertResult(string result, string message);
    bool PastAssertCooldown();
    void SendEmail();

protected:
    bool mRecordErrors;

    // TODO: Can Update These To Take a message string from child if implicit string conversion is causing issues
    void AssertEquals(TUnitTest expected, TUnitTest actual);
    void AssertNotEquals(TUnitTest expected, TUnitTest actual);

public:
    UnitTest(string directory, string testName, string description, int maxAsserts);
    ~UnitTest();

    void AssertCooldown(int minutes);
    void RecordErrors(bool recordErrors) { mRecordErrors = recordErrors; }

    bool CanAssert();
    void RecordError(int error);

    virtual void Assert(bool equals);
};

template <typename TUnitTest, typename TRecord>
UnitTest::UnitTest(string directory, string testName, string description, int maxAsserts)
{
    mDirectory = directory + testName + "/";
    mCSVFileName = testName + ".csv";
    mRecordErrors = true;
    mLastAssertTime = 0;
    mUseAssertCooldown = false;

    PendingRecord.Name = testName;
    PendingRecord.Description = description;
    PendingRecord.MaxAsserts = maxAsserts;
}

template <typename TUnitTest, typename TRecord>
UnitTest::~UnitTest(void)
{
}

template <typename TUnitTest, typename TRecord>
void UnitTest::AssertCooldown(int minutes)
{
    mUseAssertCooldown = true;
    mAssertCooldownMinutes = minutes;
}

template <typename TUnitTest, typename TRecord>
void UnitTest::SetAssertResult(string result, string message)
{
    PendingRecord.AssertTime = TimeCurrent();
    PendingRecord.Result = result;
    PendingRecord.Asserts += 1;
    PendingRecord.Message = message;
    mLastAssertTime = TimeCurrent();

    CSVRecordWriter<TRecord>::Write();

    if (PendingRecord.Asserts >= PendingRecord.MaxAsserts)
    {
        mDone = true;
        SendEmail();
    }
}

template <typename TUnitTest, typename TRecord>
bool UnitTest::CanAssert()
{
    if (mDone)
    {
        return false;
    }

    if (mUseAssertCooldown)
    {
        return PastAssertCooldown();
    }

    return true;
}

template <typename TUnitTest, typename TRecord>
bool UnitTest::PastAssertCooldown()
{
    if (mLastAssertTime == 0)
    {
        return true;
    }

    if (Hour() == TimeHour(mLastAssertTime) && (Minute() - TimeMinute(mLastAssertTime) >= mAssertCooldownMinutes))
    {
        return true;
    }

    if (Hour() > TimeHour(mLastAssertTime))
    {
        int minutes = (59 - TimeMinute(mLastAssertTime)) + Minute();
        return minutes >= mAssertCooldownMinutes;
    }

    return false;
}

template <typename TUnitTest, typename TRecord>
void UnitTest::SendEmail()
{
    SendMail("Unit Test " + PendingRecord.Name + " Completed", "");
}

template <typename TUnitTest, typename TRecord>
void UnitTest::AssertEquals(TUnitTest expected, TUnitTest actual)
{
    string message = "Expected: " + expected + " - Actual: " + actual;
    string result = expected == actual ? "Pass" : "Fail";

    SetAssertResult(result, message);
}

template <typename TUnitTest, typename TRecord>
void UnitTest::AssertNotEquals(TUnitTest expected, TUnitTest actual)
{
    string message = "Didn't Expect: " + expected + " - Actual: " + actual;
    string result = expected != actual ? "Pass" : "Fail";

    SetAssertResult(result, message);
}

template <typename TUnitTest, typename TRecord>
void UnitTest::RecordError(int error)
{
    PendingRecord.Result = "Error";
    PendingRecord.Message = IntegerToString(error);

    CSVRecordWriter<TRecord>::Write();
}