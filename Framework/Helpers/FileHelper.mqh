//+------------------------------------------------------------------+
//|                                                   FileHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>

enum TimeFormat
{
    MQL,
    Excel
};

class FileHelper
{
private:
    template <typename T>
    static void SendFailedFileWriteEmail(string type, T value);

public:
    static void WriteDelimiter(int fileHandle);

    static bool InternalWriteString(int fileHandle, string value, bool writeDelimiter);
    static void WriteString(int fileHandle, string value, bool writeDelimiter);
    static void WriteInteger(int fileHandle, int value, bool writeDelimiter);
    static void WriteDouble(int fileHandle, double value, int precision, bool writeDelimiter);
    static void WriteDateTime(int fileHandle, datetime value, TimeFormat timeFormat, bool writeDelimiter);

    static bool ReadBool(int fileHandle);
};

template <typename T>
static void FileHelper::SendFailedFileWriteEmail(string type, T value)
{
    SendMail("Failed To Write " + type + " to File",
             "Value: " + value + "\n" +
                 "Error: " + IntegerToString(GetLastError()));
}

static void FileHelper::WriteDelimiter(int fileHandle)
{
    FileWriteString(fileHandle, ConstantValues::CSVDelimiter);
}

static bool FileHelper::InternalWriteString(int fileHandle, string value, bool writeDelimiter = true)
{
    // Clear Error Queue
    GetLastError();

    uint result = FileWriteString(fileHandle, value);

    if (writeDelimiter)
    {
        WriteDelimiter(fileHandle);
    }

    return result != 0;
}

static void FileHelper::WriteString(int fileHandle, string value, bool writeDelimiter = true)
{
    if (!InternalWriteString(fileHandle, value, writeDelimiter))
    {
        SendFailedFileWriteEmail<string>("String", value);
    }
}

static void FileHelper::WriteInteger(int fileHandle, int value, bool writeDelimiter = true)
{
    if (!InternalWriteString(fileHandle, IntegerToString(value), writeDelimiter))
    {
        SendFailedFileWriteEmail<int>("Int", value);
    }
}

static void FileHelper::WriteDouble(int fileHandle, double value, int precision, bool writeDelimiter = true)
{
    if (!InternalWriteString(fileHandle, DoubleToString(value, precision), writeDelimiter))
    {
        SendFailedFileWriteEmail<double>("Double", value);
    }
}

static void FileHelper::WriteDateTime(int fileHandle, datetime value, TimeFormat timeFormat = TimeFormat::Excel, bool writeDelimiter = true)
{
    string dateAsString = TimeToString(value, TIME_DATE | TIME_MINUTES);

    // replace '.' with '/' so that excel knows its a date and allows for datetime functions within
    if (timeFormat == TimeFormat::Excel)
    {
        StringReplace(dateAsString, ".", "/");
    }

    if (!InternalWriteString(fileHandle, dateAsString, writeDelimiter))
    {
        SendFailedFileWriteEmail<datetime>("DateTime", value);
    }
}

static bool FileHelper::ReadBool(int fileHandle)
{
    string boolAsString = FileReadString(fileHandle);
    if (!StringToLower(boolAsString))
    {
        return false;
    }

    return boolAsString == "true";
}