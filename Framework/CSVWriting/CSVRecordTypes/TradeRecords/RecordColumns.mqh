//+------------------------------------------------------------------+
//|                                                 RecordFields.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Utilities\PipConverter.mqh>
#include <Wantanites\Framework\Helpers\FileHelper.mqh>
#include <Wantanites\Framework\Constants\ConstantValues.mqh>

class RecordColumns
{
public:
    double mTotalMovePips;
    double mPotentialRR;
    double mRRSecured;

public:
    RecordColumns();
    ~RecordColumns();

    int RowNumber;

    int MagicNumber;
    ulong TicketNumber;
    string Symbol;
    ENUM_TIMEFRAMES EntryTimeFrame; // Needed for TotalMovePips() and PotentialRR()

    string OrderDirection;
    double AccountBalanceBefore;
    double Lots;
    datetime EntryTime;
    double EntryPrice;
    double EntrySlippage;
    double OriginalStopLoss;

    bool DuringNews;
    int NewsImpact;
    int DayOfWeek;
    string Outcome;

    string EntryImage;
    string HigherTimeFrameEntryImage;
    string LowerTimeFrameEntryImage;

    int NewTicketNumber;
    double ExpectedPartialRR;
    double ActualPartialRR;

    double AccountBalanceAfter;
    datetime ExitTime;
    double ExitPrice;
    double StopLossExitSlippage;
    string ExitImage;
    string HigherTimeFrameExitImage;
    string LowerTimeFrameExitImage;

    double FurthestEquityDrawdownPercent;

    double TotalMovePips();
    double PotentialRR();
    double RRSecured();
    string CurrentDrawdown(string columnIndex);
    string PercentChange(string columnIndex);
};

RecordColumns::RecordColumns()
{
    mTotalMovePips = ConstantValues::EmptyDouble;
    mPotentialRR = ConstantValues::EmptyDouble;
    mRRSecured = -99;

    RowNumber = ConstantValues::UnsetString;

    MagicNumber = ConstantValues::EmptyInt;
    TicketNumber = ConstantValues::EmptyInt;
    Symbol = ConstantValues::UnsetString;
    EntryTimeFrame = Period();

    OrderDirection = ConstantValues::UnsetString;
    AccountBalanceBefore = ConstantValues::EmptyDouble;
    Lots = ConstantValues::EmptyDouble;
    EntryTime = 0;
    EntryPrice = ConstantValues::EmptyDouble;
    EntrySlippage = ConstantValues::EmptyDouble;
    OriginalStopLoss = ConstantValues::EmptyDouble;

    DuringNews = false;
    NewsImpact = ConstantValues::EmptyInt;
    DayOfWeek = ConstantValues::EmptyInt;
    Outcome = ConstantValues::UnsetString;

    EntryImage = ConstantValues::UnsetString;
    HigherTimeFrameEntryImage = ConstantValues::UnsetString;
    LowerTimeFrameEntryImage = ConstantValues::UnsetString;

    NewTicketNumber = ConstantValues::EmptyInt;
    ExpectedPartialRR = ConstantValues::EmptyDouble;
    ActualPartialRR = ConstantValues::EmptyDouble;

    AccountBalanceAfter = ConstantValues::EmptyDouble;
    ExitTime = 0;
    ExitPrice = ConstantValues::EmptyDouble;
    StopLossExitSlippage = ConstantValues::EmptyDouble;
    ExitImage = ConstantValues::UnsetString;
    HigherTimeFrameExitImage = ConstantValues::UnsetString;
    LowerTimeFrameExitImage = ConstantValues::UnsetString;

    FurthestEquityDrawdownPercent = ConstantValues::EmptyDouble;
}

RecordColumns::~RecordColumns()
{
}

double RecordColumns::TotalMovePips()
{
    if (mTotalMovePips == -1.0)
    {
        double furthestPoint;
        if (OrderDirection == "Buy")
        {
            int entryIndex = iBarShift(Symbol, EntryTimeFrame, EntryTime, true);
            if (entryIndex == ConstantValues::EmptyInt)
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            if (!MQLHelper::GetHighestHighBetween(Symbol, EntryTimeFrame, entryIndex, 0, true, furthestPoint))
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            mTotalMovePips = NormalizeDouble(PipConverter::PointsToPips((furthestPoint - EntryPrice)), 2);
        }
        else if (OrderDirection == "Sell")
        {
            int entryIndex = iBarShift(Symbol, EntryTimeFrame, EntryTime, true);
            if (entryIndex == ConstantValues::EmptyInt)
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            if (!MQLHelper::GetLowestLowBetween(Symbol, EntryTimeFrame, entryIndex, 0, true, furthestPoint))
            {
                mTotalMovePips = 0.0;
                return mTotalMovePips;
            }

            mTotalMovePips = NormalizeDouble(PipConverter::PointsToPips((EntryPrice - furthestPoint)), 2);
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
        if (OrderDirection == "Buy")
        {
            mPotentialRR = NormalizeDouble(totalMovePips / (PipConverter::PointsToPips(EntryPrice - OriginalStopLoss)), 2);
        }
        else if (OrderDirection == "Sell")
        {
            mPotentialRR = NormalizeDouble(totalMovePips / (PipConverter::PointsToPips(OriginalStopLoss - EntryPrice)), 2);
        }
    }

    return mPotentialRR;
}

double RecordColumns::RRSecured()
{
    if (mRRSecured != -99)
    {
        return mRRSecured;
    }

    if (EntryPrice - OriginalStopLoss == 0)
    {
        // return -99 here so that i know something went wrong. Should never happen naturally
        return -99;
    }

    if (OrderDirection == "Buy")
    {
        mRRSecured = (EntryPrice - ExitPrice) / (EntryPrice - OriginalStopLoss);
    }
    else if (OrderDirection == "Sell")
    {
        mRRSecured = (ExitPrice - EntryPrice) / (OriginalStopLoss - EntryPrice);
    }

    // switch the sign since the calc gives positive values when exiting at a worse price than we entered at and a negative value when exiting at a better price
    mRRSecured *= -1;
    return mRRSecured;
}

// ColumnIndex should be the Character representing the column i.e A, B, C etc.
string RecordColumns::CurrentDrawdown(string columnIndex)
{
    if (RowNumber == ConstantValues::UnsetString)
    {
        return RowNumber;
    }

    // add double qutoes around the formula so the csv ignores the ',' in it
    return StringFormat("\"=MIN((%s%d - MAX($%s$%d:%s%d)) / MAX($%s$%d:%s%d), 0)\"",
                        columnIndex,
                        RowNumber,
                        columnIndex,
                        2,
                        columnIndex,
                        RowNumber,
                        columnIndex,
                        2,
                        columnIndex,
                        RowNumber);
}

// ColumnIndex should be the Character representing the column i.e A, B, C etc.
string RecordColumns::PercentChange(string columnIndex)
{
    if (RowNumber == ConstantValues::UnsetString)
    {
        return RowNumber;
    }

    // (final - inital) / initial
    return StringFormat("=(%s%d - %s%d) / %s%d",
                        columnIndex,
                        RowNumber,
                        columnIndex,
                        RowNumber - 1,
                        columnIndex,
                        RowNumber - 1);
}
