//+------------------------------------------------------------------+
//|                                        LiquidationMB.mqh |
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

class LiquidationMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    string mEntrySymbol;
    int mEntryTimeFrame;

    int mBarCount;
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

    // virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishLiquidationMB : MagicNumbers::BearishLiquidationMB; }
    virtual double RiskPercent() { return mRiskPercent; }
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

    double EMA(int index);
};

LiquidationMB::LiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, LiquidationSetupTracker *&lst)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LiquidationMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LiquidationMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LiquidationMB, MultiTimeFrameEntryTradeRecord>(this);
}

double LiquidationMB::EMA(int index)
{
    return iMA(mEntrySymbol, mEntryTimeFrame, 100, 0, MODE_EMA, PRICE_CLOSE, index);
}

LiquidationMB::~LiquidationMB()
{
}

void LiquidationMB::Run()
{
    EAHelper::RunDrawMBT<LiquidationMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool LiquidationMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<LiquidationMB>(this) && EAHelper::WithinTradingSession<LiquidationMB>(this);
}

void LiquidationMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupMBT.MBsCreated() - 1 == mLastEntryMB)
    {
        return;
    }

    if (EAHelper::CheckSetLiquidationMBSetup<LiquidationMB>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
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
        int error = EAHelper::LiquidationMBZoneIsHolding<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, zoneIsHolding);
        if (error != ERR_NO_ERROR)
        {
            EAHelper::InvalidateSetup<LiquidationMB>(this, true, false);
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

            if (mSetupType == OP_BUY)
            {
                // make sure first mb is above ema
                double firstMBLow = iLow(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.LowIndex());
                double firstMBEMA = EMA(firstMBInSetup.LowIndex());
                if (firstMBLow < firstMBEMA)
                {
                    return;
                }

                // make sure second mb is above ema
                double secondMBLow = iLow(mEntrySymbol, mEntryTimeFrame, secondMBInSetup.LowIndex());
                double secondMBEMA = EMA(secondMBInSetup.LowIndex());
                if (secondMBLow < secondMBEMA)
                {
                    return;
                }

                // make sure liq mb is above ema
                double liqMBLow = iLow(mEntrySymbol, mEntryTimeFrame, liquidationMBInSetup.LowIndex());
                double liqMBEMA = EMA(liquidationMBInSetup.LowIndex());
                if (liqMBLow < liqMBEMA)
                {
                    return;
                }

                int lowestIndex = EMPTY;
                if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.EndIndex() - 1, 1, true, lowestIndex))
                {
                    return;
                }

                // need to break within 3 candles of our lowest
                if (lowestIndex > 3)
                {
                    return;
                }

                // make sure low is above ema
                if (iLow(mEntrySymbol, mEntryTimeFrame, lowestIndex) < EMA(lowestIndex))
                {
                    return;
                }

                // make sure we broke above
                if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
                {
                    return;
                }

                // make sure we have a decent sized setup / mbs aren't too small
                if (firstMBInSetup.EndIndex() <= minBreakLength)
                {
                    return;
                }

                mHasSetup = true;
                mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                mMostRecentMB = mSetupMBT.MBsCreated() - 1;
            }
            else if (mSetupType == OP_SELL)
            {
                // make sure first mb is above ema
                double firstMBHigh = iHigh(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.HighIndex());
                double firstMBEMA = EMA(firstMBInSetup.HighIndex());
                if (firstMBHigh > firstMBEMA)
                {
                    return;
                }

                // make sure second mb is above ema
                double secondMBHigh = iHigh(mEntrySymbol, mEntryTimeFrame, secondMBInSetup.HighIndex());
                double secondMBEMA = EMA(secondMBInSetup.HighIndex());
                if (secondMBHigh > secondMBEMA)
                {
                    return;
                }

                // make sure third mb is above ema
                double liqMBHigh = iHigh(mEntrySymbol, mEntryTimeFrame, liquidationMBInSetup.HighIndex());
                double liqMBEMA = EMA(liquidationMBInSetup.HighIndex());
                if (liqMBHigh > liqMBEMA)
                {
                    return;
                }

                int highestIndex = EMPTY;
                if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.EndIndex() - 1, 1, true, highestIndex))
                {
                    return;
                }

                // need to break within 3 candles of our highest
                if (highestIndex > 3)
                {
                    return;
                }

                // make sure high is below ema
                if (iHigh(mEntrySymbol, mEntryTimeFrame, highestIndex) > EMA(highestIndex))
                {
                    return;
                }

                // make sure we broke below a candle
                if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
                {
                    return;
                }

                // make sure we have a decent sized setup / mbs aren't too small
                if (firstMBInSetup.EndIndex() <= minBreakLength)
                {
                    return;
                }

                mHasSetup = true;
                mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                mMostRecentMB = mSetupMBT.MBsCreated() - 1;
            }
        }
    }
}

void LiquidationMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber == mLastEntryMB)
    {
        InvalidateSetup(true);
        return;
    }

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        InvalidateSetup(true);
        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<LiquidationMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        InvalidateSetup(false);
        return;
    }

    bool zoneIsHolding = false;
    int error = EAHelper::LiquidationMBZoneIsHolding<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, zoneIsHolding);
    if (error != ERR_NO_ERROR || !zoneIsHolding)
    {
        InvalidateSetup(true, error);
        return;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (mSetupType == OP_BUY)
    {
        // invalidate if we broke below our candle zone with a body
        if (MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, 1), iClose(mEntrySymbol, mEntryTimeFrame, 1)) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // invalidate if we broke above our candle zone with a body
        if (MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, 1), iClose(mEntrySymbol, mEntryTimeFrame, 1)) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void LiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::ResetLiquidationMBSetup<LiquidationMB>(this, false);
    EAHelper::InvalidateSetup<LiquidationMB>(this, deletePendingOrder, false, error);
}

bool LiquidationMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    if (mSetupMBT.MBsCreated() - 1 != mMostRecentMB)
    {
        InvalidateSetup(true);
        return false;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);

    // make sure we actually had a decent push up after the inital break
    if (zoneCandleIndex < 5)
    {
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        bool pushedUpAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bearish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1))
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
        if (iLow(mEntrySymbol, mEntryTimeFrame, 2) < iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        bool pushedDownAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bullish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1))
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
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 2) > iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }

    return hasTicket;
}

void LiquidationMB::PlaceOrders()
{
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
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2), iLow(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);

        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips), entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<LiquidationMB>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void LiquidationMB::ManageCurrentPendingSetupTicket()
{
    mBrokeEntryIndex = false;

    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mSetupType == OP_BUY && entryCandleIndex > 1)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL && entryCandleIndex > 1)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void LiquidationMB::ManageCurrentActiveSetupTicket()
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

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        if (!mBrokeEntryIndex)
        {
            for (int i = entryIndex - 1; i >= 0; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
                {
                    mBrokeEntryIndex = true;
                }
            }
        }

        if (mBrokeEntryIndex && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // get too close to our entry after 10 candles and coming back
        if (entryIndex >= 10)
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
        if (!mBrokeEntryIndex)
        {
            for (int i = entryIndex - 1; i >= 0; i--)
            {
                // change to any break lower within our entry
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
                {
                    mBrokeEntryIndex = true;
                }
            }
        }

        if (mBrokeEntryIndex && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // get too close to our entry after 10 candles and coming back
        if (entryIndex >= 10)
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<LiquidationMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool LiquidationMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LiquidationMB>(this, ticket);
}

void LiquidationMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<LiquidationMB>(this, mPreviousSetupTickets[ticketIndex]);
}

void LiquidationMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<LiquidationMB>(this);
}

void LiquidationMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<LiquidationMB>(this, ticketIndex);
}

void LiquidationMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LiquidationMB>(this);
}

void LiquidationMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LiquidationMB>(this, partialedTicket, newTicketNumber);
}

void LiquidationMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LiquidationMB>(this, ticket, mEntryTimeFrame);
}

void LiquidationMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LiquidationMB>(this, error, additionalInformation);
}

void LiquidationMB::Reset()
{
}