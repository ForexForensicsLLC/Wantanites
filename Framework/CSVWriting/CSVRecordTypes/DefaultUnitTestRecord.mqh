//+------------------------------------------------------------------+
//|                                        DefaultUnitTestRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\ICSVRecord.mqh>

class DefaultUnitTestRecord : ICSVRecord
{
protected:
    string mName;
    string mResult;
    string mErrorMessage;
    int mAsserts;
    int mMaxAsserts;
    string mImage;

public:
    string Name() { return mName; }
    void Name(string name) { mName = name; }

    void Result(string result) { mResult = result; }

    void ErrorMessage(string errorMessage) { mErrorMessage = errorMessage; }

    int Asserts() { return mAsserts; }
    void IncrementAsserts() { mAsserts += 1; }

    int MaxAsserts() { return mMaxAsserts; }
    void MaxAsserts(int maxAsserts) { mMaxAsserts = maxAsserts; }

    void Image(string image) { mImage = image; }

    DefaultUnitTestRecord();
    ~DefaultUnitTestRecord();

    void Write(int fileHandle);
    void Reset();
};

DefaultUnitTestRecord::DefaultUnitTestRecord()
{
    mName = "";
    mResult = "";
    mErrorMessage = "";
    mAsserts = 0;
    mMaxAsserts = 0;
    mImage = "";
}
DefaultUnitTestRecord::~DefaultUnitTestRecord() {}

void DefaultUnitTestRecord::Write(int fileHandle)
{
    FileWrite(fileHandle, mName, mResult, mErrorMessage, mAsserts, mMaxAsserts, mImage);
}

void DefaultUnitTestRecord::Reset()
{
    mResult = "";
    mErrorMessage = "";
    mAsserts = 0;
    mMaxAsserts = 0;
    mImage = "";
}
