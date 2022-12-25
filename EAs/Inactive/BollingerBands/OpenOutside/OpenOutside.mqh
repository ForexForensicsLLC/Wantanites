//+------------------------------------------------------------------+
//|                                                    OpenOutside.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EA\EA.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

class OpenOutside : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

public:
    OpenOutside(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~OpenOutside();

    double UpperBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, shift); }
    double MiddleBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, shift); }
    double LowerBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, shift); }

    virtual double RiskPercent();

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManageCurrentPendingSetupTicket();
    virtual void ManageCurrentActiveSetupTicket();
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(int ticketIndex);
    virtual void CheckCurrentSetupTicket();
    virtual void CheckPreviousSetupTicket(int ticketIndex);
    virtual void RecordTicketOpenData();
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

OpenOutside::OpenOutside(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mBarCount = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<OpenOutside>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<OpenOutside, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<OpenOutside, SingleTimeFrameEntryTradeRecord>(this);
}

double OpenOutside::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<OpenOutside>(this, 5, 0.5);
}

OpenOutside::~OpenOutside()
{
}

void OpenOutside::Run()
{
    EAHelper::Run<OpenOutside>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool OpenOutside::AllowedToTrade()
{
    return EAHelper::BelowSpread<OpenOutside>(this) && EAHelper::WithinTradingSession<OpenOutside>(this);
}

void OpenOutside::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < LowerBand(0))
        {
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > UpperBand(0))
        {
            mHasSetup = true;
        }
    }
}

void OpenOutside::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void OpenOutside::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<OpenOutside>(this, deletePendingOrder, false, error);
}

bool OpenOutside::Confirmation()
{
    return true;
}

void OpenOutside::PlaceOrders()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
    {
        return;
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceMarketOrder<OpenOutside>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }
}

void OpenOutside::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);

    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    if (entryCandleIndex > 1)
    {
        InvalidateSetup(true);
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
}

void OpenOutside::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        // if (entryIndex > 5)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice())
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a low within our stop loss
        // if (entryIndex <= 200)
        // {
        //     // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
        //     for (int i = entryIndex - 2; i >= 0; i--)
        //     {
        //         if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
        //         {
        //             break;
        //         }

        //         for (int j = entryIndex; j > i; j--)
        //         {
        //             if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j))
        //             {
        //                 // managed to break back out, close at BE
        //                 if (currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //                 {
        //                     mCurrentSetupTicket.Close();
        //                     return;
        //                 }
        //             }
        //         }
        //     }
        // }
        // else
        // {
        //     // TOD: Create error code
        //     string additionalInformation = "Entry Index: " + entryIndex;
        //     RecordError(-1, additionalInformation);
        // }

        // movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);

        if (currentTick.bid >= MiddleBand(0))
        {
            mCurrentSetupTicket.Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        // if (entryIndex > 5)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice())
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        // middle close
        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a high within our stop loss
        // if (entryIndex <= 200)
        // {
        //     // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
        //     for (int i = entryIndex - 2; i >= 0; i--)
        //     {
        //         if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
        //         {
        //             break;
        //         }

        //         for (int j = entryIndex; j > i; j--)
        //         {
        //             if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j))
        //             {
        //                 // managed to break back out, close at BE
        //                 if (currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //                 {
        //                     mCurrentSetupTicket.Close();
        //                     return;
        //                 }
        //             }
        //         }
        //     }
        // }
        // else
        // {
        //     // TOD: Create error code
        //     string additionalInformation = "Entry Index: " + entryIndex;
        //     RecordError(-1, additionalInformation);
        // }

        // movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);

        if (currentTick.ask <= MiddleBand(0))
        {
            mCurrentSetupTicket.Close();
        }
    }

    // if (movedPips)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<OpenOutside>(this, mBEAdditionalPips);
    // }
}

bool OpenOutside::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<OpenOutside>(this, ticket);
}

void OpenOutside::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<OpenOutside>(this, mPreviousSetupTickets[ticketIndex]);
}

void OpenOutside::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<OpenOutside>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<OpenOutside>(this);
}

void OpenOutside::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<OpenOutside>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<OpenOutside>(this, ticketIndex);
}

void OpenOutside::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<OpenOutside>(this);
}

void OpenOutside::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<OpenOutside>(this, partialedTicket, newTicketNumber);
}

void OpenOutside::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<OpenOutside>(this, ticket, Period());
}

void OpenOutside::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<OpenOutside>(this, error, additionalInformation);
}

void OpenOutside::Reset()
{
}