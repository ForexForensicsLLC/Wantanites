//+------------------------------------------------------------------+
//|                                        DefaultUnitTestRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\ICSVRecord.mqh>

class DefaultUnitTestRecord : ICSVRecord
{
public:
    string Name;
    string Description;
    datetime AssertTime;
    string Result;
    string Message;
    string AdditionalInformation;
    int Asserts;
    int MaxAsserts;
    string Image;
    string Notes;

    DefaultUnitTestRecord();
    ~DefaultUnitTestRecord();

    virtual void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
    virtual void Reset();
};

DefaultUnitTestRecord::DefaultUnitTestRecord()
{
    Name = "";
    Description = "";
    AssertTime = 0;
    Result = "";
    Message = "";
    AdditionalInformation = "";
    Asserts = 0;
    MaxAsserts = 0;
    Image = "";
    Notes = "";
}

DefaultUnitTestRecord::~DefaultUnitTestRecord() {}

void DefaultUnitTestRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle, "Name", "Description", "Assert Time", "Result", "Message", "Additional Information", "Assert Number", "Max Asserts", "Image", "Notes");
}

void DefaultUnitTestRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle, Name, Description, AssertTime, Result, Message, AdditionalInformation, Asserts, MaxAsserts, Image, Notes);
}

void DefaultUnitTestRecord::Reset()
{
    AssertTime = 0;
    Result = "";
    Message = "";
    AdditionalInformation = "";
    Image = "";
    Notes = "";
}
