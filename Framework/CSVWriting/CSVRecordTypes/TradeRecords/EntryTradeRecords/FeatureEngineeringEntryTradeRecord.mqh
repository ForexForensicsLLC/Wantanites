//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\ForexForensicsEntryTradeRecord.mqh>

class FeatureEngineeringEntryTradeRecord : public ForexForensicsEntryTradeRecord
{
public:
    FeatureEngineeringEntryTradeRecord();
    ~FeatureEngineeringEntryTradeRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

FeatureEngineeringEntryTradeRecord::FeatureEngineeringEntryTradeRecord() : ForexForensicsEntryTradeRecord() {}
FeatureEngineeringEntryTradeRecord::~FeatureEngineeringEntryTradeRecord() {}

void FeatureEngineeringEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsEntryTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "News Impact");
    FileHelper::WriteString(fileHandle, "Day of Week", writeDelimiter);
}
void FeatureEngineeringEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsEntryTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteInteger(fileHandle, NewsImpact);
    FileHelper::WriteInteger(fileHandle, DayOfWeek, writeDelimiter);
}

void FeatureEngineeringEntryTradeRecord::ReadRow(int fileHandle)
{
    ForexForensicsEntryTradeRecord::ReadRow(fileHandle);
    NewsImpact = StringToInteger(FileReadString(fileHandle));
    DayOfWeek = StringToInteger(FileReadString(fileHandle));
}