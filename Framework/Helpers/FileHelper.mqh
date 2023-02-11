//+------------------------------------------------------------------+
//|                                                   FileHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Constants\ConstantValues.mqh>

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
    static void WriteDateTime(int fileHandle, datetime value, bool writeDelimiter);
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

static void FileHelper::WriteDateTime(int fileHandle, datetime value, bool writeDelimiter = true)
{
    // replace '.' with '/' so that excel knows its a date and allows for datetime functions within
    string dateAsString = TimeToString(value, TIME_DATE | TIME_MINUTES);
    StringReplace(dateAsString, ".", "/");

    if (!InternalWriteString(fileHandle, dateAsString, writeDelimiter))
    {
        SendFailedFileWriteEmail<datetime>("DateTime", value);
    }
}