//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

class EconomicEventRecord
{
public:
    string Id;
    datetime Date;
    string Title;
    string Symbol;
    int Impact;
    string Forecast;
    string Previous;

    EconomicEventRecord();
    ~EconomicEventRecord();

    void WriteHeaders(int fileHandle, bool writeDelimiter);
    void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

EconomicEventRecord::EconomicEventRecord() : RecordColumns() {}
EconomicEventRecord::~EconomicEventRecord() {}

void EconomicEventRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Id");
    FileHelper::WriteString(fileHandle, "Date");
    FileHelper::WriteString(fileHandle, "Title");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Impact");
    FileHelper::WriteString(fileHandle, "Forecast");
    FileHelper::WriteString(fileHandle, "Previous");
}
void EconomicEventRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, Id);
    FileHelper::WriteDateTime(fileHandle, Date);
    FileHelper::WriteString(fileHandle, Title);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteInteger(fileHandle, Impact);
    FileHelper::WriteString(fileHandle, Forecast);
    FileHelper::WriteString(fileHandle, Previous);
}

void EconomicEventRecord::ReadRow(int fileHandle)
{
    Id = FileReadString(fileHandle);
    Date = FileReadDatetime(fileHandle);
    Title = FileReadString(fileHandle);
    Symbol = FileReadString(fileHandle);
    Impact = StrToInteger(FileReadString(fileHandle));
    Forecast = FileReadString(fileHandle);
    Previous = FileReadString(fileHandle);
}