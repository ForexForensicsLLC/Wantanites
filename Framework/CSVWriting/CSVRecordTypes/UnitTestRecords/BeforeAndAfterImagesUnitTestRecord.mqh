//+------------------------------------------------------------------+
//|                              BeforeAfterImagesUnitTestRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

class BeforeAndAfterImagesUnitTestRecord : public DefaultUnitTestRecord
{
public:
    string BeforeImage;
    string AfterImage;

    BeforeAndAfterImagesUnitTestRecord();
    ~BeforeAndAfterImagesUnitTestRecord();

    virtual void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
    virtual void Reset();
};
BeforeAndAfterImagesUnitTestRecord::BeforeAndAfterImagesUnitTestRecord() : DefaultUnitTestRecord()
{
    Reset();
}

BeforeAndAfterImagesUnitTestRecord::~BeforeAndAfterImagesUnitTestRecord()
{
}

void BeforeAndAfterImagesUnitTestRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle, "Name", "Description", "Assert Time", "Result", "Message", "Additional Information", "Assert Number",
              "Max Asserts", "Before Image", "After Image", "Notes");
}

void BeforeAndAfterImagesUnitTestRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle, Name, Description, AssertTime, Result, Message, AdditionalInformation, Asserts, MaxAsserts, BeforeImage, AfterImage, Notes);
}

void BeforeAndAfterImagesUnitTestRecord::Reset()
{
    BeforeImage = "";
    AfterImage = "";

    DefaultUnitTestRecord::Reset();
}
