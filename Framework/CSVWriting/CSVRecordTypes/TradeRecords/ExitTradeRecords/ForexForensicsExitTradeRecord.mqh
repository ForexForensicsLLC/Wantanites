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
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "Account Balance After");
    FileHelper::WriteString(fileHandle, "Exit Price");
    FileHelper::WriteString(fileHandle, "Original Stop Loss");
    FileHelper::WriteString(fileHandle, "Furthest Equity Drawdown", writeDelimiter);
}

void ForexForensicsExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, ExitTime);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteDouble(fileHandle, AccountBalanceAfter, 2);
    FileHelper::WriteDouble(fileHandle, ExitPrice, Digits());
    FileHelper::WriteDouble(fileHandle, OriginalStopLoss, Digits());
    FileHelper::WriteDouble(fileHandle, FurthestEquityDrawdownPercent, 3, writeDelimiter);
}

void ForexForensicsExitTradeRecord::ReadRow(int fileHandle)
{
    ExitTime = FileReadDatetime(fileHandle);
    AccountBalanceAfter = StringToDouble(FileReadString(fileHandle));
    ExitPrice = StringToDouble(FileReadString(fileHandle));
    OriginalStopLoss = StringToDouble(FileReadString(fileHandle));
    FurthestEquityDrawdownPercent = StringToDouble(FileReadString(fileHandle));
}