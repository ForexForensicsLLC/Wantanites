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

class ForexForensicsEntryTradeRecord : public RecordColumns
{
public:
    ForexForensicsEntryTradeRecord();
    ~ForexForensicsEntryTradeRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

ForexForensicsEntryTradeRecord::ForexForensicsEntryTradeRecord() : RecordColumns() {}
ForexForensicsEntryTradeRecord::~ForexForensicsEntryTradeRecord() {}

void ForexForensicsEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Entry Time");
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Order Type");
    FileHelper::WriteString(fileHandle, "Account Balance Before");
    FileHelper::WriteString(fileHandle, "Lots");
    FileHelper::WriteString(fileHandle, "Entry Price");
    FileHelper::WriteString(fileHandle, "Original Stop Loss");
    FileHelper::WriteString(fileHandle, "During News", writeDelimiter);
}
void ForexForensicsEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, EntryTime);
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteString(fileHandle, OrderDirection);
    FileHelper::WriteDouble(fileHandle, AccountBalanceBefore, 2);
    FileHelper::WriteDouble(fileHandle, Lots, 2);
    FileHelper::WriteDouble(fileHandle, EntryPrice, Digits());
    FileHelper::WriteDouble(fileHandle, OriginalStopLoss, Digits());
    FileHelper::WriteString(fileHandle, DuringNews, writeDelimiter);
}

void ForexForensicsEntryTradeRecord::ReadRow(int fileHandle)
{
    EntryTime = FileReadDatetime(fileHandle);
    MagicNumber = StringToInteger(FileReadString(fileHandle));
    TicketNumber = StringToInteger(FileReadString(fileHandle));
    Symbol = FileReadString(fileHandle);
    OrderDirection = FileReadString(fileHandle);
    AccountBalanceBefore = StringToDouble(FileReadString(fileHandle));
    Lots = StringToDouble(FileReadString(fileHandle));
    EntryPrice = StringToDouble(FileReadString(fileHandle));
    OriginalStopLoss = StringToDouble(FileReadString(fileHandle));
    DuringNews = FileHelper::ReadBool(fileHandle);
}