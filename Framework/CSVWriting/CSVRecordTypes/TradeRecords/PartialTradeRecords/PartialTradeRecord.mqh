//+------------------------------------------------------------------+
//|                                    DefaultPartialTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class PartialTradeRecord : public RecordColumns
{
public:
    PartialTradeRecord();
    ~PartialTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

PartialTradeRecord::PartialTradeRecord() : RecordColumns() {}
PartialTradeRecord::~PartialTradeRecord() {}

void PartialTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "New Ticket Number");
    FileHelper::WriteString(fileHandle, "Expected Partial RR");
    FileHelper::WriteString(fileHandle, "ActualPartialRR", writeDelimiter);
}

void PartialTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteInteger(fileHandle, NewTicketNumber);
    FileHelper::WriteDouble(fileHandle, ExpectedPartialRR, 2);
    FileHelper::WriteDouble(fileHandle, ActualPartialRR, 2, writeDelimiter);
}

void PartialTradeRecord::ReadRow(int fileHandle)
{
    MagicNumber = StrToInteger(FileReadString(fileHandle));
    TicketNumber = StrToInteger(FileReadString(fileHandle));
    NewTicketNumber = StrToInteger(FileReadString(fileHandle));
    ExpectedPartialRR = StrToDouble(FileReadString(fileHandle));
    ActualPartialRR = StrToDouble(FileReadString(fileHandle));
}