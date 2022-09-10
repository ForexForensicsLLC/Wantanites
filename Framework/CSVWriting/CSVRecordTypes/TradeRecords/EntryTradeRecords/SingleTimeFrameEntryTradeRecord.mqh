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

class SingleTimeFrameEntryTradeRecord : public DefaultEntryTradeRecord
{
public:
    SingleTimeFrameEntryTradeRecord();
    ~SingleTimeFrameEntryTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

SingleTimeFrameEntryTradeRecord::SingleTimeFrameEntryTradeRecord() : DefaultEntryTradeRecord() {}
SingleTimeFrameEntryTradeRecord::~SingleTimeFrameEntryTradeRecord() {}

void SingleTimeFrameEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    DefaultEntryTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Entry Image", writeDelimiter);
}

void SingleTimeFrameEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    DefaultEntryTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, EntryImage, writeDelimiter);
}

void SingleTimeFrameEntryTradeRecord::ReadRow(int fileHandle)
{
    DefaultEntryTradeRecord::ReadRow(fileHandle);
    EntryImage = FileReadString(fileHandle);
}
