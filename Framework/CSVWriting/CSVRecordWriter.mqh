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

    void CheckWriteHeaders(TRecord &record);

public:
    CSVRecordWriter(string directory, string csvFileName);
    ~CSVRecordWriter();

    string Directory() { return mDirectory; }
    string CSVFileName() { return mCSVFileName; }
    int FileHandle() { return mFileHandle; }

    bool SeekToStart();
    bool SeekToEnd();

    void Open();
    void WriteRecord(TRecord &record);
};

template <typename TRecord>
CSVRecordWriter::CSVRecordWriter(string directory, string csvFileName)
{
    mDirectory = directory;
    mCSVFileName = csvFileName;

    mFileIsOpen = false;
    mFileHandle = INVALID_HANDLE;

    Open();
}

template <typename TRecord>
CSVRecordWriter::~CSVRecordWriter()
{
    FileClose(mFileHandle);
}

template <typename TRecord>
bool CSVRecordWriter::SeekToStart()
{
    if (!mFileIsOpen)
    {
        Open();
    }

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

template <typename TRecord>
bool CSVRecordWriter::SeekToEnd()
{
    if (!mFileIsOpen)
    {
        Open();
    }

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
void CSVRecordWriter::CheckWriteHeaders(TRecord &record)
{
    if (FileTell(mFileHandle) == 0)
    {
        record.WriteHeaders(mFileHandle);
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

    mFileIsOpen = true;
    if (!SeekToEnd())
    {
        return;
    }
}

template <typename TRecord>
void CSVRecordWriter::WriteRecord(TRecord &record)
{
    if (!mFileIsOpen)
    {
        Open();
    }

    if (mFileHandle == INVALID_HANDLE)
    {
        return;
    }

    if (!SeekToEnd())
    {
        return;
    }

    CheckWriteHeaders(record);
    FileWriteString(mFileHandle, "\n");

    record.WriteRecord(mFileHandle);
}
