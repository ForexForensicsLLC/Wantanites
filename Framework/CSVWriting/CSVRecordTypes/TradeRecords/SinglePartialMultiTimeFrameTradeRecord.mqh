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

class SinglePartialMultiTimeFrameTradeRecord : public DefaultTradeRecord
{
public:
    int PartialedTicketNumber;
    double PartialOneRR;

    string HigherTimeFrameEntryImage;
    string LowerTimeFrameEntryImage;

    string HigherTimeFrameExitImage;
    string LowerTimeFrameExitImage;

    SinglePartialMultiTimeFrameTradeRecord();
    ~SinglePartialMultiTimeFrameTradeRecord();

    virtual int TotalColumns() { return 21; }
    virtual int PartialDataStartIndex() { return 10; }
    virtual int CloseDataStartIndex() { return 12; }

    static void WriteHeaders(int fileHandle);

    virtual void WriteTicketOpenData(int fileHandle);
    virtual void WriteTicketPartialData(int fileHandle);
    virtual void WriteTicketCloseData(int fileHandle);
};

SinglePartialMultiTimeFrameTradeRecord::SinglePartialMultiTimeFrameTradeRecord() {}
SinglePartialMultiTimeFrameTradeRecord::~SinglePartialMultiTimeFrameTradeRecord() {}

void SinglePartialMultiTimeFrameTradeRecord::WriteHeaders(int fileHandle)
{
    DefaultTradeRecord::WriteTicketOpenHeaders(fileHandle);
    FileWriteString(fileHandle, "High TF Entry Image");
    FileWriteString(fileHandle, "Lower TF Entry Imaage");

    FileWriteString(fileHandle, "Partial Ticket Number");
    FileWriteString(fileHandle, "Partial One RR");

    DefaultTradeRecord::WriteTicketCloseHeaders(fileHandle);
    FileWriteString(fileHandle, "High TF Exit Image");
    FileWriteString(fileHandle, "Lower TF Exit Imaage");

    DefaultTradeRecord::WriteAdditionalTicketHeaders(fileHandle);
}

void SinglePartialMultiTimeFrameTradeRecord::WriteTicketOpenData(int fileHandle)
{
    DefaultTradeRecord::WriteTicketOpenData(fileHandle);
    FileWriteString(fileHandle, HigherTimeFrameEntryImage);
    FileWriteString(fileHandle, LowerTimeFrameEntryImage);
}

void SinglePartialMultiTimeFrameTradeRecord::WriteTicketPartialData(int fileHandle)
{
    FileWriteInteger(fileHandle, PartialedTicketNumber);
    FileWriteDouble(fileHandle, NormalizeDouble(PartialOneRR, 2));
}

void SinglePartialMultiTimeFrameTradeRecord::WriteTicketCloseData(int fileHandle)
{
    DefaultTradeRecord::WriteTicketCloseData(fileHandle);
    FileWriteString(fileHandle, HigherTimeFrameExitImage);
    FileWriteString(fileHandle, LowerTimeFrameExitImage);
}
