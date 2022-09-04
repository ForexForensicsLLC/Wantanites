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
    datetime ErrorTime;
    int Error;
    int LastState;
    string ErrorImage;

public:
    DefaultErrorRecord();
    ~DefaultErrorRecord();

    static void WriteHeaders(int fileHandle);
    virtual void WriteEntireRecord(int fileHandle);
};

DefaultErrorRecord::DefaultErrorRecord()
{
}

DefaultErrorRecord::~DefaultErrorRecord()
{
}

void DefaultErrorRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle,
              "Error Time",
              "Error",
              "LastState",
              "Error Image");
}

void DefaultErrorRecord::WriteEntireRecord(int fileHandle)
{
    FileWrite(fileHandle,
              ErrorTime,
              Error,
              LastState,
              ErrorImage);
}
