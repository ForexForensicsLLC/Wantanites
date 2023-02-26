//+------------------------------------------------------------------+
//|                                          STFCloseTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\ExitTradeRecords\DefaultExitTradeRecord.mqh>

class SingleTimeFrameExitTradeRecord : public DefaultExitTradeRecord
{
public:
    SingleTimeFrameExitTradeRecord();
    ~SingleTimeFrameExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

SingleTimeFrameExitTradeRecord::SingleTimeFrameExitTradeRecord() : DefaultExitTradeRecord() {}
SingleTimeFrameExitTradeRecord::~SingleTimeFrameExitTradeRecord() {}

void SingleTimeFrameExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Exit Image", writeDelimiter);
}

void SingleTimeFrameExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, ExitImage, writeDelimiter);
}

void SingleTimeFrameExitTradeRecord::ReadRow(int fileHandle)
{
    DefaultExitTradeRecord::ReadRow(fileHandle);
    ExitImage = FileReadString(fileHandle);
}