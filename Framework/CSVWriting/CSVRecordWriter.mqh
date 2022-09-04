//+------------------------------------------------------------------+
//|                                                          CSV.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class CSVRecordWriter
{
protected:
    string mDirectory;
    string mCSVFileName;

    bool mFileIsOpen;
    int mFileHandle;

    bool SeekToStart();
    bool SeekToEnd();

    template <typename TRecord>
    void CheckWriteHeaders();

public:
    CSVRecordWriter(string directory, string csvFileName);
    ~CSVRecordWriter();

    string Directory() { return mDirectory; }
    string CSVFileName() { return mCSVFileName; }

    template <typename TRecord>
    void Open();

    template <typename TRecord>
    void WriteEntireRecord(TRecord &record);
};

CSVRecordWriter::CSVRecordWriter(string directory, string csvFileName)
{
    mDirectory = directory;
    mCSVFileName = csvFileName;

    mFileIsOpen = false;
    mFileHandle = INVALID_HANDLE;
}

CSVRecordWriter::~CSVRecordWriter()
{
    FileClose(mFileHandle);
}

bool CSVRecordWriter::SeekToStart()
{
    if (mFileHandle == INVALID_HANDLE)
    {
        return false;
    }

    if (!FileSeek(mFileHandle, 0, SEEK_SET))
    {
        FileClose(mFileHandle);
        mFileIsOpen = false;

        return false;
    }

    return true;
}

bool CSVRecordWriter::SeekToEnd()
{
    if (mFileHandle == INVALID_HANDLE)
    {
        return false;
    }

    if (!FileSeek(mFileHandle, 0, SEEK_END))
    {
        FileClose(mFileHandle);
        mFileIsOpen = false;

        return false;
    }

    return true;
}

template <typename TRecord>
void CSVRecordWriter::CheckWriteHeaders()
{
    if (FileTell(mFileHandle) == 0)
    {
        TRecord::WriteHeaders(mFileHandle);
    }
}

template <typename TRecord>
void CSVRecordWriter::Open()
{
    mFileHandle = FileOpen(mDirectory + mCSVFileName, FILE_CSV | FILE_READ | FILE_WRITE, ",");
    if (mFileHandle == INVALID_HANDLE)
    {
        return;
    }

    if (!SeekToEnd())
    {
        return;
    }

    CheckWriteHeaders<TRecord>();
    mFileIsOpen = true;
}

template <typename TRecord>
void CSVRecordWriter::WriteEntireRecord(TRecord &record)
{
    if (!mFileIsOpen)
    {
        Open<TRecord>();
    }

    if (mFileHandle == INVALID_HANDLE)
    {
        return;
    }

    record.WriteEntireRecord(mFileHandle);
}
