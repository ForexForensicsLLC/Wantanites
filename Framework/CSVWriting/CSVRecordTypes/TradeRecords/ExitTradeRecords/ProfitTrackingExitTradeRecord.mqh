//+------------------------------------------------------------------+
//|                                      ForexForensicsExitTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\ExitTradeRecords\ForexForensicsExitTradeRecord.mqh>

class ProfitTrackingExitTradeRecord : public ForexForensicsExitTradeRecord
{
public:
    ProfitTrackingExitTradeRecord();
    ~ProfitTrackingExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

ProfitTrackingExitTradeRecord::ProfitTrackingExitTradeRecord() : ForexForensicsExitTradeRecord() {}
ProfitTrackingExitTradeRecord::~ProfitTrackingExitTradeRecord() {}

void ProfitTrackingExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsExitTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Total Move Pips");
    FileHelper::WriteString(fileHandle, "Potential RR");
    FileHelper::WriteString(fileHandle, "RR Secured", writeDelimiter);
}

void ProfitTrackingExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    ForexForensicsExitTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteDouble(fileHandle, TotalMovePips(), Digits());
    FileHelper::WriteDouble(fileHandle, PotentialRR(), 2);
    FileHelper::WriteDouble(fileHandle, RRSecured(), 2);
}

void ProfitTrackingExitTradeRecord::ReadRow(int fileHandle)
{
    ForexForensicsExitTradeRecord::ReadRow(fileHandle);
    mTotalMovePips = StringToDouble(FileReadString(fileHandle));
    mPotentialRR = StringToDouble(FileReadString(fileHandle));
    mRRSecured = StringToDouble(FileReadString(fileHandle));
}