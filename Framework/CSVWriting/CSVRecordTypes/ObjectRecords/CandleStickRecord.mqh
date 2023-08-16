//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\FileHelper.mqh>
#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class CandleStickRecord : public RecordColumns
{
public:
    datetime Date;
    double Open;
    double Close;
    double High;
    double Low;

    CandleStickRecord();
    ~CandleStickRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

CandleStickRecord::CandleStickRecord() {}
CandleStickRecord::~CandleStickRecord() {}

void CandleStickRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Date");
    FileHelper::WriteString(fileHandle, "Open");
    FileHelper::WriteString(fileHandle, "Close");
    FileHelper::WriteString(fileHandle, "High");
    FileHelper::WriteString(fileHandle, "Low", writeDelimiter);
}
void CandleStickRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, Date, TimeFormat::MQL); // write in MQL format since we are going to have to read the values in at some point
    FileHelper::WriteDouble(fileHandle, Open, Digits());
    FileHelper::WriteDouble(fileHandle, Close, Digits());
    FileHelper::WriteDouble(fileHandle, High, Digits());
    FileHelper::WriteDouble(fileHandle, Low, Digits(), writeDelimiter);
}

void CandleStickRecord::ReadRow(int fileHandle)
{
    Date = FileReadDatetime(fileHandle);
    Open = StringToDouble(FileReadString(fileHandle));
    Close = StringToDouble(FileReadString(fileHandle));
    High = StringToDouble(FileReadString(fileHandle));
    Low = StringToDouble(FileReadString(fileHandle));
}