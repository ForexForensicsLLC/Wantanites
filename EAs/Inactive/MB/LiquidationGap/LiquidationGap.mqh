//+------------------------------------------------------------------+
//|                                                    LiquidationGap.mqh |
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

class LiquidationGap : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    double mMinMBGap;

    double mMinMBRatio;
    double mMaxMBRatio;

    double mMinMBHeight;
    double mMaxMBHeight;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mEntryZone;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    LiquidationGap(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~LiquidationGap();

    double EMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 100, 0, MODE_EMA, PRICE_CLOSE, index); }
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

LiquidationGap::LiquidationGap(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mMinMBGap = 0.0;

    mMinMBRatio = 0.0;
    mMaxMBRatio = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LiquidationGap>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LiquidationGap, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LiquidationGap, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryZone = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

LiquidationGap::~LiquidationGap()
{
}

double LiquidationGap::RiskPercent()
{
    return mRiskPercent;
}

void LiquidationGap::Run()
{
    EAHelper::RunDrawMBT<LiquidationGap>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool LiquidationGap::AllowedToTrade()
{
    return EAHelper::BelowSpread<LiquidationGap>(this) && EAHelper::WithinTradingSession<LiquidationGap>(this);
}

void LiquidationGap::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    for (int i = 3; i <= 5; i++)
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetNthMostRecentMB(i, tempMBState))
        {
            continue;
        }

        if (tempMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight))
        {
            return;
        }

        if (tempMBState.Type() != mSetupType)
        {
            continue;
        }

        if (tempMBState.GlobalStartIsBroken())
        {
            continue;
        }

        MBState *subsequentMBState;
        if (!mSetupMBT.GetSubsequentMB(tempMBState.Number(), subsequentMBState))
        {
            continue;
        }

        double gap = 0.0;
        bool hasLiquidationMB = false;
        if (mSetupType == OP_BUY)
        {
            gap = iLow(mEntrySymbol, mEntryTimeFrame, subsequentMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());

            for (int j = tempMBState.Number(); j < mSetupMBT.MBsCreated() - 1; j++)
            {
                MBState *liquidationMBState;
                if (!mSetupMBT.GetMB(j, liquidationMBState))
                {
                    continue;
                }

                if (liquidationMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight))
                {
                    return;
                }

                if (liquidationMBState.Type() == OP_SELL && !liquidationMBState.GlobalStartIsBroken())
                {
                    hasLiquidationMB = true;
                    mLiquidationMBInSetupNumber = liquidationMBState.Number();

                    break;
                }
            }
        }
        else if (mSetupType == OP_SELL)
        {
            gap = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, subsequentMBState.HighIndex());

            for (int j = tempMBState.Number(); j < mSetupMBT.MBsCreated() - 1; j++)
            {
                MBState *liquidationMBState;
                if (!mSetupMBT.GetMB(j, liquidationMBState))
                {
                    continue;
                }

                if (liquidationMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight))
                {
                    return;
                }

                if (liquidationMBState.Type() == OP_BUY && !liquidationMBState.GlobalStartIsBroken())
                {
                    hasLiquidationMB = true;
                    mLiquidationMBInSetupNumber = liquidationMBState.Number();

                    break;
                }
            }
        }

        if (gap < OrderHelper::PipsToRange(mMinMBGap))
        {
            continue;
        }

        if (hasLiquidationMB)
        {
            mFirstMBInSetupNumber = tempMBState.Number();
            mHasSetup = true;

            return;
        }
        else
        {
            mLiquidationMBInSetupNumber = EMPTY;
        }
    }
}

void LiquidationGap::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            InvalidateSetup(true);
            return;
        }

        if (tempMBState.GlobalStartIsBroken())
        {
            InvalidateSetup(true);
            return;
        }
    }

    if (mLiquidationMBInSetupNumber != EMPTY)
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mLiquidationMBInSetupNumber, tempMBState))
        {
            InvalidateSetup(true);
            return;
        }

        if (tempMBState.GlobalStartIsBroken())
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void LiquidationGap::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<LiquidationGap>(this, deletePendingOrder, false, error);

    mFirstMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;
}

bool LiquidationGap::Confirmation()
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

    MBState *liquidationMBState;
    if (!mSetupMBT.GetMB(mLiquidationMBInSetupNumber, liquidationMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetClosestValidZone(tempZoneState))
    {
        return false;
    }

    if (!tempZoneState.IsHolding(liquidationMBState.EndIndex()))
    {
        return false;
    }

    int dojiCandleIndex = 1;
    bool dojiInZone = false;
    if (tempMBState.Type() == OP_BUY)
    {
        double low = iLow(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex);
        double bodyLow = MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex), iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex));
        dojiInZone = SetupHelper::HammerCandleStickPattern(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex) &&
                     (low <= tempZoneState.EntryPrice() && bodyLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        double high = iHigh(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex);
        double bodyHigh = MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex), iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex));
        dojiInZone = SetupHelper::ShootingStarCandleStickPattern(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex) &&
                     (high >= tempZoneState.EntryPrice() && bodyHigh <= tempZoneState.ExitPrice());
    }

    return dojiInZone;
}

void LiquidationGap::PlaceOrders()
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

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        // double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2), iLow(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        // double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<LiquidationGap>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryZone = tempZoneState.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
    }
}

void LiquidationGap::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    // if (entryCandleIndex > 1)
    // {
    //     InvalidateSetup(true);
    //     return;
    // }

    if (mSetupType == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void LiquidationGap::ManageCurrentActiveSetupTicket()
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

    bool movedPips = false;
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    if (mSetupType == OP_BUY)
    {
        if (orderPlaceIndex > 1)
        {
            // close if we fail to break with a body
            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
            //     currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            // {
            //     mCurrentSetupTicket.Close();
            // }

            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
            // {
            //     mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            // }

            // // close if we put in a bearish candle
            // if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
            // {
            //     mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            // }
        }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double lowest = 0.0;
        //     if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        if (orderPlaceIndex > 1)
        {
            // close if we fail to break with a body
            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
            //     currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            // {
            //     mCurrentSetupTicket.Close();
            //     return;
            // }

            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
            // {
            //     mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            // }

            // // close if we put in a bullish candle
            // if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
            // {
            //     mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            // }
        }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double highest = 0.0;
        //     if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // BE after we validate the MB we entered in
    // if (mSetupMBT.MBsCreated() - 1 != mEntryMB)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<LiquidationGap>(this, mBEAdditionalPips);
    // }

    if (movedPips /*|| mEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<LiquidationGap>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<LiquidationGap>(this, mCurrentSetupTicket);
}

bool LiquidationGap::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LiquidationGap>(this, ticket);
}

void LiquidationGap::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<LiquidationGap>(this, mPreviousSetupTickets[ticketIndex]);
}

void LiquidationGap::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LiquidationGap>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<LiquidationGap>(this);
}

void LiquidationGap::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LiquidationGap>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<LiquidationGap>(this, ticketIndex);
}

void LiquidationGap::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LiquidationGap>(this);
}

void LiquidationGap::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LiquidationGap>(this, partialedTicket, newTicketNumber);
}

void LiquidationGap::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LiquidationGap>(this, ticket, Period());
}

void LiquidationGap::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LiquidationGap>(this, error, additionalInformation);
}

void LiquidationGap::Reset()
{
}