//+------------------------------------------------------------------+
//|                                        SPMTFCloseTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\ExitTradeRecords\DefaultExitTradeRecord.mqh>

class MultiTimeFrameExitTradeRecord : public DefaultExitTradeRecord
{
public:
    MultiTimeFrameExitTradeRecord();
    ~MultiTimeFrameExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

MultiTimeFrameExitTradeRecord::MultiTimeFrameExitTradeRecord() : DefaultExitTradeRecord() {}
MultiTimeFrameExitTradeRecord::~MultiTimeFrameExitTradeRecord() {}

void MultiTimeFrameExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "High TF Exit Image");
    FileHelper::WriteString(fileHandle, "Lower TF Exit Imaage", writeDelimiter);
}

void MultiTimeFrameExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, HigherTimeFrameExitImage);
    FileHelper::WriteString(fileHandle, LowerTimeFrameExitImage, writeDelimiter);
}

void MultiTimeFrameExitTradeRecord::ReadRow(int fileHandle)
{
    DefaultExitTradeRecord::ReadRow(fileHandle);
    HigherTimeFrameExitImage = FileReadString(fileHandle);
    LowerTimeFrameExitImage = FileReadString(fileHandle);
}