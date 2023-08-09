//+------------------------------------------------------------------+
//|                                        LiquidationMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class LiquidationMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    int mLastEntryMB;

    MBTracker *mSetupMBT;
    LiquidationSetupTracker *mLST;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mMostRecentMB;
    datetime mZoneCandleTime;
    datetime mEntryCandleTime;

    double mMinInitialBreakTotalPips;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    bool mBrokeEntryIndex;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    LiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                  CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                  CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, LiquidationSetupTracker *&lst);
    ~LiquidationMB();

    virtual double RiskPercent() { return mRiskPercent; }
    double EMA(int index);

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

LiquidationMB::LiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, LiquidationSetupTracker *&lst)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mLastEntryMB = EMPTY;

    mSetupMBT = setupMBT;
    mLST = lst;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mMostRecentMB = EMPTY;
    mZoneCandleTime = 0;
    mEntryCandleTime = 0;

    mMinInitialBreakTotalPips = 0.0;
    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mBrokeEntryIndex = false;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    mLargestAccountBalance = 100000;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<LiquidationMB>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<LiquidationMB, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<LiquidationMB, SingleTimeFrameEntryTradeRecord>(this);
}

double LiquidationMB::EMA(int index)
{
    return IndicatorHelper::MovingAverage(EntrySymbol(), EntryTimeFrame(), 100, 0, MODE_EMA, PRICE_CLOSE, index);
}

LiquidationMB::~LiquidationMB()
{
}

void LiquidationMB::PreRun()
{
    mSetupMBT.Draw();
}

bool LiquidationMB::AllowedToTrade()
{
    return EARunHelper::BelowSpread<LiquidationMB>(this) && EARunHelper::WithinTradingSession<LiquidationMB>(this);
}

void LiquidationMB::CheckSetSetup()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (mSetupMBT.MBsCreated() - 1 == mLastEntryMB)
    {
        return;
    }

    if (EASetupHelper::CheckSetLiquidationMBSetup<LiquidationMB>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        MBState *firstMBInSetup;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBInSetup))
        {
            return;
        }

        // make sure first mb isn't too small
        if (firstMBInSetup.StartIndex() - firstMBInSetup.EndIndex() < 10)
        {
            return;
        }

        bool zoneIsHolding = false;
        int error = EASetupHelper::LiquidationMBZoneIsHolding<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, zoneIsHolding);
        if (error != Errors::NO_ERROR)
        {
            EASetupHelper::InvalidateSetup<LiquidationMB>(this, true, false);
            return;
        }

        double minBreakLength = 20;
        if (zoneIsHolding)
        {
            MBState *secondMBInSetup;
            if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, secondMBInSetup))
            {
                return;
            }

            MBState *liquidationMBInSetup;
            if (!mSetupMBT.GetMB(mLiquidationMBInSetupNumber, liquidationMBInSetup))
            {
                return;
            }

            if (SetupType() == OP_BUY)
            {
                // make sure first mb is above ema
                double firstMBLow = iLow(EntrySymbol(), EntryTimeFrame(), firstMBInSetup.LowIndex());
                double firstMBEMA = EMA(firstMBInSetup.LowIndex());
                if (firstMBLow < firstMBEMA)
                {
                    return;
                }

                // make sure second mb is above ema
                double secondMBLow = iLow(EntrySymbol(), EntryTimeFrame(), secondMBInSetup.LowIndex());
                double secondMBEMA = EMA(secondMBInSetup.LowIndex());
                if (secondMBLow < secondMBEMA)
                {
                    return;
                }

                // make sure liq mb is above ema
                double liqMBLow = iLow(EntrySymbol(), EntryTimeFrame(), liquidationMBInSetup.LowIndex());
                double liqMBEMA = EMA(liquidationMBInSetup.LowIndex());
                if (liqMBLow < liqMBEMA)
                {
                    return;
                }

                int lowestIndex = EMPTY;
                if (!MQLHelper::GetLowestIndexBetween(EntrySymbol(), EntryTimeFrame(), firstMBInSetup.EndIndex() - 1, 1, true, lowestIndex))
                {
                    return;
                }

                // need to break within 3 candles of our lowest
                if (lowestIndex > 3)
                {
                    return;
                }

                // make sure low is above ema
                if (iLow(EntrySymbol(), EntryTimeFrame(), lowestIndex) < EMA(lowestIndex))
                {
                    return;
                }

                // make sure we broke above
                if (iClose(EntrySymbol(), EntryTimeFrame(), 1) < iHigh(EntrySymbol(), EntryTimeFrame(), 2))
                {
                    return;
                }

                // make sure we have a decent sized setup / mbs aren't too small
                if (firstMBInSetup.EndIndex() <= minBreakLength)
                {
                    return;
                }

                mHasSetup = true;
                mZoneCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 2);
                mMostRecentMB = mSetupMBT.MBsCreated() - 1;
            }
            else if (SetupType() == OP_SELL)
            {
                // make sure first mb is above ema
                double firstMBHigh = iHigh(EntrySymbol(), EntryTimeFrame(), firstMBInSetup.HighIndex());
                double firstMBEMA = EMA(firstMBInSetup.HighIndex());
                if (firstMBHigh > firstMBEMA)
                {
                    return;
                }

                // make sure second mb is above ema
                double secondMBHigh = iHigh(EntrySymbol(), EntryTimeFrame(), secondMBInSetup.HighIndex());
                double secondMBEMA = EMA(secondMBInSetup.HighIndex());
                if (secondMBHigh > secondMBEMA)
                {
                    return;
                }

                // make sure third mb is above ema
                double liqMBHigh = iHigh(EntrySymbol(), EntryTimeFrame(), liquidationMBInSetup.HighIndex());
                double liqMBEMA = EMA(liquidationMBInSetup.HighIndex());
                if (liqMBHigh > liqMBEMA)
                {
                    return;
                }

                int highestIndex = EMPTY;
                if (!MQLHelper::GetHighestIndexBetween(EntrySymbol(), EntryTimeFrame(), firstMBInSetup.EndIndex() - 1, 1, true, highestIndex))
                {
                    return;
                }

                // need to break within 3 candles of our highest
                if (highestIndex > 3)
                {
                    return;
                }

                // make sure high is below ema
                if (iHigh(EntrySymbol(), EntryTimeFrame(), highestIndex) > EMA(highestIndex))
                {
                    return;
                }

                // make sure we broke below a candle
                if (iClose(EntrySymbol(), EntryTimeFrame(), 1) > iLow(EntrySymbol(), EntryTimeFrame(), 2))
                {
                    return;
                }

                // make sure we have a decent sized setup / mbs aren't too small
                if (firstMBInSetup.EndIndex() <= minBreakLength)
                {
                    return;
                }

                mHasSetup = true;
                mZoneCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 2);
                mMostRecentMB = mSetupMBT.MBsCreated() - 1;
            }
        }
    }
}

void LiquidationMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (mFirstMBInSetupNumber == mLastEntryMB)
    {
        InvalidateSetup(true);
        return;
    }

    // Start of Setup TF Liquidation
    if (EASetupHelper::CheckBrokeMBRangeStart<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        InvalidateSetup(true);
        return;
    }

    // End of Setup TF Liquidation
    if (EASetupHelper::CheckBrokeMBRangeStart<LiquidationMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        InvalidateSetup(false);
        return;
    }

    bool zoneIsHolding = false;
    int error = EASetupHelper::LiquidationMBZoneIsHolding<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, zoneIsHolding);
    if (error != Errors::NO_ERROR || !zoneIsHolding)
    {
        InvalidateSetup(true, error);
        return;
    }

    int zoneCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mZoneCandleTime);
    if (SetupType() == OP_BUY)
    {
        // invalidate if we broke below our candle zone with a body
        if (MathMin(iOpen(EntrySymbol(), EntryTimeFrame(), 1), iClose(EntrySymbol(), EntryTimeFrame(), 1)) < iLow(EntrySymbol(), EntryTimeFrame(), zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        // invalidate if we broke above our candle zone with a body
        if (MathMax(iOpen(EntrySymbol(), EntryTimeFrame(), 1), iClose(EntrySymbol(), EntryTimeFrame(), 1)) > iHigh(EntrySymbol(), EntryTimeFrame(), zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void LiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EASetupHelper::ResetLiquidationMBSetup<LiquidationMB>(this, false);
    EASetupHelper::InvalidateSetup<LiquidationMB>(this, deletePendingOrder, false, error);
}

bool LiquidationMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return hasTicket;
    }

    if (mSetupMBT.MBsCreated() - 1 != mMostRecentMB)
    {
        InvalidateSetup(true);
        return false;
    }

    int zoneCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mZoneCandleTime);

    // make sure we actually had a decent push up after the inital break
    if (zoneCandleIndex < 5)
    {
        return false;
    }

    if (SetupType() == OP_BUY)
    {
        bool pushedUpAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bearish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBearish(EntrySymbol(), EntryTimeFrame(), i) &&
                MathMin(iOpen(EntrySymbol(), EntryTimeFrame(), i), iClose(EntrySymbol(), EntryTimeFrame(), i)) < iLow(EntrySymbol(), EntryTimeFrame(), i + 1))
            {
                pushedUpAfterInitialBreak = true;
                break;
            }
        }

        if (!pushedUpAfterInitialBreak)
        {
            return false;
        }

        // need a body break above our previous candle while within the candle zone
        if (iLow(EntrySymbol(), EntryTimeFrame(), 2) < iHigh(EntrySymbol(), EntryTimeFrame(), zoneCandleIndex) &&
            iClose(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), 2))
        {
            return true;
        }
    }
    else if (SetupType() == OP_SELL)
    {
        bool pushedDownAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bullish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBullish(EntrySymbol(), EntryTimeFrame(), i) &&
                MathMax(iOpen(EntrySymbol(), EntryTimeFrame(), i), iClose(EntrySymbol(), EntryTimeFrame(), i)) > iHigh(EntrySymbol(), EntryTimeFrame(), i + 1))
            {
                pushedDownAfterInitialBreak = true;
                break;
            }
        }

        if (!pushedDownAfterInitialBreak)
        {
            return false;
        }
        // need a body break below our previous candle while within the candle zone
        if (iHigh(EntrySymbol(), EntryTimeFrame(), 2) > iLow(EntrySymbol(), EntryTimeFrame(), zoneCandleIndex) &&
            iClose(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), 2))
        {
            return true;
        }
    }

    return hasTicket;
}

void LiquidationMB::PlaceOrders()
{
    if (!mCurrentSetupTickets.IsEmpty())
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        double lowest = MathMin(iLow(EntrySymbol(), EntryTimeFrame(), 2), iLow(EntrySymbol(), EntryTimeFrame(), 1));

        entry = iHigh(EntrySymbol(), EntryTimeFrame(), 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (SetupType() == OP_SELL)
    {
        double highest = MathMax(iHigh(EntrySymbol(), EntryTimeFrame(), 2), iHigh(EntrySymbol(), EntryTimeFrame(), 1));
        entry = iLow(EntrySymbol(), EntryTimeFrame(), 1) - OrderHelper::PipsToRange(mEntryPaddingPips);

        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips), entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<LiquidationMB>(this, entry, stopLoss);

    if (!mCurrentSetupTickets.IsEmpty())
    {
        mEntryCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 1);
    }
}

void LiquidationMB::PreManageTickets()
{
}

void LiquidationMB::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
    mBrokeEntryIndex = false;

    int entryCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    if (SetupType() == OP_BUY && entryCandleIndex > 1)
    {
        if (iLow(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (SetupType() == OP_SELL && entryCandleIndex > 1)
    {
        if (iHigh(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void LiquidationMB::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    int selectError = ticket.SelectIfOpen("Stuff");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    int entryIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    bool movedPips = false;

    if (SetupType() == OP_BUY)
    {
        if (!mBrokeEntryIndex)
        {
            for (int i = entryIndex - 1; i >= 0; i--)
            {
                if (iLow(EntrySymbol(), EntryTimeFrame(), i) < iLow(EntrySymbol(), EntryTimeFrame(), entryIndex))
                {
                    mBrokeEntryIndex = true;
                }
            }
        }

        if (mBrokeEntryIndex && CurrentTick().Bid() >= OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips))
        {
            ticket.Close();
            return;
        }

        // get too close to our entry after 10 candles and coming back
        if (entryIndex >= 10)
        {
            if (mLastManagedBid > OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips) &&
                CurrentTick().Bid() <= OrderOpenPrice() + PipConverter::PipsToPoints(mBEAdditionalPips))
            {
                ticket.Close();
                return;
            }
        }

        movedPips = CurrentTick().Bid() - OrderOpenPrice() >= PipConverter::PipsToPoints(mPipsToWaitBeforeBE);
    }
    else if (SetupType() == OP_SELL)
    {
        if (!mBrokeEntryIndex)
        {
            for (int i = entryIndex - 1; i >= 0; i--)
            {
                // change to any break lower within our entry
                if (iHigh(EntrySymbol(), EntryTimeFrame(), i) > iHigh(EntrySymbol(), EntryTimeFrame(), entryIndex))
                {
                    mBrokeEntryIndex = true;
                }
            }
        }

        if (mBrokeEntryIndex && CurrentTick().Ask() <= OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips))
        {
            ticket.Close();
            return;
        }

        // get too close to our entry after 10 candles and coming back
        if (entryIndex >= 10)
        {
            if (mLastManagedAsk < OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips) &&
                CurrentTick().Ask() >= OrderOpenPrice() - PipConverter::PipsToPoints(mBEAdditionalPips))
            {
                ticket.Close();
                return;
            }
        }

        movedPips = OrderOpenPrice() - CurrentTick().Ask() >= PipConverter::PipsToPoints(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAOrderHelper::MoveTicketToBreakEven<LiquidationMB>(this, ticket, mBEAdditionalPips);
    }

    mLastManagedAsk = CurrentTick().Ask();
    mLastManagedBid = CurrentTick().Bid();
}

bool LiquidationMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAOrderHelper::TicketStopLossIsMovedToBreakEven<LiquidationMB>(this, ticket);
}

void LiquidationMB::ManagePreviousSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<LiquidationMB>(this, ticket);
}

void LiquidationMB::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void LiquidationMB::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void LiquidationMB::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LiquidationMB>(this, ticket);
}

void LiquidationMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LiquidationMB>(this, partialedTicket, newTicketNumber);
}

void LiquidationMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LiquidationMB>(this, ticket, EntryTimeFrame());
}

void LiquidationMB::RecordError(string methodName, int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LiquidationMB>(this, methodName, error, additionalInformation);
}

bool LiquidationMB::ShouldReset()
{
    return false;
}

void LiquidationMB::Reset()
{
}