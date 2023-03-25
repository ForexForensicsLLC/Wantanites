//+------------------------------------------------------------------+
//|                                      ForexForensicsExitTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class ForexForensicsExitTradeRecord : public RecordColumns
{
public:
    ForexForensicsExitTradeRecord();
    ~ForexForensicsExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

ForexForensicsExitTradeRecord::ForexForensicsExitTradeRecord() : RecordColumns() {}
ForexForensicsExitTradeRecord::~ForexForensicsExitTradeRecord() {}

void ForexForensicsExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Exit Time");
    FileHelper::WriteString(fileHandle, "Account Balance After");
    FileHelper::WriteString(fileHandle, "Exit Price");
    FileHelper::WriteString(fileHandle, "RR Secured", writeDelimiter);
}

void ForexForensicsExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, ExitTime);
    FileHelper::WriteDouble(fileHandle, AccountBalanceAfter, 2);
    FileHelper::WriteDouble(fileHandle, ExitPrice, Digits);
    FileHelper::WriteDouble(fileHandle, RRSecured(), 2, writeDelimiter);
}

void ForexForensicsExitTradeRecord::ReadRow(int fileHandle)
{
    ExitTime = FileReadDatetime(fileHandle);
    AccountBalanceAfter = StrToDouble(FileReadString(fileHandle));
    ExitPrice = StrToDouble(FileReadString(fileHandle));
    mRRSecured = StrToDouble(FileReadString(fileHandle));
}