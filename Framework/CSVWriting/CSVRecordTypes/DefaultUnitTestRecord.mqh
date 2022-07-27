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
public:
    string Name;
    datetime AssertTime;
    string Result;
    string ErrorMessage;
    int Asserts;
    int MaxAsserts;
    string Image;

    DefaultUnitTestRecord();
    ~DefaultUnitTestRecord();

    void Write(int fileHandle);
    void Reset();
};

DefaultUnitTestRecord::DefaultUnitTestRecord()
{
    Name = "";
    AssertTime = 0;
    Result = "";
    ErrorMessage = "";
    Asserts = 0;
    MaxAsserts = 0;
    Image = "";
}

DefaultUnitTestRecord::~DefaultUnitTestRecord() {}

void DefaultUnitTestRecord::Write(int fileHandle)
{
    FileWrite(fileHandle, Name, AssertTime, Result, ErrorMessage, Asserts, MaxAsserts, Image);
}

void DefaultUnitTestRecord::Reset()
{
    AssertTime = 0;
    Result = "";
    ErrorMessage = "";
    Asserts = 0;
    MaxAsserts = 0;
    Image = "";
}
