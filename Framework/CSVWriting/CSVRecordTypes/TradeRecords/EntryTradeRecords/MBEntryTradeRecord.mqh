//+------------------------------------------------------------------+
//|                                            MBEntryTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\SingleTimeFrameEntryTradeRecord.mqh>

class MBEntryTradeRecord : public SingleTimeFrameEntryTradeRecord
{
public:
    double MBHeight;
    int MBWidth;
    double PendingMBHeight;
    int PendingMBWidth;
    double PercentOfPendingMBInPrevious;
    int MBCount;
    int ZoneNumber;
    double RRToMBValidation;

    MBEntryTradeRecord();
    ~MBEntryTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);
};

MBEntryTradeRecord::MBEntryTradeRecord() : SingleTimeFrameEntryTradeRecord()
{
    MBWidth = -1.0;
    MBHeight = -1.0;
    PendingMBHeight = 1.0;
    PendingMBWidth = EMPTY;
    PercentOfPendingMBInPrevious = -1.0;
}

MBEntryTradeRecord::~MBEntryTradeRecord()
{
}

void MBEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    SingleTimeFrameEntryTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "RR To MB Validation");
    FileHelper::WriteString(fileHandle, "MB Height");
    FileHelper::WriteString(fileHandle, "MB Width");
    FileHelper::WriteString(fileHandle, "Pending MB Height");
    FileHelper::WriteString(fileHandle, "Pending MB Width");
    FileHelper::WriteString(fileHandle, "Percent Of Pending MB in Previous");
    FileHelper::WriteString(fileHandle, "MB Count");
    // FileHelper::WriteString(fileHandle, "Zone Number");
}

void MBEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    SingleTimeFrameEntryTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteDouble(fileHandle, RRToMBValidation, 2);
    FileHelper::WriteDouble(fileHandle, MBHeight, Digits);
    FileHelper::WriteInteger(fileHandle, MBWidth);
    FileHelper::WriteDouble(fileHandle, PendingMBHeight, Digits);
    FileHelper::WriteInteger(fileHandle, PendingMBWidth);
    FileHelper::WriteDouble(fileHandle, PercentOfPendingMBInPrevious, 2);
    FileHelper::WriteInteger(fileHandle, MBCount);
    // FileHelper::WriteInteger(fileHandle, ZoneNumber);
}
