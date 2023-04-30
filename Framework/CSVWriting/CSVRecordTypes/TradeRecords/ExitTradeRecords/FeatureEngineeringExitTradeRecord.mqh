//+------------------------------------------------------------------+
//|                                      FeatureEngineeringExitTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\ExitTradeRecords\ForexForensicsExitTradeRecord.mqh>

class FeatureEngineeringExitTradeRecord : public ForexForensicsExitTradeRecord
{
public:
    FeatureEngineeringExitTradeRecord();
    ~FeatureEngineeringExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

FeatureEngineeringExitTradeRecord::FeatureEngineeringExitTradeRecord() : ForexForensicsExitTradeRecord() {}
FeatureEngineeringExitTradeRecord::~FeatureEngineeringExitTradeRecord() {}

void FeatureEngineeringExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsExitTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Outcome");
}

void FeatureEngineeringExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsExitTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, Outcome);
}

void FeatureEngineeringExitTradeRecord::ReadRow(int fileHandle)
{
    ForexForensicsExitTradeRecord::ReadRow(fileHandle);
    Outcome = FileReadString(fileHandle);
}