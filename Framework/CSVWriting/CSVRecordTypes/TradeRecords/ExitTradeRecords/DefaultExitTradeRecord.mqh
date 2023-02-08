//+------------------------------------------------------------------+
//|                                      DefaultExitTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class DefaultExitTradeRecord : public RecordColumns
{
public:
    DefaultExitTradeRecord();
    ~DefaultExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void WriteCloseHeaders(int fileHandle);
    void WriteAdditionalHeaders(int fileHandle, bool writeDelimiter);

    void WriteCloseRecord(int fileHandle);
    void WriteAdditionalRecord(int fileHandle, bool writeDelimiter);
};

DefaultExitTradeRecord::DefaultExitTradeRecord() : RecordColumns() {}
DefaultExitTradeRecord::~DefaultExitTradeRecord() {}

void DefaultExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    WriteCloseHeaders(fileHandle);
    WriteAdditionalHeaders(fileHandle, writeDelimiter);
}

void DefaultExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    WriteCloseRecord(fileHandle);
    WriteAdditionalRecord(fileHandle, writeDelimiter);
}

void DefaultExitTradeRecord::WriteCloseHeaders(int fileHandle)
{
    FileHelper::WriteString(fileHandle, "Exit Time");
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Order Type");
    FileHelper::WriteString(fileHandle, "Account Balance After");
    FileHelper::WriteString(fileHandle, "Entry Price");
    FileHelper::WriteString(fileHandle, "Slippage");
    FileHelper::WriteString(fileHandle, "Original Stop Loss");
    FileHelper::WriteString(fileHandle, "Exit Price");
}

void DefaultExitTradeRecord::WriteAdditionalHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Total Move Pips");
    FileHelper::WriteString(fileHandle, "Potential RR");
    FileHelper::WriteString(fileHandle, "RR Secured");
}

void DefaultExitTradeRecord::WriteCloseRecord(int fileHandle)
{
    FileHelper::WriteDateTime(fileHandle, ExitTime);
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteString(fileHandle, OrderType);
    FileHelper::WriteDouble(fileHandle, AccountBalanceAfter, 2);
    FileHelper::WriteDouble(fileHandle, EntryPrice, Digits);
    FileHelper::WriteDouble(fileHandle, Slippage, Digits);
    FileHelper::WriteDouble(fileHandle, OriginalStopLoss, Digits);
    FileHelper::WriteDouble(fileHandle, ExitPrice, Digits);
}

void DefaultExitTradeRecord::WriteAdditionalRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDouble(fileHandle, TotalMovePips(), Digits);
    FileHelper::WriteDouble(fileHandle, PotentialRR(), 2);
    FileHelper::WriteDouble(fileHandle, RRSecured(), 2);
}