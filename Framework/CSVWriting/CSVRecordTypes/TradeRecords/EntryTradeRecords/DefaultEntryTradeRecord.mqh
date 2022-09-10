//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class DefaultEntryTradeRecord : public RecordColumns
{
public:
    DefaultEntryTradeRecord();
    ~DefaultEntryTradeRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

DefaultEntryTradeRecord::DefaultEntryTradeRecord() : RecordColumns() {}
DefaultEntryTradeRecord::~DefaultEntryTradeRecord() {}

void DefaultEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Order Type");
    FileHelper::WriteString(fileHandle, "Account Balance Before");
    FileHelper::WriteString(fileHandle, "Lots");
    FileHelper::WriteString(fileHandle, "Entry Time");
    FileHelper::WriteString(fileHandle, "Entry Price");
    FileHelper::WriteString(fileHandle, "Entry Stop Loss", writeDelimiter);
}
void DefaultEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteString(fileHandle, OrderType);
    FileHelper::WriteDouble(fileHandle, AccountBalanceBefore, 2);
    FileHelper::WriteDouble(fileHandle, Lots, 2);
    FileHelper::WriteDateTime(fileHandle, EntryTime);
    FileHelper::WriteDouble(fileHandle, EntryPrice, Digits);
    FileHelper::WriteDouble(fileHandle, EntryStopLoss, Digits, writeDelimiter);
}

void DefaultEntryTradeRecord::ReadRow(int fileHandle)
{
    MagicNumber = StrToInteger(FileReadString(fileHandle));
    TicketNumber = StrToInteger(FileReadString(fileHandle));
    Symbol = FileReadString(fileHandle);
    OrderType = FileReadString(fileHandle);
    AccountBalanceBefore = StrToDouble(FileReadString(fileHandle));
    Lots = StrToDouble(FileReadString(fileHandle));
    EntryTime = FileReadDatetime(fileHandle);
    EntryPrice = StrToDouble(FileReadString(fileHandle));
    EntryStopLoss = StrToDouble(FileReadString(fileHandle));
}