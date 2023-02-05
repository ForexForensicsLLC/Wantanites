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
    double mTotalMovePips;
    double mPotentialRR;
    double mRRAcquired;

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
    double OriginalStopLoss;
    string EntryImage;
    string HigherTimeFrameEntryImage;
    string LowerTimeFrameEntryImage;

    int NewTicketNumber;
    double ExpectedPartialRR;
    double ActualPartialRR;

    double AccountBalanceAfter;
    datetime ExitTime;
    double ExitPrice;
    string ExitImage;
    string HigherTimeFrameExitImage;
    string LowerTimeFrameExitImage;

    double TotalMovePips();
    double PotentialRR();
    double RRSecured();
    string Psychology();
};

RecordColumns::RecordColumns()
{
    mTotalMovePips = -1.0;
    mPotentialRR = -1.0;
    mRRAcquired = -1.0;

    MagicNumber = EMPTY;
    TicketNumber = EMPTY;
    Symbol = "EMPTY";
    EntryTimeFrame = EMPTY;

    OrderType = "EMPTY";
    AccountBalanceBefore = -1.0;
    Lots = -1.0;
    EntryTime = 0;
    EntryPrice = -1.0;
    OriginalStopLoss = -1.0;
    EntryImage = "EMPTY";
    HigherTimeFrameEntryImage = "EMPTY";
    LowerTimeFrameEntryImage = "EMPTY";

    NewTicketNumber = EMPTY;
    ExpectedPartialRR = -1.0;
    ActualPartialRR = -1.0;

    AccountBalanceAfter = -1.0;
    ExitTime = 0;
    ExitPrice = -1.0;
    ExitImage = "EMPTY";
    HigherTimeFrameExitImage = "EMPTY";
    LowerTimeFrameExitImage = "EMPTY";
}

RecordColumns::~RecordColumns()
{
}

double RecordColumns::TotalMovePips()
{
    if (mTotalMovePips == -1.0)
    {
        double furthestPoint;
        if (OrderType == "Buy")
        {
            int entryIndex = iBarShift(Symbol, EntryTimeFrame, EntryTime, true);
            if (entryIndex == EMPTY)
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            if (!MQLHelper::GetHighestHighBetween(Symbol, EntryTimeFrame, entryIndex, 0, true, furthestPoint))
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            mTotalMovePips = NormalizeDouble(OrderHelper::RangeToPips((furthestPoint - EntryPrice)), 2);
        }
        else if (OrderType == "Sell")
        {
            int entryIndex = iBarShift(Symbol, EntryTimeFrame, EntryTime, true);
            if (entryIndex == EMPTY)
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            if (!MQLHelper::GetLowestLowBetween(Symbol, EntryTimeFrame, entryIndex, 0, true, furthestPoint))
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            mTotalMovePips = NormalizeDouble(OrderHelper::RangeToPips((EntryPrice - furthestPoint)), 2);
        }
    }

    return mTotalMovePips;
}

double RecordColumns::PotentialRR()
{
    if (mPotentialRR == -1.0)
    {
        if (EntryPrice - OriginalStopLoss == 0)
        {
            mPotentialRR = 0.0;
            return mPotentialRR;
        }

        double totalMovePips = TotalMovePips();
        if (OrderType == "Buy")
        {
            mPotentialRR = NormalizeDouble(totalMovePips / (OrderHelper::RangeToPips(EntryPrice - OriginalStopLoss)), 2);
        }
        else if (OrderType == "Sell")
        {
            mPotentialRR = NormalizeDouble(totalMovePips / (OrderHelper::RangeToPips(OriginalStopLoss - EntryPrice)), 2);
        }
    }

    return mPotentialRR;
}

double RecordColumns::RRSecured()
{
    if (EntryPrice - OriginalStopLoss == 0)
    {
        // return -2 here so that i know something went wrong. Should never happen naturally
        return -2.0;
    }

    double rrLost = 0.0;
    if (OrderType == "Buy")
    {
        rrLost = (EntryPrice - ExitPrice) / (EntryPrice - OriginalStopLoss);
    }
    else if (OrderType == "Sell")
    {
        rrLost = (ExitPrice - EntryPrice) / (OriginalStopLoss - EntryPrice);
    }

    return (-1 * rrLost);
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
