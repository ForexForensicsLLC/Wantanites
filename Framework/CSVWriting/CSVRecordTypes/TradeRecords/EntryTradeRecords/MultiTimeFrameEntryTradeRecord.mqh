//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\DefaultEntryTradeRecord.mqh>

class MultiTimeFrameEntryTradeRecord : public DefaultEntryTradeRecord
{
public:
    MultiTimeFrameEntryTradeRecord();
    ~MultiTimeFrameEntryTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

MultiTimeFrameEntryTradeRecord::MultiTimeFrameEntryTradeRecord() : DefaultEntryTradeRecord() {}
MultiTimeFrameEntryTradeRecord::~MultiTimeFrameEntryTradeRecord() {}

void MultiTimeFrameEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    DefaultEntryTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "High TF Entry Image");
    FileHelper::WriteString(fileHandle, "Lower TF Entry Imaage", writeDelimiter);
}

void MultiTimeFrameEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    DefaultEntryTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, HigherTimeFrameEntryImage);
    FileHelper::WriteString(fileHandle, LowerTimeFrameEntryImage, writeDelimiter);
}

void MultiTimeFrameEntryTradeRecord::ReadRow(int fileHandle)
{
    DefaultEntryTradeRecord::ReadRow(fileHandle);
    HigherTimeFrameEntryImage = FileReadString(fileHandle);
    LowerTimeFrameEntryImage = FileReadString(fileHandle);
}
