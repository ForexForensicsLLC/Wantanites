//+------------------------------------------------------------------+
//|                                    MultiTimeFrameErrorRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\DefaultErrorRecord.mqh>

class MultiTimeFrameErrorRecord : public DefaultErrorRecord
{
public:
    string HigherTimeFrameErrorImage;
    string LowerTimeFrameErrorImage;

    MultiTimeFrameErrorRecord();
    ~MultiTimeFrameErrorRecord();

    void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
};

MultiTimeFrameErrorRecord::MultiTimeFrameErrorRecord() : DefaultErrorRecord()
{
    HigherTimeFrameErrorImage = "EMPTY";
    LowerTimeFrameErrorImage = "EMPTY";
}

MultiTimeFrameErrorRecord::~MultiTimeFrameErrorRecord()
{
}

void MultiTimeFrameErrorRecord::WriteHeaders(int fileHandle)
{
    DefaultErrorRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Higher Time Frame Error Iamge");
    FileHelper::WriteString(fileHandle, "Lower Time Frame Error Image");
}

void MultiTimeFrameErrorRecord::WriteRecord(int fileHandle)
{
    DefaultErrorRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, HigherTimeFrameErrorImage);
    FileHelper::WriteString(fileHandle, LowerTimeFrameErrorImage);
}
