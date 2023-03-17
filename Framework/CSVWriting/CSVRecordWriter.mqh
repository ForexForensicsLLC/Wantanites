//+------------------------------------------------------------------+
//|                                                          CSV.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>

template <typename TRecord>
class CSVRecordWriter
{
protected:
    string mDirectory;
    string mCSVFileName;
    bool mCreateIfFileDoesNotExist;
    bool mStopTryingToOpenFile;

    bool mFileIsOpen;
    int mFileHandle;

    int mRowCount;

    void CheckWriteHeaders(TRecord &record);
    void Init();
    void CountRows();

public:
    CSVRecordWriter(string directory, string csvFileName, bool createIfFileDoesNotExist);
    ~CSVRecordWriter();

    string Directory() { return mDirectory; }
    string CSVFileName() { return mCSVFileName; }
    int FileHandle() { return mFileHandle; }

    bool SeekToStart();
    bool SeekToEnd();

    bool Open();
    void WriteRecord(TRecord &record);
};

template <typename TRecord>
CSVRecordWriter::CSVRecordWriter(string directory, string csvFileName, bool createIfFileDoesNotExist = true)
{
    mDirectory = directory;
    mCSVFileName = csvFileName;
    mCreateIfFileDoesNotExist = createIfFileDoesNotExist;
    mStopTryingToOpenFile = false;

    mFileIsOpen = false;
    mFileHandle = INVALID_HANDLE;

    Init();
}

template <typename TRecord>
CSVRecordWriter::~CSVRecordWriter()
{
    FileClose(mFileHandle);
}

template <typename TRecord>
void CSVRecordWriter::Init()
{
    if (!Open())
    {
        return;
    }

    mRowCount = 1;
    CountRows();
}

template <typename TRecord>
bool CSVRecordWriter::Open()
{
    if (mStopTryingToOpenFile)
    {
        return;
    }

    if (!mCreateIfFileDoesNotExist && !FileIsExist(mDirectory + mCSVFileName))
    {
        Print("File: ", mDirectory + mCSVFileName, " does not exist");
        mStopTryingToOpen = true;

        return;
    }

    mFileHandle = FileOpen(mDirectory + mCSVFileName, FILE_CSV | FILE_READ | FILE_WRITE, ConstantValues::CSVDelimiter);
    if (mFileHandle == INVALID_HANDLE)
    {
        Print("Failed to open file: ", mDirectory + mCSVFileName, ". Error: ", GetLastError());
        return false;
    }

    mFileIsOpen = true;
    return true;
}

template <typename TRecord>
bool CSVRecordWriter::SeekToStart()
{
    if (!mFileIsOpen)
    {
        Init();
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
        Init();
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
void CSVRecordWriter::CountRows()
{
    TRecord *record = new TRecord();
    while (!FileIsEnding(mFileHandle))
    {
        record.ReadRow(mFileHandle);
        mRowCount += 1;
    }

    delete record;
}

template <typename TRecord>
void CSVRecordWriter::CheckWriteHeaders(TRecord &record)
{
    if (FileTell(mFileHandle) == 0)
    {
        record.WriteHeaders(mFileHandle);
        mRowCount += 1;
    }
}

template <typename TRecord>
void CSVRecordWriter::WriteRecord(TRecord &record)
{
    if (!mFileIsOpen)
    {
        Init();
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

    record.RowNumber = mRowCount;
    record.WriteRecord(mFileHandle);

    // incremenet after since we start at 1
    mRowCount += 1;
}
