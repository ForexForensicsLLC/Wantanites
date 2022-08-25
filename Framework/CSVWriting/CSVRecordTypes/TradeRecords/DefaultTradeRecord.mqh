//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\ICSVRecord.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class DefaultTradeRecord : public ICSVRecord
{
public:
    string Symbol;
    int EntryTimeFrame;
    string OrderType;
    double AccountBalanceBefore;
    double AccountBalanceAfter;
    datetime EntryTime;
    double EntryPrice;
    double EntryStopLoss;
    datetime ExitTime;
    double ExitPrice;
    double ExitStopLoss;
    double Lots;
    int LastState;
    int Error;
    string ErrorImage;
    string Notes;

    DefaultTradeRecord();
    ~DefaultTradeRecord();

    double TotalMovePips();
    double PotentialRR();

    virtual void WriteHeaders(int fileHandle);
    virtual void WriteRecord(int fileHandle);
    virtual void Reset();
};

DefaultTradeRecord::DefaultTradeRecord()
{
    Reset();
}

DefaultTradeRecord::~DefaultTradeRecord() {}

double DefaultTradeRecord::TotalMovePips()
{
    double furthestPoint;
    if (OrderType == "Buy")
    {
        int entryIndex = iBarShift(Symbol, EntryTimeFrame, EntryTime, true);
        if (entryIndex == EMPTY)
        {
            return 0.0;
        }

        if (!MQLHelper::GetHighestHighBetween(Symbol, EntryTimeFrame, entryIndex, 0, true, furthestPoint))
        {
            return 0.0;
        }

        return NormalizeDouble(OrderHelper::RangeToPips((furthestPoint - EntryPrice)), 2);
    }
    else if (OrderType == "Sell")
    {
        int entryIndex = iBarShift(Symbol, EntryTimeFrame, EntryTime, true);
        if (entryIndex == EMPTY)
        {
            return 0.0;
        }

        if (!MQLHelper::GetLowestLowBetween(Symbol, EntryTimeFrame, entryIndex, 0, true, furthestPoint))
        {
            return 0.0;
        }

        return NormalizeDouble(OrderHelper::RangeToPips((EntryPrice - furthestPoint)), 2);
    }

    return 0.0;
}

double DefaultTradeRecord::PotentialRR()
{
    double totalMovePips = TotalMovePips();

    if (EntryPrice - EntryStopLoss == 0)
    {
        return 0.0;
    }

    if (OrderType == "Buy")
    {
        return NormalizeDouble(totalMovePips / (EntryPrice - EntryStopLoss), 2);
    }
    else if (OrderType == "Sell")
    {
        return NormalizeDouble(totalMovePips / (EntryStopLoss - EntryPrice), 2);
    }

    return 0.0;
}

void DefaultTradeRecord::WriteHeaders(int fileHandle)
{
    FileWrite(fileHandle,
              "Symbol",
              "Order Type",
              "Account Balance Before",
              "Account Balance After",
              "Lots",
              "Entry Time",
              "Entry Price",
              "Entry Stop Loss",
              "Exit Time",
              "Exit Price",
              "Exit Stop Loss",
              "Total Move Pips",
              "Potential RR",
              "Last State",
              "Error",
              "Error Image",
              "Notes");
}

void DefaultTradeRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle,
              Symbol,
              OrderType,
              AccountBalanceBefore,
              AccountBalanceAfter,
              Lots,
              EntryTime,
              EntryPrice,
              EntryStopLoss,
              ExitTime,
              ExitPrice,
              ExitStopLoss,
              TotalMovePips(),
              PotentialRR(),
              LastState,
              Error,
              ErrorImage,
              Notes);
}

void DefaultTradeRecord::Reset()
{
    Symbol = "";
    EntryTimeFrame = 0;
    OrderType = "";
    AccountBalanceBefore = 0;
    AccountBalanceAfter = 0;
    Lots = 0.0;
    EntryTime = 0;
    EntryPrice = 0.0;
    EntryStopLoss = 0.0;
    ExitTime = 0;
    ExitPrice = 0.0;
    ExitStopLoss = 0.0;
    LastState = 0;
    Error = 0;
    ErrorImage = "";
    Notes = "";
}