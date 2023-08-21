//+------------------------------------------------------------------+
//|                                                    WickLiquidatedMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Utilities\CandleStickTracker.mqh>

class WickLiquidatedMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    datetime mLiquidatedMBCandleTime;

    double mMinMBRatio;
    double mMaxMBRatio;

    double mMinMBHeight;
    double mMaxMBHeight;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~WickLiquidatedMB();

    virtual double RiskPercent();

    virtual void PreRun();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void PreManageTickets();
    virtual void ManageCurrentPendingSetupTicket(Ticket &ticket);
    virtual void ManageCurrentActiveSetupTicket(Ticket &ticket);
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(Ticket &ticket);
    virtual void CheckCurrentSetupTicket(Ticket &ticket);
    virtual void CheckPreviousSetupTicket(Ticket &ticket);
    virtual void RecordTicketOpenData(Ticket &ticket);
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

WickLiquidatedMB::WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;
    mLiquidatedMBCandleTime = 0;

    mMinMBRatio = 0.0;
    mMaxMBRatio = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<WickLiquidatedMB>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<WickLiquidatedMB, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<WickLiquidatedMB, MultiTimeFrameEntryTradeRecord>(this);

    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

WickLiquidatedMB::~WickLiquidatedMB()
{
}

double WickLiquidatedMB::RiskPercent()
{
    return mRiskPercent;
}

void WickLiquidatedMB::PreRun()
{
    EARunHelper::ShowOpenTicketProfit<WickLiquidatedMB>(this);
    mMBT.Draw();
}

bool WickLiquidatedMB::AllowedToTrade()
{
    return EARunHelper::BelowSpread<WickLiquidatedMB>(this) && EARunHelper::WithinTradingSession<WickLiquidatedMB>(this);
}

void WickLiquidatedMB::CheckSetSetup()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (EASetupHelper::CheckSetSingleMBSetup<WickLiquidatedMB>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
    {
        // MBState *tempMBState;
        // if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        // {
        //     return;
        // }

        // if (tempMBState.Height() < PipConverter::PipsToPoints(mMinMBHeight))
        // {
        //     return;
        // }

        mHasSetup = true;
    }
}

void WickLiquidatedMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (mFirstMBInSetupNumber != ConstantValues::EmptyInt && mFirstMBInSetupNumber != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }
}

void WickLiquidatedMB::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;
    mLiquidatedMBCandleTime = 0;

    EASetupHelper::InvalidateSetup<WickLiquidatedMB>(this, deletePendingOrder, false, error);
}

bool WickLiquidatedMB::Confirmation()
{
    // bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    // if (hasTicket)
    // {
    //     return true;
    // }

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return false;
    }

    MBState *tempMBState;
    if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    bool candleFurther = false;

    if (SetupType() == OP_BUY)
    {
        if (mLiquidatedMBCandleTime == 0)
        {
            double mbLow = iLow(EntrySymbol(), EntryTimeFrame(), tempMBState.LowIndex());

            // liquidate the previous mb with a doji wick that is longer than 50% of the mb
            if (CandleStickHelper::LowestBodyPart(EntrySymbol(), EntryTimeFrame(), 1) >= mbLow &&
                iLow(EntrySymbol(), EntryTimeFrame(), 1) < mbLow)
            {
                return true;
                mLiquidatedMBCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 1);
            }
        }

        // if (mLiquidatedMBCandleTime > 0)
        // {
        //     int liquidationCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mLiquidatedMBCandleTime);
        //     for (int i = liquidationCandleIndex; i >= 1; i--)
        //     {
        //         if (iLow(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex))
        //         {
        //             mLastEntryMB = mFirstMBInSetupNumber;
        //             InvalidateSetup(true);
        //         }
        //     }

        //     double wickLength = CandleStickHelper::LowestBodyPart(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex) -
        //                         iLow(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex);

        //     return wickLength > tempMBState.Height() / 2 &&
        //            iClose(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex - 1) > iHigh(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex);
        // }
    }
    else if (SetupType() == OP_SELL)
    {
        if (mLiquidatedMBCandleTime == 0)
        {
            double mbHigh = iHigh(EntrySymbol(), EntryTimeFrame(), tempMBState.HighIndex());

            // liquidate the previous mb with a doji wick that is longer than 50% of the mb
            if (CandleStickHelper::HighestBodyPart(EntrySymbol(), EntryTimeFrame(), 1) <= mbHigh &&
                iHigh(EntrySymbol(), EntryTimeFrame(), 1) > mbHigh)
            {
                return true;
                mLiquidatedMBCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 1);
            }
        }

        // if (mLiquidatedMBCandleTime > 0)
        // {
        //     int liquidationCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mLiquidatedMBCandleTime);
        //     for (int i = liquidationCandleIndex; i >= 1; i--)
        //     {
        //         if (iHigh(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex))
        //         {
        //             mLastEntryMB = mFirstMBInSetupNumber;
        //             InvalidateSetup(true);
        //         }
        //     }

        //     double wickLength = iHigh(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex) -
        //                         CandleStickHelper::HighestBodyPart(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex);

        //     return wickLength > tempMBState.Height() / 2 &&
        //            iClose(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex - 1) < iLow(EntrySymbol(), EntryTimeFrame(), liquidationCandleIndex);
        // }
    }

    return false;
}

void WickLiquidatedMB::PlaceOrders()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        double lowest = MathMin(iLow(EntrySymbol(), EntryTimeFrame(), 1), iLow(EntrySymbol(), EntryTimeFrame(), 2));

        // entry = iHigh(EntrySymbol(), EntryTimeFrame(), 1) + PipConverter::PipsToPoints(mMaxSpreadPips + mEntryPaddingPips);
        // stopLoss = MathMin(lowest - PipConverter::PipsToPoints(mStopLossPaddingPips), entry - PipConverter::PipsToPoints(mMinStopLossPips));
        entry = CurrentTick().Ask();
        stopLoss = iLow(EntrySymbol(), EntryTimeFrame(), 1);
        takeProfit = entry + (MathAbs(entry - stopLoss) * 3);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        double highest = MathMax(iHigh(EntrySymbol(), EntryTimeFrame(), 1), iHigh(EntrySymbol(), EntryTimeFrame(), 2));

        // entry = iLow(EntrySymbol(), EntryTimeFrame(), 1) - PipConverter::PipsToPoints(mEntryPaddingPips);
        // stopLoss = MathMax(highest + PipConverter::PipsToPoints(mStopLossPaddingPips + mMaxSpreadPips), entry + PipConverter::PipsToPoints(mMinStopLossPips));
        entry = CurrentTick().Bid();
        stopLoss = iHigh(EntrySymbol(), EntryTimeFrame(), 1);
        takeProfit = entry - (MathAbs(entry - stopLoss) * 3);
    }

    // EAHelper::PlaceStopOrder<WickLiquidatedMB>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);
    bool canLose = MathRand() % 6 == 0;
    if (canLose)
    {
        EAOrderHelper::PlaceMarketOrder<WickLiquidatedMB>(this, entry, stopLoss);
    }
    else if (EASetupHelper::TradeWillWin<WickLiquidatedMB>(this, iTime(EntrySymbol(), EntryTimeFrame(), 0), entry, stopLoss, takeProfit))
    {
        EAOrderHelper::PlaceMarketOrder<WickLiquidatedMB>(this, entry, stopLoss);
    }

    // if (mCurrentSetupTicket.Number() != EMPTY)
    // {
    //     mLastEntryMB = mFirstMBInSetupNumber; // only 1 trade per mb whether we actually enter or not
    //     mEntryCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 1);
    //     mFailedImpulseEntryTime = 0;
    // }
}

void WickLiquidatedMB::PreManageTickets()
{
}

void WickLiquidatedMB::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
    // int entryCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // if (SetupType() == OP_BUY)
    // {
    //     if (iLow(EntrySymbol(), EntryTimeFrame(), 0) < iLow(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (SetupType() == OP_SELL)
    // {
    //     if (iHigh(EntrySymbol(), EntryTimeFrame(), 0) > iHigh(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
}

void WickLiquidatedMB::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAOrderHelper::MoveToBreakEvenAfterPips<WickLiquidatedMB>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    // if (TerminalErrors::IsTerminalError(selectError))
    // {
    //     RecordError(selectError);
    //     return;
    // }

    // MqlTick currentTick;
    // if (!SymbolInfoTick(Symbol(), currentTick))
    // {
    //     RecordError(GetLastError());
    //     return;
    // }

    // int orderPlaceIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    // int entryIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), OrderOpenTime());

    // bool movedPips = false;

    // if (SetupType() == OP_BUY)
    // {
    //     if (entryIndex > 5)
    //     {
    //         // close if we are still opening within our entry and get the chance to close at BE
    //         if (iOpen(EntrySymbol(), EntryTimeFrame(), 1) < iHigh(EntrySymbol(), EntryTimeFrame(), orderPlaceIndex) && currentTick.bid >= OrderOpenPrice())
    //         {
    //             mCurrentSetupTicket.Close();
    //         }
    //     }

    //     // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
    //     // close if we break a low within our stop loss
    //     if (entryIndex <= 200)
    //     {
    //         // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
    //         for (int i = entryIndex - 2; i >= 0; i--)
    //         {
    //             if (iLow(EntrySymbol(), EntryTimeFrame(), i) > OrderOpenPrice())
    //             {
    //                 break;
    //             }

    //             for (int j = entryIndex; j > i; j--)
    //             {
    //                 if (iLow(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), j))
    //                 {
    //                     // managed to break back out, close at BE
    //                     if (currentTick.bid >= OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips))
    //                     {
    //                         mCurrentSetupTicket.Close();
    //                         return;
    //                     }

    //                     // pushed too far into SL, take the -0.5
    //                     if (EAHelper::CloseIfPercentIntoStopLoss<WickLiquidatedMB>(this, mCurrentSetupTicket, 0.5))
    //                     {
    //                         return;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     else
    //     {
    //         // TOD: Create error code
    //         string additionalInformation = "Entry Index: " + entryIndex;
    //         RecordError(-1, additionalInformation);
    //     }

    //     // get too close to our entry after 5 candles and coming back
    //     if (entryIndex >= 5)
    //     {
    //         if (mLastManagedBid > OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips) &&
    //             currentTick.bid <= OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //             return;
    //         }
    //     }

    //     movedPips = currentTick.bid - OrderOpenPrice() >= PipConverter::PipsToPoints(mPipsToWaitBeforeBE);
    // }
    // else if (SetupType() == OP_SELL)
    // {
    //     // early close
    //     if (entryIndex > 5)
    //     {
    //         // close if we are still opening above our entry and we get the chance to close at BE
    //         if (iOpen(EntrySymbol(), EntryTimeFrame(), 1) > iLow(EntrySymbol(), EntryTimeFrame(), orderPlaceIndex) && currentTick.ask <= OrderOpenPrice())
    //         {
    //             mCurrentSetupTicket.Close();
    //         }
    //     }

    //     // middle close
    //     // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
    //     // close if we break a high within our stop loss
    //     if (entryIndex <= 200)
    //     {
    //         // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
    //         for (int i = entryIndex - 2; i >= 0; i--)
    //         {
    //             if (iHigh(EntrySymbol(), EntryTimeFrame(), i) < OrderOpenPrice())
    //             {
    //                 break;
    //             }

    //             for (int j = entryIndex; j > i; j--)
    //             {
    //                 if (iHigh(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), j))
    //                 {
    //                     // managed to break back out, close at BE
    //                     if (currentTick.ask <= OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips))
    //                     {
    //                         mCurrentSetupTicket.Close();
    //                         return;
    //                     }

    //                     // pushed too far into SL, take the -0.5
    //                     if (EAHelper::CloseIfPercentIntoStopLoss<WickLiquidatedMB>(this, mCurrentSetupTicket, 0.5))
    //                     {
    //                         return;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     else
    //     {
    //         // TOD: Create error code
    //         string additionalInformation = "Entry Index: " + orderPlaceIndex;
    //         RecordError(-1, additionalInformation);
    //     }

    //     // get too close to our entry after 5 candles and coming back
    //     if (entryIndex >= 5)
    //     {
    //         if (mLastManagedAsk < OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips) &&
    //             currentTick.ask >= OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //             return;
    //         }
    //     }

    //     movedPips = OrderOpenPrice() - currentTick.ask >= PipConverter::PipsToPoints(mPipsToWaitBeforeBE);
    // }

    // if (movedPips)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<WickLiquidatedMB>(this, mBEAdditionalPips);
    // }

    // mLastManagedAsk = currentTick.ask;
    // mLastManagedBid = currentTick.bid;
}

bool WickLiquidatedMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAOrderHelper::TicketStopLossIsMovedToBreakEven<WickLiquidatedMB>(this, ticket);
}

void WickLiquidatedMB::ManagePreviousSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<WickLiquidatedMB>(this, ticket);
}

void WickLiquidatedMB::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void WickLiquidatedMB::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void WickLiquidatedMB::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<WickLiquidatedMB>(this, ticket);
}

void WickLiquidatedMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EARecordHelper::RecordPartialTradeRecord<WickLiquidatedMB>(this, partialedTicket, newTicketNumber);
}

void WickLiquidatedMB::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<WickLiquidatedMB>(this, ticket);
}

void WickLiquidatedMB::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<WickLiquidatedMB>(this, methodName, error, additionalInformation);
}

bool WickLiquidatedMB::ShouldReset()
{
    return false;
}

void WickLiquidatedMB::Reset()
{
}