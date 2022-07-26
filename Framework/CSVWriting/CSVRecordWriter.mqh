//+------------------------------------------------------------------+
//|                                                          CSV.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

template <typename TRecord>
class CSVRecordWriter
{
protected:
    string mDirectory;
    string mCSVFileName;

    bool mFileIsOpen;
    int mFileHandle;

    void SeekToEnd();

public:
    TRecord PendingRecord;

    CSVRecordWriter();
    ~CSVRecordWriter();

    string Directory() { return mDirectory; }
    string CSVFileName() { return mCSVFileName; }

    void Open();
    void Write();
};

template <typename TRecord>
void CSVRecordWriter::SeekToEnd()
{
    if (!FileSeek(mFileHandle, 0, SEEK_END))
    {
        FileClose(mFileHandle);
        mFileIsOpen = false;
    }
}

template <typename TRecord>
CSVRecordWriter::CSVRecordWriter()
{
    mFileIsOpen = false;
    mFileHandle = INVALID_HANDLE;
}

template <typename TRecord>
CSVRecordWriter::~CSVRecordWriter()
{
    FileClose(mFileHandle);
}

template <typename TRecord>
void CSVRecordWriter::Open()
{
    mFileHandle = FileOpen(mDirectory + mCSVFileName, FILE_CSV | FILE_READ | FILE_WRITE, ",");
    if (mFileHandle == INVALID_HANDLE)
    {
        return;
    }

    SeekToEnd();
    mFileIsOpen = true;
}

template <typename TRecord>
void CSVRecordWriter::Write()
{
    if (!mFileIsOpen)
    {
        Open();
    }

    if (mFileHandle == INVALID_HANDLE)
    {
        return;
    }

    PendingRecord.Write(mFileHandle);
    PendingRecord.Reset();
}