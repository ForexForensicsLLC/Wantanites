//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\MQLVersionSpecific\Helpers\DateTimeHelper\DateTimeHelper.mqh>
#include <Wantanites\Framework\Helpers\FileHelper.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ObjectRecords\EconomicEventRecord.mqh>

class EconomicEventAndCandleRecord : public EconomicEventRecord
{
public:
    double Open;
    double Close;
    double High;
    double Low;

    EconomicEventAndCandleRecord();
    ~EconomicEventAndCandleRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

EconomicEventAndCandleRecord::EconomicEventAndCandleRecord() {}
EconomicEventAndCandleRecord::~EconomicEventAndCandleRecord() {}

void EconomicEventAndCandleRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    EconomicEventRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Open");
    FileHelper::WriteString(fileHandle, "Close");
    FileHelper::WriteString(fileHandle, "High");
    FileHelper::WriteString(fileHandle, "Low", writeDelimiter);
}
void EconomicEventAndCandleRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    EconomicEventRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteDouble(fileHandle, Open, Digits);
    FileHelper::WriteDouble(fileHandle, Close, Digits);
    FileHelper::WriteDouble(fileHandle, High, Digits);
    FileHelper::WriteDouble(fileHandle, Low, Digits, writeDelimiter);
}

void EconomicEventAndCandleRecord::ReadRow(int fileHandle)
{
    EconomicEventRecord::ReadRow(fileHandle);
    Open = StrToDouble(FileReadString(fileHandle));
    Close = StrToDouble(FileReadString(fileHandle));
    High = StrToDouble(FileReadString(fileHandle));
    Low = StrToDouble(FileReadString(fileHandle));
}