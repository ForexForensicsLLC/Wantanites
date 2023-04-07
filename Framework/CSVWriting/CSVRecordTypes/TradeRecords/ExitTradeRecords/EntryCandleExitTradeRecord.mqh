//+------------------------------------------------------------------+
//|                                          STFCloseTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\ExitTradeRecords\DefaultExitTradeRecord.mqh>

class EntryCandleExitTradeRecord : public DefaultExitTradeRecord
{
public:
    double CandleOpen;
    double CandleClose;
    double CandleHigh;
    double CandleLow;

    EntryCandleExitTradeRecord();
    ~EntryCandleExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

EntryCandleExitTradeRecord::EntryCandleExitTradeRecord() : DefaultExitTradeRecord() {}
EntryCandleExitTradeRecord::~EntryCandleExitTradeRecord() {}

void EntryCandleExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Candle Open");
    FileHelper::WriteString(fileHandle, "Candle Close");
    FileHelper::WriteString(fileHandle, "Candle High");
    FileHelper::WriteString(fileHandle, "Candle Low", writeDelimiter);
}

void EntryCandleExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    DefaultExitTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteDouble(fileHandle, CandleOpen, Digits());
    FileHelper::WriteDouble(fileHandle, CandleClose, Digits());
    FileHelper::WriteDouble(fileHandle, CandleHigh, Digits());
    FileHelper::WriteDouble(fileHandle, CandleLow, Digits(), writeDelimiter);
}

void EntryCandleExitTradeRecord::ReadRow(int fileHandle)
{
    DefaultExitTradeRecord::ReadRow(fileHandle);
    CandleOpen = StrToDouble(FileReadString(fileHandle));
    CandleClose = StrToDouble(FileReadString(fileHandle));
    CandleHigh = StrToDouble(FileReadString(fileHandle));
    CandleLow = StrToDouble(FileReadString(fileHandle));
}