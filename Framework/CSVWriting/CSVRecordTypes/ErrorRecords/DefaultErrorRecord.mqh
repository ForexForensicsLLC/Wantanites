//+------------------------------------------------------------------+
//|                                           DefaultErrorRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\FileHelper.mqh>

class DefaultErrorRecord
{
public:
    int MagicNumber;
    datetime ErrorTime;
    int Error;
    int LastState;
    string AdditionalInformation;

public:
    DefaultErrorRecord();
    ~DefaultErrorRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);
};

DefaultErrorRecord::DefaultErrorRecord()
{
    MagicNumber = EMPTY;
    ErrorTime = 0;
    Error = ERR_NO_ERROR;
    LastState = EMPTY;
    AdditionalInformation = "EMPTY";
}

DefaultErrorRecord::~DefaultErrorRecord() {}

void DefaultErrorRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Error Time");
    FileHelper::WriteString(fileHandle, "Error");
    FileHelper::WriteString(fileHandle, "Last State");
    FileHelper::WriteString(fileHandle, "Additional Information", writeDelimiter);
}

void DefaultErrorRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteDateTime(fileHandle, ErrorTime);
    FileHelper::WriteInteger(fileHandle, Error);
    FileHelper::WriteInteger(fileHandle, LastState);
    FileHelper::WriteString(fileHandle, AdditionalInformation, writeDelimiter);
}
