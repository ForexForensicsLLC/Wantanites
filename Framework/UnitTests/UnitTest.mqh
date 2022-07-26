/* -*- coding: utf-8 -*-
 *
 * This indicator is licensed under GNU GENERAL PUBLIC LICENSE Version 3.
 * See a LICENSE file for detail of the license.
 */

#property copyright "Copyright 2014, micclly."
#property link "https://github.com/micclly"
#property strict

#include <Object.mqh>
#include <Arrays/List.mqh>

#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

template <typename TRecord>
class UnitTest : public CSVRecordWriter<TRecord>
{
public:
    UnitTest(string directory, string csvFileName, int maxAsserts);
    ~UnitTest();

    void addTest(string name);
    void setSuccess();
    void setFailure(string message);
    void printSummary();

    void assertEquals(string message, bool expected, bool actual);
    void assertEquals(string message, char expected, char actual);
    void assertEquals(string message, uchar expected, uchar actual);
    void assertEquals(string message, short expected, short actual);
    void assertEquals(string message, ushort expected, ushort actual);
    void assertEquals(string message, int expected, int actual);
    void assertEquals(string message, uint expected, uint actual);
    void assertEquals(string message, long expected, long actual);
    void assertEquals(string message, ulong expected, ulong actual);
    void assertEquals(string message, datetime expected, datetime actual);
    void assertEquals(string message, color expected, color actual);
    void assertEquals(string message, float expected, float actual);
    void assertEquals(string message, double expected, double actual);
    void assertEquals(string message, string expected, string actual);

    void assertEquals(string message, const bool &expected[], const bool &actual[]);
    void assertEquals(string message, const char &expected[], const char &actual[]);
    void assertEquals(string message, const uchar &expected[], const uchar &actual[]);
    void assertEquals(string message, const short &expected[], const short &actual[]);
    void assertEquals(string message, const ushort &expected[], const ushort &actual[]);
    void assertEquals(string message, const int &expected[], const int &actual[]);
    void assertEquals(string message, const uint &expected[], const uint &actual[]);
    void assertEquals(string message, const long &expected[], const long &actual[]);
    void assertEquals(string message, const ulong &expected[], const ulong &actual[]);
    void assertEquals(string message, const datetime &expected[], const datetime &actual[]);
    void assertEquals(string message, const color &expected[], const color &actual[]);
    void assertEquals(string message, const float &expected[], const float &actual[]);
    void assertEquals(string message, const double &expected[], const double &actual[]);
    void assertEquals(string message, const string &expected[], const string &actual[]);

private:
    bool assertArraySize(string message, const int expectedSize, const int actualSize);
    void TrySetImage();
};

template <typename TRecord>
UnitTest::UnitTest(string directory, string csvFileName, int maxAsserts)
{
    mDirectory = directory;
    mCSVFileName = csvFileName;

    PendingRecord.MaxAsserts(maxAsserts);
}

template <typename TRecord>
UnitTest::~UnitTest(void)
{
}

template <typename TRecord>
void UnitTest::addTest(string name)
{
    if (PendingRecord.Name() != "")
    {
        return;
    }

    PendingRecord.Name(name);
}

template <typename TRecord>
void UnitTest::setSuccess()
{
    if (PendingRecord.Asserts() >= PendingRecord.MaxAsserts())
    {
        return;
    }

    PendingRecord.Result("Passed");
    PendingRecord.IncrementAsserts();
    TrySetImage();

    CSVRecordWriter<TRecord>::Write();
}

template <typename TRecord>
void UnitTest::setFailure(string message)
{
    PendingRecord.Result("Failed");
    PendingRecord.ErrorMessage(message);
    PendingRecord.IncrementAsserts();
    TrySetImage();

    CSVRecordWriter<TRecord>::Write();
}

template <typename TRecord>
void UnitTest::TrySetImage()
{
    string filePath = "";
    int screenShotError = ScreenShotHelper::TryTakeUnitTestScreenShot(mDirectory, filePath);
    if (screenShotError != ERR_NO_ERROR)
    {
        return;
    }

    PendingRecord.Image(filePath);
}

template <typename TRecord>
void UnitTest::assertEquals(string message, bool expected, bool actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        string m;
        StringConcatenate(m, message, ": expected is <", expected, "> but <", actual, ">");
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, char expected, char actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + CharToString(expected) +
                         "> but <" + CharToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, uchar expected, uchar actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + CharToString(expected) +
                         "> but <" + CharToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, short expected, short actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + IntegerToString(expected) +
                         "> but <" + IntegerToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, ushort expected, ushort actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + IntegerToString(expected) +
                         "> but <" + IntegerToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, int expected, int actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + IntegerToString(expected) +
                         "> but <" + IntegerToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, uint expected, uint actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + IntegerToString(expected) +
                         "> but <" + IntegerToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, long expected, long actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + IntegerToString(expected) +
                         "> but <" + IntegerToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, ulong expected, ulong actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + IntegerToString(expected) +
                         "> but <" + IntegerToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, datetime expected, datetime actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + TimeToString(expected) +
                         "> but <" + TimeToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, color expected, color actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + ColorToString(expected) +
                         "> but <" + ColorToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, float expected, float actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + DoubleToString(expected) +
                         "> but <" + DoubleToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, double expected, double actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + DoubleToString(expected) +
                         "> but <" + DoubleToString(actual) + ">";
        setFailure(m);
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, string expected, string actual)
{
    if (expected == actual)
    {
        setSuccess();
    }
    else
    {
        const string m = message + ": expected is <" + expected +
                         "> but <" + actual + ">";
        setFailure(m);
    }
}

template <typename TRecord>
bool UnitTest::assertArraySize(string message, const int expectedSize, const int actualSize)
{
    if (expectedSize == actualSize)
    {
        return true;
    }
    else
    {
        const string m = message + ": expected array size is <" + IntegerToString(expectedSize) +
                         "> but <" + IntegerToString(actualSize) + ">";
        setFailure(m);
        return false;
    }
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const bool &expected[], const bool &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            string m;
            StringConcatenate(m, message, ": expected array[", IntegerToString(i), "] is <",
                              expected[i], "> but <", actual[i], ">");
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const char &expected[], const char &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             CharToString(expected[i]) +
                             "> but <" + CharToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const uchar &expected[], const uchar &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             CharToString(expected[i]) +
                             "> but <" + CharToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const short &expected[], const short &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             IntegerToString(expected[i]) +
                             "> but <" + IntegerToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const ushort &expected[], const ushort &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             IntegerToString(expected[i]) +
                             "> but <" + IntegerToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const int &expected[], const int &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             IntegerToString(expected[i]) +
                             "> but <" + IntegerToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const uint &expected[], const uint &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             IntegerToString(expected[i]) +
                             "> but <" + IntegerToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const long &expected[], const long &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             IntegerToString(expected[i]) +
                             "> but <" + IntegerToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const ulong &expected[], const ulong &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             IntegerToString(expected[i]) +
                             "> but <" + IntegerToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const datetime &expected[], const datetime &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             TimeToString(expected[i]) +
                             "> but <" + TimeToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const color &expected[], const color &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             ColorToString(expected[i]) +
                             "> but <" + ColorToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const float &expected[], const float &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             DoubleToString(expected[i]) +
                             "> but <" + DoubleToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}

template <typename TRecord>
void UnitTest::assertEquals(string message, const double &expected[], const double &actual[])
{
    const int expectedSize = ArraySize(expected);
    const int actualSize = ArraySize(actual);

    if (!assertArraySize(message, expectedSize, actualSize))
    {
        return;
    }

    for (int i = 0; i < actualSize; i++)
    {
        if (expected[i] != actual[i])
        {
            const string m = message + ": expected array[" + IntegerToString(i) + "] is <" +
                             DoubleToString(expected[i]) +
                             "> but <" + DoubleToString(actual[i]) + ">";
            setFailure(m);
            return;
        }
    }

    setSuccess();
}
