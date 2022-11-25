//+------------------------------------------------------------------+
//|                                                    WickLiquidatedMB.mqh |
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

class WickLiquidatedMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    bool mHasLiquidatedMB;
    datetime mLiquidatedMBCandleTime;
    datetime mFirstOppositeCandleTime;

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

    double EMA(int index);
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
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

double WickLiquidatedMB::EMA(int index)
{
    return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index);
}

WickLiquidatedMB::WickLiquidatedMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mHasLiquidatedMB = false;
    mLiquidatedMBCandleTime = 0;
    mFirstOppositeCandleTime = 0;

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

    if (!mHasLiquidatedMB)
    {
        if (EAHelper::CheckSetSingleMBSetup<WickLiquidatedMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
        {
            MBState *tempMBState;
            if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
            {
                return;
            }

            int liquidatedCandleIndex = 1;
            bool hasWickLiquidatedMB = false;
            int retracement = EMPTY;
            int furthestIndex = EMPTY;
            if (mSetupType == OP_BUY)
            {
                if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(retracement))
                {
                    return;
                }

                if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, retracement, 0, false, furthestIndex))
                {
                    return;
                }

                double mbLow = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());
                mHasLiquidatedMB = CandleStickHelper::GetLowestBodyPart(mEntrySymbol, mEntryTimeFrame, liquidatedCandleIndex) > mbLow &&
                                   iLow(mEntrySymbol, mEntryTimeFrame, liquidatedCandleIndex) < mbLow &&
                                   iClose(mEntrySymbol, mEntryTimeFrame, liquidatedCandleIndex) > mbLow;
            }
            else if (mSetupType == OP_SELL)
            {
                if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(retracement))
                {
                    return;
                }

                if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, retracement, 0, false, furthestIndex))
                {
                    return;
                }

                double mbHigh = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());
                mHasLiquidatedMB = CandleStickHelper::GetHighestBodyPart(mEntrySymbol, mEntryTimeFrame, liquidatedCandleIndex) < mbHigh &&
                                   iHigh(mEntrySymbol, mEntryTimeFrame, liquidatedCandleIndex) > mbHigh &&
                                   iClose(mEntrySymbol, mEntryTimeFrame, liquidatedCandleIndex) < mbHigh;
            }

            if (retracement - furthestIndex < 15 || tempMBState.Width() < 15 || tempMBState.Height() < OrderHelper::PipsToRange(500))
            {
                mHasLiquidatedMB = false;
                return;
            }

            if (mHasLiquidatedMB)
            {
                mLiquidatedMBCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
            }
        }
    }

    if (mHasLiquidatedMB)
    {
        if (EAHelper::RunningBigDipperSetup<WickLiquidatedMB>(this, mLiquidatedMBCandleTime))
        {
            mHasSetup = true;
        }
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

    if (mLiquidatedMBCandleTime > 0)
    {
        int liquidatedMBCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLiquidatedMBCandleTime);
        if (mSetupType == OP_BUY)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, liquidatedMBCandleIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, liquidatedMBCandleIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }

    if (mFirstOppositeCandleTime > 0)
    {
        int oppositeCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFirstOppositeCandleTime);
        if (mSetupType == OP_BUY)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, oppositeCandleIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, oppositeCandleIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }
        }
    }
}

void WickLiquidatedMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<WickLiquidatedMB>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<WickLiquidatedMB>(this, false);

    mHasLiquidatedMB = false;
    mLiquidatedMBCandleTime = 0;
    mFirstOppositeCandleTime = 0;
}

bool WickLiquidatedMB::Confirmation()
{
    return true;
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
        // double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        // stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<WickLiquidatedMB>(this, currentTick.ask, stopLoss);
        }
        else if (entry > currentTick.ask)
        {
            EAHelper::PlaceStopOrder<WickLiquidatedMB>(this, entry, stopLoss);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        // stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
        //                    entry + OrderHelper::PipsToRange(mMinStopLossPips));
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
        if (entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<WickLiquidatedMB>(this, currentTick.bid, stopLoss);
        }
        else if (entry < currentTick.bid)
        {
            EAHelper::PlaceStopOrder<WickLiquidatedMB>(this, entry, stopLoss);
        }
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
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
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void WickLiquidatedMB::ManageCurrentActiveSetupTicket()
{
    if (mFirstMBInSetupNumber != EMPTY && mLastEntryMB != mFirstMBInSetupNumber)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
    }

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

    // if (mSetupType == OP_BUY)
    // {
    //     if (orderPlaceIndex > 1)
    //     {
    //         // close if we fail to break with a body
    //         if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
    //             currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //         }

    //         // close if we put in a bearish candle
    //         if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (orderPlaceIndex > 3)
    //     {
    //         // close if we are still opening within our entry and get the chance to close at BE
    //         if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (mFailedImpulseEntryTime != 0)
    //     {
    //         int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
    //         double lowest = 0.0;
    //         if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
    //         {
    //             return;
    //         }

    //         // only close if we crossed our entry price after failing to run and then we go a bit in profit
    //         if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //         }
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (orderPlaceIndex > 1)
    //     {
    //         // close if we fail to break with a body
    //         if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
    //             currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //             return;
    //         }

    //         // close if we put in a bullish candle
    //         if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (orderPlaceIndex > 3)
    //     {
    //         // close if we are still opening above our entry and we get the chance to close at BE
    //         if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (mFailedImpulseEntryTime != 0)
    //     {
    //         int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
    //         double highest = 0.0;
    //         if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
    //         {
    //             return;
    //         }

    //         // only close if we crossed our entry price after failing to run and then we go a bit in profit
    //         if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //         }
    //     }
    // }

    // BE after we validate the MB we entered in
    if (mSetupMBT.MBsCreated() - 1 != mLastEntryMB || entryIndex > 3)
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
    EAHelper::CheckPartialPreviousSetupTicket<WickLiquidatedMB>(this, ticketIndex);
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

void WickLiquidatedMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickLiquidatedMB>(this, oldTicketIndex, newTicketNumber);
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