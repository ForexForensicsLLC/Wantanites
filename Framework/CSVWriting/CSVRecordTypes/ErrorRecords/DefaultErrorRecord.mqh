//+------------------------------------------------------------------+
//|                                           DefaultErrorRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class DefaultErrorRecord
{
public:
    int MagicNumber;
    datetime ErrorTime;
    int Error;
    int LastState;
    string ErrorImage;

public:
    DefaultErrorRecord();
    ~DefaultErrorRecord();

    static void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
};

DefaultErrorRecord::DefaultErrorRecord()
{
    MagicNumber = EMPTY;
    ErrorTime = 0;
    Error = ERR_NO_ERROR;
    LastState = EMPTY;
    ErrorImage = "EMPTY";
}

DefaultErrorRecord::~DefaultErrorRecord() {}

void DefaultErrorRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle,
              "Magic Number",
              "Error Time",
              "Error",
              "LastState",
              "Error Image");
}

void DefaultErrorRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle,
              MagicNumber,
              ErrorTime,
              Error,
              LastState,
              ErrorImage);
}
