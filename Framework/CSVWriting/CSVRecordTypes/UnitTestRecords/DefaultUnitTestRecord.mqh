//+------------------------------------------------------------------+
//|                                        DefaultUnitTestRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Helpers\FileHelper.mqh>

class DefaultUnitTestRecord
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

    static void WriteHeaders(int fileHandle);
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

static void DefaultUnitTestRecord::WriteHeaders(int fileHandle)
{
    FileHelper::WriteString(fileHandle, "Name");
    FileHelper::WriteString(fileHandle, "Description");
    FileHelper::WriteString(fileHandle, "Assert Time");
    FileHelper::WriteString(fileHandle, "Result");
    FileHelper::WriteString(fileHandle, "Message");
    FileHelper::WriteString(fileHandle, "Additional Information");
    FileHelper::WriteString(fileHandle, "Assert Number");
    FileHelper::WriteString(fileHandle, "Max Asserts");
    FileHelper::WriteString(fileHandle, "Image");
    FileHelper::WriteString(fileHandle, "Notes", false);
}

void DefaultUnitTestRecord::WriteRecord(int fileHandle)
{
    FileHelper::WriteString(fileHandle, Name);
    FileHelper::WriteString(fileHandle, Description);
    FileHelper::WriteDateTime(fileHandle, AssertTime);
    FileHelper::WriteString(fileHandle, Result);
    FileHelper::WriteString(fileHandle, Message);
    FileHelper::WriteString(fileHandle, AdditionalInformation);
    FileHelper::WriteInteger(fileHandle, Asserts);
    FileHelper::WriteInteger(fileHandle, MaxAsserts);
    FileHelper::WriteString(fileHandle, Image);
    FileHelper::WriteString(fileHandle, Notes, false);
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
