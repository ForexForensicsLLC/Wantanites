//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\DefaultTradeRecord.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class SingleTimeFrameTradeRecord : public DefaultTradeRecord
{
public:
    string EntryImage;
    string ExitImage;

    SingleTimeFrameTradeRecord();
    ~SingleTimeFrameTradeRecord();

    virtual int TotalColumns() { return 17; }
    virtual int CloseDataStartIndex() { return 9; }

    static void WriteHeaders(int fileHandle);

    virtual void WriteTicketOpenData(int fileHandle);
    virtual void WriteTicketCloseData(int fileHandle);
};

SingleTimeFrameTradeRecord::SingleTimeFrameTradeRecord() {}
SingleTimeFrameTradeRecord::~SingleTimeFrameTradeRecord() {}

void SingleTimeFrameTradeRecord::WriteHeaders(int fileHandle)
{
    DefaultTradeRecord::WriteTicketOpenHeaders(fileHandle);
    FileWriteString(fileHandle, "Entry Image");

    DefaultTradeRecord::WriteTicketCloseHeaders(fileHandle);
    FileWriteString(fileHandle, "Exit Imaage");

    DefaultTradeRecord::WriteAdditionalTicketHeaders(fileHandle);
}

void SingleTimeFrameTradeRecord::WriteTicketOpenData(int fileHandle)
{
    DefaultTradeRecord::WriteTicketOpenData(fileHandle);
    FileWriteString(fileHandle, EntryImage);
}

void SingleTimeFrameTradeRecord::WriteTicketCloseData(int fileHandle)
{
    DefaultTradeRecord::WriteTicketCloseData(fileHandle);
    FileWriteString(fileHandle, EntryImage);
}
