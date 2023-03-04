//+------------------------------------------------------------------+
//|                                                    WickLiquidatedMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class WickLiquidatedMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

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
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~WickLiquidatedMB();

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

WickLiquidatedMB::WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mLiquidatedMBCandleTime = 0;

    mMinMBRatio = 0.0;
    mMaxMBRatio = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<WickLiquidatedMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<WickLiquidatedMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<WickLiquidatedMB, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

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

void WickLiquidatedMB::Run()
{
    EAHelper::RunDrawMBT<WickLiquidatedMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool WickLiquidatedMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<WickLiquidatedMB>(this) && EAHelper::WithinTradingSession<WickLiquidatedMB>(this) &&
           mLastEntryMB < mSetupMBT.MBsCreated() - 1;
}

void WickLiquidatedMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<WickLiquidatedMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.Height() < OrderHelper::PipsToRange(mMinMBHeight))
        {
            return;
        }

        mHasSetup = true;
    }
}

void WickLiquidatedMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }
}

void WickLiquidatedMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<WickLiquidatedMB>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<WickLiquidatedMB>(this, false);

    mLiquidatedMBCandleTime = 0;
}

bool WickLiquidatedMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    bool candleFurther = false;

    if (mSetupType == OP_BUY)
    {
        if (mLiquidatedMBCandleTime == 0)
        {
            double mbLow = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());

            // liquidate the previous mb with a doji wick that is longer than 50% of the mb
            if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) > mbLow &&
                iLow(mEntrySymbol, mEntryTimeFrame, 1) < mbLow)
            {
                mLiquidatedMBCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
            }
        }

        if (mLiquidatedMBCandleTime > 0)
        {
            int liquidationCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLiquidatedMBCandleTime);
            for (int i = liquidationCandleIndex; i >= 1; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex))
                {
                    mLastEntryMB = mFirstMBInSetupNumber;
                    InvalidateSetup(true);
                }
            }

            double wickLength = CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex) -
                                iLow(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex);

            return wickLength > tempMBState.Height() / 2 &&
                   iClose(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex - 1) > iHigh(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (mLiquidatedMBCandleTime == 0)
        {
            double mbHigh = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());

            // liquidate the previous mb with a doji wick that is longer than 50% of the mb
            if (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) < mbHigh &&
                iHigh(mEntrySymbol, mEntryTimeFrame, 1) > mbHigh)
            {
                mLiquidatedMBCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
            }
        }

        if (mLiquidatedMBCandleTime > 0)
        {
            int liquidationCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLiquidatedMBCandleTime);
            for (int i = liquidationCandleIndex; i >= 1; i--)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex))
                {
                    mLastEntryMB = mFirstMBInSetupNumber;
                    InvalidateSetup(true);
                }
            }

            double wickLength = iHigh(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex) -
                                CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex);

            return wickLength > tempMBState.Height() / 2 &&
                   iClose(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex - 1) < iLow(mEntrySymbol, mEntryTimeFrame, liquidationCandleIndex);
        }
    }

    return false;
}

void WickLiquidatedMB::PlaceOrders()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
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
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<WickLiquidatedMB>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mFirstMBInSetupNumber; // only 1 trade per mb whether we actually enter or not
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mFailedImpulseEntryTime = 0;
    }
}

void WickLiquidatedMB::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void WickLiquidatedMB::ManageCurrentActiveSetupTicket()
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

    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        if (entryIndex > 5)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) && currentTick.bid >= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a low within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }

                        // pushed too far into SL, take the -0.5
                        if (EAHelper::CloseIfPercentIntoStopLoss<WickLiquidatedMB>(this, mCurrentSetupTicket, 0.5))
                        {
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 5)
        {
            if (mLastManagedBid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips) &&
                currentTick.bid <= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        if (entryIndex > 5)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) && currentTick.ask <= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // middle close
        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a high within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }

                        // pushed too far into SL, take the -0.5
                        if (EAHelper::CloseIfPercentIntoStopLoss<WickLiquidatedMB>(this, mCurrentSetupTicket, 0.5))
                        {
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + orderPlaceIndex;
            RecordError(-1, additionalInformation);
        }

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 5)
        {
            if (mLastManagedAsk < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips) &&
                currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<WickLiquidatedMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool WickLiquidatedMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<WickLiquidatedMB>(this, ticket);
}

void WickLiquidatedMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<WickLiquidatedMB>(this, mPreviousSetupTickets[ticketIndex]);
}

void WickLiquidatedMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickLiquidatedMB>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<WickLiquidatedMB>(this);
}

void WickLiquidatedMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickLiquidatedMB>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<WickLiquidatedMB>(this, ticketIndex);
}

void WickLiquidatedMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<WickLiquidatedMB>(this);
}

void WickLiquidatedMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickLiquidatedMB>(this, partialedTicket, newTicketNumber);
}

void WickLiquidatedMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<WickLiquidatedMB>(this, ticket, Period());
}

void WickLiquidatedMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<WickLiquidatedMB>(this, error, additionalInformation);
}

void WickLiquidatedMB::Reset()
{
}