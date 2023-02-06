//+------------------------------------------------------------------+
//|                                        WickEntryLiquidationMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\EA\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>

class WickEntryLiquidationMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    WickEntryLiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, LiquidationSetupTracker *&lst);
    ~WickEntryLiquidationMB();

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
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();

    double EMA(int index);
};

WickEntryLiquidationMB::WickEntryLiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<WickEntryLiquidationMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<WickEntryLiquidationMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<WickEntryLiquidationMB, MultiTimeFrameEntryTradeRecord>(this);
}

double WickEntryLiquidationMB::EMA(int index)
{
    return iMA(mEntrySymbol, mEntryTimeFrame, 100, 0, MODE_EMA, PRICE_CLOSE, index);
}

WickEntryLiquidationMB::~WickEntryLiquidationMB()
{
}

void WickEntryLiquidationMB::Run()
{
    EAHelper::RunDrawMBT<WickEntryLiquidationMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool WickEntryLiquidationMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<WickEntryLiquidationMB>(this) && EAHelper::WithinTradingSession<WickEntryLiquidationMB>(this);
}

void WickEntryLiquidationMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetLiquidationMBSetup<WickEntryLiquidationMB>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        MBState *firstMBInSetup;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBInSetup))
        {
            return;
        }

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
            double firstMBLow = CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.LowIndex());
            double firstMBEMA = EMA(firstMBInSetup.LowIndex());
            if (firstMBLow < firstMBEMA)
            {
                return;
            }

            // make sure second mb is above ema
            double secondMBLow = CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, secondMBInSetup.LowIndex());
            double secondMBEMA = EMA(secondMBInSetup.LowIndex());
            if (secondMBLow < secondMBEMA)
            {
                return;
            }

            // make sure liq mb is above ema
            double liqMBLow = CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, liquidationMBInSetup.LowIndex());
            double liqMBEMA = EMA(liquidationMBInSetup.LowIndex());
            if (liqMBLow < liqMBEMA)
            {
                return;
            }

            mHasSetup = true;
        }
        else if (mSetupType == OP_SELL)
        {
            // make sure first mb is below ema
            double firstMBHigh = CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.HighIndex());
            double firstMBEMA = EMA(firstMBInSetup.HighIndex());
            if (firstMBHigh > firstMBEMA)
            {
                return;
            }

            // make sure second mb is below ema
            double secondMBHigh = CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, secondMBInSetup.HighIndex());
            double secondMBEMA = EMA(secondMBInSetup.HighIndex());
            if (secondMBHigh > secondMBEMA)
            {
                return;
            }

            // make sure third mb is below ema
            double liqMBHigh = CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, liquidationMBInSetup.HighIndex());
            double liqMBEMA = EMA(liquidationMBInSetup.HighIndex());
            if (liqMBHigh > liqMBEMA)
            {
                return;
            }

            mHasSetup = true;
        }
    }
}

void WickEntryLiquidationMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<WickEntryLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        InvalidateSetup(true);
        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<WickEntryLiquidationMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        InvalidateSetup(false);
        return;
    }

    if (mHasSetup)
    {
        if (mSetupType == OP_BUY)
        {
            if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) < EMA(1))
            {
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) > EMA(1))
            {
                InvalidateSetup(true);
            }
        }
    }
}

void WickEntryLiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::ResetLiquidationMBSetup<WickEntryLiquidationMB>(this, false);
    EAHelper::InvalidateSetup<WickEntryLiquidationMB>(this, deletePendingOrder, false, error);
}

bool WickEntryLiquidationMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    MBState *liquidationMBState;
    if (!mSetupMBT.GetMB(mLiquidationMBInSetupNumber, liquidationMBState))
    {
        return false;
    }

    bool dojiInLiquidationSetupZone =
        EAHelper::DojiInsideLiquidationSetupMBsHoldingZone<WickEntryLiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber);

    int furthestIndex = EMPTY;
    if (mSetupType == OP_BUY)
    {
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, liquidationMBState.EndIndex(), 1, true, furthestIndex))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, liquidationMBState.EndIndex(), 1, true, furthestIndex))
        {
            return false;
        }
    }

    return hasTicket || (furthestIndex < 3 && dojiInLiquidationSetupZone);
}

void WickEntryLiquidationMB::PlaceOrders()
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

    EAHelper::PlaceStopOrder<WickEntryLiquidationMB>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void WickEntryLiquidationMB::ManageCurrentPendingSetupTicket()
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

void WickEntryLiquidationMB::ManageCurrentActiveSetupTicket()
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
        // if (!mBrokeEntryIndex)
        // {
        //     for (int i = entryIndex - 1; i >= 0; i--)
        //     {
        //         if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
        //         {
        //             mBrokeEntryIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeEntryIndex && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // // get too close to our entry after 10 candles and coming back
        // if (entryIndex >= 10)
        // {
        //     if (mLastManagedBid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips) &&
        //         currentTick.bid <= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // if (!mBrokeEntryIndex)
        // {
        //     for (int i = entryIndex - 1; i >= 0; i--)
        //     {
        //         // change to any break lower within our entry
        //         if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
        //         {
        //             mBrokeEntryIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeEntryIndex && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // // get too close to our entry after 10 candles and coming back
        // if (entryIndex >= 10)
        // {
        //     if (mLastManagedAsk < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips) &&
        //         currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<WickEntryLiquidationMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool WickEntryLiquidationMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<WickEntryLiquidationMB>(this, ticket);
}

void WickEntryLiquidationMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<WickEntryLiquidationMB>(this, ticketIndex);
}

void WickEntryLiquidationMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<WickEntryLiquidationMB>(this);
}

void WickEntryLiquidationMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<WickEntryLiquidationMB>(this, ticketIndex);
}

void WickEntryLiquidationMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<WickEntryLiquidationMB>(this);
}

void WickEntryLiquidationMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickEntryLiquidationMB>(this, oldTicketIndex, newTicketNumber);
}

void WickEntryLiquidationMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<WickEntryLiquidationMB>(this, ticket, mEntryTimeFrame);
}

void WickEntryLiquidationMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<WickEntryLiquidationMB>(this, error, additionalInformation);
}

void WickEntryLiquidationMB::Reset()
{
}