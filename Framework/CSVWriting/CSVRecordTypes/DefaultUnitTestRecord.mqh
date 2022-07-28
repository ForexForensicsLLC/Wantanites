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
    string Description;
    datetime AssertTime;
    string Result;
    string Message;
    int Asserts;
    int MaxAsserts;
    string Image;

    DefaultUnitTestRecord();
    ~DefaultUnitTestRecord();

    void WriteHeaders(int fileHandle);
    void WriteRecord(int fileHandle);
    void Reset();
};

DefaultUnitTestRecord::DefaultUnitTestRecord()
{
    Name = "";
    Description = "";
    AssertTime = 0;
    Result = "";
    Message = "";
    Asserts = 0;
    MaxAsserts = 0;
    Image = "";
}

DefaultUnitTestRecord::~DefaultUnitTestRecord() {}

void DefaultUnitTestRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle, "Name", "Description", "Assert Time", "Result", "Message", "Assert Number", "Max Asserts", "Image");
}

void DefaultUnitTestRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle, Name, Description, AssertTime, Result, Message, Asserts, MaxAsserts, Image);
}

void DefaultUnitTestRecord::Reset()
{
    AssertTime = 0;
    Result = "";
    Message = "";
    Image = "";
}
