//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\ICSVRecord.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class DefaultTradeRecord : ICSVRecord
{
public:
    string Symbol;
    int TimeFrame;
    string OrderType;
    double AccountBalanceBefore;
    double AccountBalanceAfter;
    datetime EntryTime;
    string EntryImage;
    datetime ExitTime;
    string ExitImage;
    double EntryPrice;
    double EntryStopLoss;
    double Lots;
    double ExitPrice;
    double ExitStopLoss;
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
        int entryIndex = iBarShift(Symbol, TimeFrame, EntryTime, true);
        if (entryIndex == EMPTY)
        {
            return 0.0;
        }

        if (!MQLHelper::GetHighestHighBetween(Symbol, TimeFrame, entryIndex, 0, true, furthestPoint))
        {
            return 0.0;
        }

        return NormalizeDouble(OrderHelper::RangeToPips((furthestPoint - EntryPrice)), 2);
    }
    else if (OrderType == "Sell")
    {
        int entryIndex = iBarShift(Symbol, TimeFrame, EntryTime, true);
        if (entryIndex == EMPTY)
        {
            return 0.0;
        }

        if (!MQLHelper::GetLowestLowBetween(Symbol, TimeFrame, entryIndex, 0, true, furthestPoint))
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
    FileWrite(fileHandle, "Symbol", "Time Frame", "Order Type", "Account Balance Before", "Account Balance After", "Entry Time", "Entry Image", "Exit Time", "Exit Image",
              "Entry Price", "Entry Stop Loss", "Lots", "Exit Price", "Exit Stop Loss", "Total Move Pips", "Potential RR", "Last State", "Error", "Error Image", "Notes");
}

void DefaultTradeRecord::WriteRecord(int fileHandle)
{
    FileWrite(fileHandle, Symbol, TimeFrame, OrderType, AccountBalanceBefore, AccountBalanceAfter, EntryTime, EntryImage, ExitTime, ExitImage, EntryPrice,
              EntryStopLoss, Lots, ExitPrice, ExitStopLoss, TotalMovePips(), PotentialRR(), LastState, Error, ErrorImage, Notes);
}

void DefaultTradeRecord::Reset()
{
    Symbol = "";
    TimeFrame = 0;
    OrderType = "";
    AccountBalanceBefore = 0;
    AccountBalanceAfter = 0;
    EntryTime = 0;
    EntryImage = "";
    ExitTime = 0;
    ExitImage = "";
    EntryPrice = 0.0;
    EntryStopLoss = 0.0;
    Lots = 0.0;
    ExitPrice = 0.0;
    ExitStopLoss = 0.0;
    LastState = 0;
    Error = 0;
    ErrorImage = "";
    Notes = "";
}