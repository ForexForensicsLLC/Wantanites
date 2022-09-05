//+------------------------------------------------------------------+
//|                                                 RecordFields.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\FileHelper.mqh>

class RecordColumns
{
public:
    RecordColumns();
    ~RecordColumns();

    int MagicNumber;
    int TicketNumber;
    string Symbol;
    int EntryTimeFrame; // Needed for TotalMovePips() and PotentialRR()

    string OrderType;
    double AccountBalanceBefore;
    double Lots;
    datetime EntryTime;
    double EntryPrice;
    double EntryStopLoss;
    string EntryImage;
    string HigherTimeFrameEntryImage;
    string LowerTimeFrameEntryImage;

    int NewTicketNumber;
    double ExpectedPartialRR;
    double ActualPartialRR;

    double AccountBalanceAfter;
    datetime ExitTime;
    double ExitPrice;
    double ExitStopLoss;
    string ExitImage;
    string HigherTimeFrameExitImage;
    string LowerTimeFrameExitImage;

    double TotalMovePips();
    double PotentialRR();
    string Psychology();
};

RecordColumns::RecordColumns()
{
    MagicNumber = EMPTY;
    TicketNumber = EMPTY;
    Symbol = "EMPTY";
    EntryTimeFrame = -1;

    OrderType = "EMPTY";
    AccountBalanceBefore = -1.0;
    Lots = -1.0;
    EntryTime = 0;
    EntryPrice = -1.0;
    EntryStopLoss = -1.0;
    EntryImage = "EMPTY";
    HigherTimeFrameEntryImage = "EMPTY";
    LowerTimeFrameEntryImage = "EMPTY";

    NewTicketNumber = EMPTY;
    ExpectedPartialRR = -1.0;
    ActualPartialRR = -1.0;

    AccountBalanceAfter = -1.0;
    ExitTime = 0;
    ExitPrice = -1.0;
    ExitStopLoss = -1.0;
    ExitImage = "EMPTY";
    HigherTimeFrameExitImage = "EMPTY";
    LowerTimeFrameExitImage = "EMPTY";
}

RecordColumns::~RecordColumns()
{
}

double RecordColumns::TotalMovePips()
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

double RecordColumns::PotentialRR()
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

string RecordColumns::Psychology()
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
