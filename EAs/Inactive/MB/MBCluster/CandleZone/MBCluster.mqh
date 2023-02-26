//+------------------------------------------------------------------+
//|                                        MBCluster.mqh |
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

class MBCluster : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

    string mEntrySymbol;
    int mEntryTimeFrame;

    double mMaxZoneBreakagePips;

    int mBarCount;
    int mLastEntryMB;

    datetime mZoneCandleTime;
    datetime mEntryCandleTime;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

public:
    MBCluster(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBCluster();

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
};

MBCluster::MBCluster(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mMaxZoneBreakagePips = 0.0;
    mBarCount = 0;
    mLastEntryMB = EMPTY;

    mZoneCandleTime = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBCluster>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBCluster, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBCluster, SingleTimeFrameEntryTradeRecord>(this);
}

MBCluster::~MBCluster()
{
}

void MBCluster::Run()
{
    EAHelper::RunDrawMBT<MBCluster>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MBCluster::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBCluster>(this) && EAHelper::WithinTradingSession<MBCluster>(this);
}

void MBCluster::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupMBT.MBsCreated() - 1 == mLastEntryMB)
    {
        return;
    }

    if (EAHelper::CheckSetDoubleMBSetup<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mSetupType))
    {
        MBState *firstMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBState))
        {
            return;
        }

        if (!firstMBState.ClosestValidZoneIsHolding(firstMBState.EndIndex() - 1))
        {
            return;
        }

        MBState *secondMBState;
        if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, secondMBState))
        {
            return;
        }

        if (!secondMBState.ClosestValidZoneIsHolding(secondMBState.EndIndex() - 1))
        {
            return;
        }

        if (firstMBState.EndIndex() - secondMBState.StartIndex() > 2)
        {
            return;
        }

        double firstSecondHeightRatio = firstMBState.Height() / secondMBState.Height();
        if (firstSecondHeightRatio < 0.5 || firstSecondHeightRatio > 1.8)
        {
            return;
        }

        int pendingMBStart = EMPTY;
        double pendingMBHeight = 0.0;

        if (mSetupType == OP_BUY)
        {
            if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
            {
                return;
            }

            if (secondMBState.EndIndex() - pendingMBStart > 2)
            {
                return;
            }

            int lowestIndex = EMPTY;
            if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, secondMBState.EndIndex() - 1, 1, true, lowestIndex))
            {
                return;
            }

            pendingMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iLow(mEntrySymbol, mEntryTimeFrame, lowestIndex);
            double secondPendingHeightRatio = secondMBState.Height() / pendingMBHeight;
            if (secondPendingHeightRatio < 0.5 || secondPendingHeightRatio > 1.8)
            {
                return;
            }

            // need to break within 3 candles of our lowest
            if (lowestIndex > 3)
            {
                return;
            }

            // make sure we broke above
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
            {
                return;
            }

            mHasSetup = true;
            mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
        }
        else if (mSetupType == OP_SELL)
        {
            if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
            {
                return;
            }

            if (secondMBState.EndIndex() - pendingMBStart > 2)
            {
                return;
            }

            int highestIndex = EMPTY;
            if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, secondMBState.EndIndex() - 1, 1, true, highestIndex))
            {
                return;
            }

            pendingMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, highestIndex) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
            double secondPendingHeightRatio = secondMBState.Height() / pendingMBHeight;
            if (secondPendingHeightRatio < 0.5 || secondPendingHeightRatio > 1.8)
            {
                return;
            }

            // need to break within 3 candles of our highest
            if (highestIndex > 3)
            {
                return;
            }

            // make sure we broke below a candle
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
            {
                return;
            }

            mHasSetup = true;
            mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
        }
    }
}

void MBCluster::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSecondMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (!EAHelper::MostRecentMBZoneIsHolding<MBCluster>(this, mSetupMBT, mSecondMBInSetupNumber))
    {
        InvalidateSetup(true);
        return;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (mSetupType == OP_BUY)
    {
        // invalidate if we broke below our candle zone with a body
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) - OrderHelper::PipsToRange(mMaxZoneBreakagePips))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // invalidate if we broke above our candle zone with a body
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) + OrderHelper::PipsToRange(mMaxZoneBreakagePips))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void MBCluster::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBCluster>(this, deletePendingOrder, false, error);

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mZoneCandleTime = 0;
}

bool MBCluster::Confirmation()
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

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);

    // make sure we actually had a decent push up after the inital break
    if (zoneCandleIndex < 3)
    {
        return false;
    }

    bool hasValidOppositePushStart = false;
    bool hasValidOppositePush = false;

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            return false;
        }

        for (int i = zoneCandleIndex - 1; i >= 0; i--)
        {
            // need to have a bearish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (!hasValidOppositePushStart &&
                CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1))
            {
                hasValidOppositePushStart = true;
            }

            if (hasValidOppositePushStart &&
                CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i + 2))
            {
                hasValidOppositePush = true;
            }
        }

        if (!hasValidOppositePush)
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            return false;
        }

        for (int i = zoneCandleIndex - 1; i >= 0; i--)
        {
            // need to have a bullish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (!hasValidOppositePushStart &&
                CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1))
            {
                hasValidOppositePushStart = true;
            }

            if (hasValidOppositePushStart &&
                CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i + 2))
            {
                hasValidOppositePush = true;
            }
        }

        if (!hasValidOppositePush)
        {
            return false;
        }
    }

    return true;
}

void MBCluster::PlaceOrders()
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

    EAHelper::PlaceStopOrder<MBCluster>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void MBCluster::ManageCurrentPendingSetupTicket()
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

    if (mSetupType == OP_BUY && entryCandleIndex > 1)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
            // InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL && entryCandleIndex > 1)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
            // InvalidateSetup(true);
        }
    }
}

void MBCluster::ManageCurrentActiveSetupTicket()
{
    if (mLastEntryMB != mFirstMBInSetupNumber && mFirstMBInSetupNumber != EMPTY)
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

    if (EAHelper::CloseIfPercentIntoStopLoss<MBCluster>(this, mCurrentSetupTicket, 0.5))
    {
        return;
    }

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBCluster>(this, mBEAdditionalPips);
    }
}

bool MBCluster::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBCluster>(this, ticket);
}

void MBCluster::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MBCluster>(this, mPreviousSetupTickets[ticketIndex]);
}

void MBCluster::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<MBCluster>(this);
}

void MBCluster::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<MBCluster>(this, ticketIndex);
}

void MBCluster::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBCluster>(this);
}

void MBCluster::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBCluster>(this, partialedTicket, newTicketNumber);
}

void MBCluster::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBCluster>(this, ticket, mEntryTimeFrame);
}

void MBCluster::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBCluster>(this, error, additionalInformation);
}

void MBCluster::Reset()
{
}