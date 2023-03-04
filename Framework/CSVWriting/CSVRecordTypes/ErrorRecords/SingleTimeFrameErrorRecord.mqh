//+------------------------------------------------------------------+
//|                                   SingleTimeFrameErrorRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\DefaultErrorRecord.mqh>

class SingleTimeFrameErrorRecord : public DefaultErrorRecord
{
public:
    string ErrorImage;

    SingleTimeFrameErrorRecord();
    ~SingleTimeFrameErrorRecord();

    void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);

    void ReadRow(int fileHandle);
};

SingleTimeFrameErrorRecord::SingleTimeFrameErrorRecord() : DefaultErrorRecord()
{
    ErrorImage = "EMPTY";
}

SingleTimeFrameErrorRecord::~SingleTimeFrameErrorRecord()
{
}

void SingleTimeFrameErrorRecord::WriteHeaders(int fileHandle)
{
    DefaultErrorRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "Error Image");
}

void SingleTimeFrameErrorRecord::WriteRecord(int fileHandle)
{
    DefaultErrorRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteString(fileHandle, ErrorImage);
}

void SingleTimeFrameErrorRecord::ReadRow(int fileHandle)
{
    DefaultErrorRecord::ReadRow(fileHandle);
    ErrorImage = FileReadString(fileHandle);
}
