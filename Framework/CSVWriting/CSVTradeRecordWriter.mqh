//+------------------------------------------------------------------+
//|                                         CSVTradeRecordWriter.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Objects\TicketList.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>

class CSVTradeRecordWriter : public CSVRecordWriter
{
public:
    CSVTradeRecordWriter(string directory, string csvFileName);
    ~CSVTradeRecordWriter();

    void SeekToColumn(int &currentColumn, int columnToSeek);

    template <typename TTradeRecord>
    void WriteTradeRecordOpenData(TTradeRecord &record);
    template <typename TTradeRecord>
    void WriteTradeRecordPartialData(TTradeRecord &record);
    template <typename TTradeRecord>
    void WriteTradeRecordCloseData(TTradeRecord &record);
    template <typename TTradeRecord>
    void WriteTradeRecordCloseDataAfterPartial(TTradeRecord &record);

    template <typename TTradeRecord>
    void SearchSetRRAcquired(TicketList &tickets);
};

CSVTradeRecordWriter::CSVTradeRecordWriter(string directory, string csvFileName) : CSVRecordWriter(directory, csvFileName)
{
}

CSVTradeRecordWriter::~CSVTradeRecordWriter()
{
}

void CSVTradeRecordWriter::SeekToColumn(int &currentColumn, int columnsToSeek)
{
    while (currentColumn < columnsToSeek)
    {
        FileReadString(mFileHandle);
        currentColumn += 1;
    }
}

template <typename TTradeRecord>
void CSVTradeRecordWriter::WriteTradeRecordOpenData(TTradeRecord &record)
{
    // go to the end
    if (!SeekToEnd())
    {
        return;
    }

    // create a new line
    FileWriteString(mFileHandle, "\n");

    // write record
    record.WriteTicketOpenData(mFileHandle);
}

template <typename TTradeRecord>
void CSVTradeRecordWriter::WriteTradeRecordPartialData(TTradeRecord &record)
{
    if (!SeekToStart())
    {
        return;
    }

    bool foundRow = false;
    while (!FileIsEnding(mFileHandle))
    {
        foundRow = FileReadInteger(mFileHandle) == record.TicketNumber;

        // start at 1 since we read in the ticket number
        int column = 1;
        if (foundRow)
        {
            SeekToColumn(column, record.PartialDataStartIndex());
            record.WriteTicketPartialData(mFileHandle);

            return;
        }
        else
        {
            SeekToColumn(column, record.TotalColumns());
        }
    }

    if (!foundRow)
    {
        SendMail("Failed To Find Ticket in CSV", "Ticket Number: " + IntegerToString(record.TicketNumber));
    }
}

template <typename TTradeRecord>
void CSVTradeRecordWriter::WriteTradeRecordCloseData(TTradeRecord &record)
{
    if (!SeekToStart())
    {
        return;
    }

    bool foundRow = false;
    while (!FileIsEnding(mFileHandle))
    {
        foundRow = FileReadInteger(mFileHandle) == record.TicketNumber;

        int column = 1;
        if (foundRow)
        {
            SeekToColumn(column, record.CloseDataStartIndex());
            record.WriteTicketCloseData(mFileHandle);

            return;
        }
        else
        {
            SeekToColumn(column, record.TotalColumns());
        }
    }

    if (!foundRow)
    {
        SendMail("Failed To Find Ticket in CSV", "Ticket Number: " + IntegerToString(record.TicketNumber));
    }
}

template <typename TTradeRecord>
void CSVTradeRecordWriter::WriteTradeRecordCloseDataAfterPartial(TTradeRecord &record)
{
    if (!SeekToStart())
    {
        return;
    }

    bool foundRow = false;
    while (!FileIsEnding(mFileHandle))
    {
        int column = 0;

        // get to the partial ticket number
        SeekToColumn(column, record.PartialDataStartIndex());

        foundRow = FileReadInteger(mFileHandle) == record.PartialedTicketNumber;
        column += 1;

        if (foundRow)
        {
            SeekToColumn(column, record.CloseDataStartIndex());
            record.WriteTicketCloseData(mFileHandle);

            return;
        }
        else
        {
            SeekToColumn(column, record.TotalColumns());
        }
    }

    if (!foundRow)
    {
        SendMail("Failed To Find Ticket in CSV", "Ticket Number: " + IntegerToString(record.TicketNumber));
    }
}

template <typename TTradeRecord>
void CSVTradeRecordWriter::SearchSetRRAcquired(TicketList &tickets)
{
    if (!SeekToStart())
    {
        return;
    }

    TTradeRecord *tempRecord = new TTradeRecord();
    Ticket *tempTicket;

    bool foundRow = false;
    int ticket = EMPTY;
    int ticketsFound = 0;

    while (!FileIsEnding(mFileHandle))
    {
        ticket = FileReadInteger(mFileHandle);
        int column = 1;

        for (int i = 0; i < tickets.Size(); i++)
        {
            if (ticket == tickets[i].Number())
            {
                tempTicket = tickets[i];
                foundRow = true;
                break;
            }
            else
            {
                foundRow = false;
            }
        }

        // Move our index over to the column which holds partial info.
        SeekToColumn(column, tempRecord.PartialDataStartIndex() + 1);

        // FileReadDouble() only works with binary files, have to use FileReadString() instead
        double rrAcquired = StringToDouble(FileReadString(mFileHandle));

        if (foundRow)
        {
            tempTicket.mRRAcquired = rrAcquired;
            ticketsFound += 1;

            // found all the tickets, can return
            if (ticketsFound == tickets.Size())
            {
                return;
            }
        }

        // Continue to the next row
        SeekToColumn(column, tempRecord.TotalColumns());
    }
}
