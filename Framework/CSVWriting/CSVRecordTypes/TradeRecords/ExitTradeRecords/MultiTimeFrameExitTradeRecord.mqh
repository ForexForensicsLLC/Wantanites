//+------------------------------------------------------------------+
//|                                        SPMTFCloseTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\ExitTradeRecords\DefaultExitTradeRecord.mqh>

class MultiTimeFrameExitTradeRecord : public DefaultExitTradeRecord
{
public:
    MultiTimeFrameExitTradeRecord();
    ~MultiTimeFrameExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);
};

MultiTimeFrameExitTradeRecord::MultiTimeFrameExitTradeRecord() : DefaultExitTradeRecord() {}
MultiTimeFrameExitTradeRecord::~MultiTimeFrameExitTradeRecord() {}

void MultiTimeFrameExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteCloseHeaders(fileHandle);
    FileHelper::WriteString(fileHandle, "High TF Entry Image");
    FileHelper::WriteString(fileHandle, "Lower TF Entry Imaage");

    DefaultExitTradeRecord::WriteAdditionalHeaders(fileHandle, writeDelimiter);
}

void MultiTimeFrameExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteCloseRecord(fileHandle);
    FileHelper::WriteString(fileHandle, HigherTimeFrameEntryImage);
    FileHelper::WriteString(fileHandle, LowerTimeFrameEntryImage);

    DefaultExitTradeRecord::WriteAdditionalRecord(fileHandle, writeDelimiter);
}