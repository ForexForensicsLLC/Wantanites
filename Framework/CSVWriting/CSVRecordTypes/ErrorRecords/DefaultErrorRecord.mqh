//+------------------------------------------------------------------+
//|                                           DefaultErrorRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>
#include <Wantanites\Framework\Helpers\FileHelper.mqh>

class DefaultErrorRecord
{
public:
    datetime ErrorTime;
    int MagicNumber;
    string Symbol;
    string MethodName;
    int Error;
    int LastState;
    string AdditionalInformation;
    int RowNumber;

public:
    DefaultErrorRecord();
    ~DefaultErrorRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

DefaultErrorRecord::DefaultErrorRecord()
{
    ErrorTime = 0;
    MagicNumber = EMPTY;
    Symbol = ConstantValues::UnsetString;
    MethodName = ConstantValues::UnsetString;
    Error = Errors::NO_ERROR;
    LastState = EMPTY;
    AdditionalInformation = ConstantValues::UnsetString;
    RowNumber = ConstantValues::UnsetString;
}

DefaultErrorRecord::~DefaultErrorRecord() {}

void DefaultErrorRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Error Time");
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Method");
    FileHelper::WriteString(fileHandle, "Error");
    FileHelper::WriteString(fileHandle, "Last State");
    FileHelper::WriteString(fileHandle, "Additional Information", writeDelimiter);
}

void DefaultErrorRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, ErrorTime);
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteString(fileHandle, Method);
    FileHelper::WriteInteger(fileHandle, Error);
    FileHelper::WriteInteger(fileHandle, LastState);
    FileHelper::WriteString(fileHandle, AdditionalInformation, writeDelimiter);
}

void DefaultErrorRecord::ReadRow(int fileHandle)
{
    ErrorTime = FileReadDatetime(fileHandle);
    MagicNumber = StrToInteger(FileReadString(fileHandle));
    Symbol = FileReadString(fileHandle);
    MethodName = FileReadString(fileHandle);
    Error = StrToInteger(FileReadString(fileHandle));
    LastState = StrToInteger(FileReadString(fileHandle));
    AdditionalInformation = FileReadString(fileHandle);
}
