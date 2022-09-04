//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class DefaultTradeRecord
{
public:
    int TicketNumber;
    int EntryTimeFrame; // Needed for TotalMovePips() and PotentialRR();
    string Symbol;
    string OrderType;
    double AccountBalanceBefore;
    double Lots;
    datetime EntryTime;
    double EntryPrice;
    double EntryStopLoss;

    double AccountBalanceAfter;
    datetime ExitTime;
    double ExitPrice;
    double ExitStopLoss;

    double TotalMovePips();
    double PotentialRR();
    string Psychology();

    DefaultTradeRecord();
    ~DefaultTradeRecord();

    virtual int TotalColumns() { return 15; }
    virtual int PartialDataStartIndex() { return 0; }
    virtual int CloseDataStartIndex() { return 8; }

    static void WriteHeaders(int fileHandle);
    static void WriteTicketOpenHeaders(int fileHandle);
    static void WriteTicketCloseHeaders(int fileHandle);
    static void WriteAdditionalTicketHeaders(int fileHandle);

    void WriteEntireRecord(int fileHandle);
    virtual void WriteTicketOpenData(int fileHandle);
    virtual void WriteTicketPartialData(int fileHandle);
    virtual void WriteTicketCloseData(int fileHandle);
    virtual void WriteAdditionalTicketData(int fileHandle);
};

DefaultTradeRecord::DefaultTradeRecord() {}
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
    if (EntryPrice - EntryStopLoss == 0)
    {
        return 0.0;
    }

    double totalMovePips = TotalMovePips();
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

string DefaultTradeRecord::Psychology()
{
    MathSrand(1);

    if (AccountBalanceAfter > AccountBalanceBefore)
    {
        string winStatements[3] = {"Ayyyyy", "Looks like I got lucky today", "Don't get too confident. You never know when a losing stread may start"};
        return winStatements[(MathRand() % ArraySize(winStatements))];
    }
    else if (AccountBalanceAfter == AccountBalanceBefore)
    {
        string breakEvenStatements[3] = {"Good Practice", "Better than losing", "Staying alive baby"};
        return breakEvenStatements[(MathRand() % ArraySize(breakEvenStatements))];
    }
    else
    {
        string loseStatments[3] = {"Perfect", "Losing is just a part of trading", "Just Unlucky *shrug*"};
        return loseStatments[(MathRand() % ArraySize(loseStatments))];
    }
}

static void DefaultTradeRecord::WriteHeaders(int fileHandle)
{
    WriteTicketOpenHeaders(fileHandle);
    WriteTicketCloseHeaders(fileHandle);
    WriteAdditionalTicketHeaders(fileHandle);
}

static void DefaultTradeRecord::WriteTicketOpenHeaders(int fileHandle)
{
    FileWriteString(fileHandle, "Ticket Number");
    FileWriteString(fileHandle, "Symbol");
    FileWriteString(fileHandle, "Order Type");
    FileWriteString(fileHandle, "Account Balance Before");
    FileWriteString(fileHandle, "Lots");
    FileWriteString(fileHandle, "Entry Time");
    FileWriteString(fileHandle, "Entry Price");
    FileWriteString(fileHandle, "Entry Stop Loss");
}

static void DefaultTradeRecord::WriteTicketCloseHeaders(int fileHandle)
{
    FileWriteString(fileHandle, "Account Balance After");
    FileWriteString(fileHandle, "Exit Time");
    FileWriteString(fileHandle, "Exit Price");
    FileWriteString(fileHandle, "Exit Stop Loss");
}

static void DefaultTradeRecord::WriteAdditionalTicketHeaders(int fileHandle)
{
    FileWriteString(fileHandle, "Total Move Pips");
    FileWriteString(fileHandle, "Potential RR");
    FileWriteString(fileHandle, "Psychology");
}

void DefaultTradeRecord::WriteEntireRecord(int fileHandle)
{
    WriteTicketOpenData(fileHandle);
    WriteTicketPartialData(fileHandle);
    WriteTicketCloseData(fileHandle);
    WriteAdditionalTicketData(fileHandle);
}

void DefaultTradeRecord::WriteTicketOpenData(int fileHandle)
{
    FileWriteInteger(fileHandle, TicketNumber);
    FileWriteString(fileHandle, Symbol);
    FileWriteString(fileHandle, OrderType);
    FileWriteDouble(fileHandle, NormalizeDouble(AccountBalanceBefore, 2));
    FileWriteDouble(fileHandle, NormalizeDouble(Lots, 2));
    FileWriteString(fileHandle, TimeToString(EntryTime, TIME_DATE | TIME_MINUTES));
    FileWriteDouble(fileHandle, NormalizeDouble(EntryPrice, Digits));
    FileWriteDouble(fileHandle, NormalizeDouble(EntryStopLoss, Digits));
}

void DefaultTradeRecord::WriteTicketPartialData(int fileHandle)
{
}

void DefaultTradeRecord::WriteTicketCloseData(int fileHandle)
{
    FileWriteDouble(fileHandle, NormalizeDouble(AccountBalanceAfter, 2));
    FileWriteString(fileHandle, TimeToString(ExitTime, TIME_DATE | TIME_MINUTES));
    FileWriteDouble(fileHandle, NormalizeDouble(ExitPrice, Digits));
    FileWriteDouble(fileHandle, NormalizeDouble(ExitStopLoss, Digits));
}

void DefaultTradeRecord::WriteAdditionalTicketData(int fileHandle)
{
    FileWriteDouble(fileHandle, NormalizeDouble(TotalMovePips(), Digits));
    FileWriteDouble(fileHandle, NormalizeDouble(PotentialRR(), 2));
    FileWriteString(fileHandle, Psychology());
}