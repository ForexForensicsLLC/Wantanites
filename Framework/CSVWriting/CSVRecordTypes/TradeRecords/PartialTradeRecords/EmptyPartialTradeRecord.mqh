//+------------------------------------------------------------------+
//|                                      EmptyPartialTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class EmptyPartialTradeRecord : public RecordColumns
{
private:
public:
    EmptyPartialTradeRecord();
    ~EmptyPartialTradeRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

EmptyPartialTradeRecord::EmptyPartialTradeRecord() {}
EmptyPartialTradeRecord::~EmptyPartialTradeRecord() {}

void EmptyPartialTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false) {}
void EmptyPartialTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false) {}

void EmptyPartialTradeRecord::ReadRow(int fileHandle) {}