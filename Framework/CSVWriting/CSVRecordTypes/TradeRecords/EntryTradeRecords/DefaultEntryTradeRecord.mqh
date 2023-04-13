//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

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
    FileHelper::WriteString(fileHandle, "Entry Time");
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Order Type");
    FileHelper::WriteString(fileHandle, "Account Balance Before");
    FileHelper::WriteString(fileHandle, "Lots");
    FileHelper::WriteString(fileHandle, "Entry Price");
    FileHelper::WriteString(fileHandle, "Entry Slippage");
    FileHelper::WriteString(fileHandle, "Original Stop Loss", writeDelimiter);
}
void DefaultEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, EntryTime);
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteString(fileHandle, OrderDirection);
    FileHelper::WriteDouble(fileHandle, AccountBalanceBefore, 2);
    FileHelper::WriteDouble(fileHandle, Lots, 2);
    FileHelper::WriteDouble(fileHandle, EntryPrice, Digits);
    FileHelper::WriteDouble(fileHandle, EntrySlippage, Digits);
    FileHelper::WriteDouble(fileHandle, OriginalStopLoss, Digits, writeDelimiter);
}

void DefaultEntryTradeRecord::ReadRow(int fileHandle)
{
    EntryTime = FileReadDatetime(fileHandle);
    MagicNumber = StrToInteger(FileReadString(fileHandle));
    TicketNumber = StrToInteger(FileReadString(fileHandle));
    Symbol = FileReadString(fileHandle);
    OrderDirection = FileReadString(fileHandle);
    AccountBalanceBefore = StrToDouble(FileReadString(fileHandle));
    Lots = StrToDouble(FileReadString(fileHandle));
    EntryPrice = StrToDouble(FileReadString(fileHandle));
    EntrySlippage = StrToDouble(FileReadString(fileHandle));
    OriginalStopLoss = StrToDouble(FileReadString(fileHandle));
}