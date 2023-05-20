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
    bool mUsingCommon;
    bool mCreateIfFileDoesNotExist;
    bool mStopTryingToOpenFile;

    bool mFileIsOpen;
    int mFileHandle;

    int mRowCount;

    int mFileOperation;

    void CheckWriteHeaders();
    void Init();
    void CountRows();

public:
    CSVRecordWriter(string directory, string csvFileName, bool read, bool write, bool createIfFileDoesNotExist, bool useCommon);
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
CSVRecordWriter::CSVRecordWriter(string directory, string csvFileName, bool read = true, bool write = true, bool createIfFileDoesNotExist = true, bool useCommon = false)
{
    mDirectory = directory;
    mCSVFileName = csvFileName;
    mCreateIfFileDoesNotExist = createIfFileDoesNotExist;
    mStopTryingToOpenFile = false;

    if (read && write)
    {
        mFileOperation = FILE_READ | FILE_WRITE;
    }
    else if (read)
    {
        mFileOperation = FILE_READ;
    }
    else if (write)
    {
        mFileOperation = FILE_WRITE;
    }

    if (useCommon)
    {
        mUsingCommon = true;
        mFileOperation = mFileOperation | FILE_COMMON;
    }

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

    CheckWriteHeaders();
}

template <typename TRecord>
bool CSVRecordWriter::Open()
{
    if (mStopTryingToOpenFile)
    {
        return false;
    }

    if (!mCreateIfFileDoesNotExist && !FileIsExist(mDirectory + mCSVFileName, mUsingCommon ? FILE_COMMON : 0))
    {
        Print("File: ", mDirectory + mCSVFileName, " does not exist");
        mStopTryingToOpenFile = true;

        return false;
    }

    mFileHandle = FileOpen(mDirectory + mCSVFileName, FILE_CSV | mFileOperation, ConstantValues::CSVDelimiter);
    if (mFileHandle == INVALID_HANDLE)
    {
        Print("Failed to open file: ", mDirectory + mCSVFileName, ". Error: ", GetLastError());
        mStopTryingToOpenFile = true;

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
void CSVRecordWriter::CheckWriteHeaders()
{
    SeekToStart();

    if (FileTell(mFileHandle) == 0)
    {
        TRecord *record = new TRecord();
        record.WriteHeaders(mFileHandle);
        mRowCount += 1;

        delete record;
    }
    else
    {
        Print("Didn't write headers. FileTell Value: ", FileTell(mFileHandle));
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

    FileWriteString(mFileHandle, "\n");

    record.RowNumber = mRowCount;
    record.WriteRecord(mFileHandle);

    // incremenet after since we start at 1
    mRowCount += 1;
}
