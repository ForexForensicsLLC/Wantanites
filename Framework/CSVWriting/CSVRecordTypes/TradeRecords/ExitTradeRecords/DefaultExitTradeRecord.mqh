//+------------------------------------------------------------------+
//|                                      DefaultExitTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\RecordColumns.mqh>

class DefaultExitTradeRecord : public RecordColumns
{
public:
    DefaultExitTradeRecord();
    ~DefaultExitTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);

    void ReadRow(int fileHandle);
};

DefaultExitTradeRecord::DefaultExitTradeRecord() : RecordColumns() {}
DefaultExitTradeRecord::~DefaultExitTradeRecord() {}

void DefaultExitTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteString(fileHandle, "Exit Time");
    FileHelper::WriteString(fileHandle, "Magic Number");
    FileHelper::WriteString(fileHandle, "Ticket Number");
    FileHelper::WriteString(fileHandle, "Symbol");
    FileHelper::WriteString(fileHandle, "Order Type");
    FileHelper::WriteString(fileHandle, "Account Balance After");
    FileHelper::WriteString(fileHandle, "Entry Price");
    FileHelper::WriteString(fileHandle, "Original Stop Loss");
    FileHelper::WriteString(fileHandle, "Exit Price");
    FileHelper::WriteString(fileHandle, "Stop Loss Exit Slippage");
    FileHelper::WriteString(fileHandle, "Total Move Pips");
    FileHelper::WriteString(fileHandle, "Potential RR");
    FileHelper::WriteString(fileHandle, "RR Secured");
    FileHelper::WriteString(fileHandle, "Current Drawdown");
    FileHelper::WriteString(fileHandle, "Percent Change", writeDelimiter);
}

void DefaultExitTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    FileHelper::WriteDateTime(fileHandle, ExitTime);
    FileHelper::WriteInteger(fileHandle, MagicNumber);
    FileHelper::WriteInteger(fileHandle, TicketNumber);
    FileHelper::WriteString(fileHandle, Symbol);
    FileHelper::WriteString(fileHandle, OrderType);
    FileHelper::WriteDouble(fileHandle, AccountBalanceAfter, 2);
    FileHelper::WriteDouble(fileHandle, EntryPrice, Digits);
    FileHelper::WriteDouble(fileHandle, OriginalStopLoss, Digits);
    FileHelper::WriteDouble(fileHandle, ExitPrice, Digits);
    FileHelper::WriteDouble(fileHandle, StopLossExitSlippage, Digits);
    FileHelper::WriteDouble(fileHandle, TotalMovePips(), Digits);
    FileHelper::WriteDouble(fileHandle, PotentialRR(), 2);
    FileHelper::WriteDouble(fileHandle, RRSecured(), 2);
    FileHelper::WriteString(fileHandle, CurrentDrawdown("F"));               // F is the column where AccountBalanceAfter is located
    FileHelper::WriteString(fileHandle, PercentChange("F"), writeDelimiter); // F is the column where AccountBalanceAfter is located
}

void DefaultExitTradeRecord::ReadRow(int fileHandle)
{
    ExitTime = FileReadDatetime(fileHandle);
    MagicNumber = StrToInteger(FileReadString(fileHandle));
    TicketNumber = StrToInteger(FileReadString(fileHandle));
    Symbol = FileReadString(fileHandle);
    OrderType = FileReadString(fileHandle);
    AccountBalanceAfter = StrToDouble(FileReadString(fileHandle));
    EntryPrice = StrToDouble(FileReadString(fileHandle));
    OriginalStopLoss = StrToDouble(FileReadString(fileHandle));
    ExitPrice = StrToDouble(FileReadString(fileHandle));
    StopLossExitSlippage = StrToDouble(FileReadString(fileHandle));
    mTotalMovePips = StrToDouble(FileReadString(fileHandle));
    mPotentialRR = StrToDouble(FileReadString(fileHandle));
    mRRSecured = StrToDouble(FileReadString(fileHandle));
    FileReadString(fileHandle); // don't need to set anything for Curent Drawdown
    FileReadString(fileHandle); // don't need to set anything for Percent Change
}