//+------------------------------------------------------------------+
//|                                                    MBCluster.mqh |
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

class MBCluster : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mThirdMBInSetupNumber;

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
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MBCluster(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBCluster();

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

MBCluster::MBCluster(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mThirdMBInSetupNumber = EMPTY;

    mMinMBRatio = 0.0;
    mMaxMBRatio = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBCluster>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBCluster, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBCluster, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

MBCluster::~MBCluster()
{
}

double MBCluster::RiskPercent()
{
    return mRiskPercent;
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

    if (EAHelper::CheckSetSingleMBSetup<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.Height() < OrderHelper::PipsToRange(500) || tempMBState.Width() > 50)
        {
            return;
        }

        double maxPercentOfPendingMBOutsideOfPrevious = 0.3;

        int pendingMBStart = EMPTY;
        int furthestIntoMB = EMPTY;
        double height = 0.0;
        double percentOfPendingMB = 0.0;

        if (mSetupType == OP_BUY)
        {
            if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
            {
                return;
            }

            if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestIntoMB))
            {
                return;
            }

            double highestValue = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
            double lowestValue = iLow(mEntrySymbol, mEntryTimeFrame, furthestIntoMB);

            height = highestValue - lowestValue;
            percentOfPendingMB = highestValue - (height * maxPercentOfPendingMBOutsideOfPrevious);
        }
        else if (mSetupType == OP_SELL)
        {
            if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
            {
                return;
            }

            if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestIntoMB))
            {
                return;
            }

            double highestValue = iHigh(mEntrySymbol, mEntryTimeFrame, furthestIntoMB);
            double lowestValue = iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);

            height = highestValue - lowestValue;
            percentOfPendingMB = lowestValue + (height * maxPercentOfPendingMBOutsideOfPrevious);
        }

        // need to start the second one right after the first
        if (tempMBState.EndIndex() - pendingMBStart > 3)
        {
            return;
        }

        // pending mb can't be larger than previous
        if (height > (tempMBState.Height() * 1.2) || pendingMBStart > tempMBState.Width())
        {
            return;
        }

        // pending MB can't be too large
        // if (height > OrderHelper::PipsToRange(1000) || height < OrderHelper::PipsToRange(650) || pendingMBStart > 40)
        // {
        //     return;
        // }

        // TODO: Maybe increase to 70 or 80%
        // pending mb needs to be at least 60% of the height of the mb before it or it has to be 80% into the previous mb
        if (height < tempMBState.Height() * 0.6 ||
            !EAHelper::PriceIsFurtherThanPercentIntoMB<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber, percentOfPendingMB, 0.0))
        {
            return;
        }

        mHasSetup = true;
    }
}

void MBCluster::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        if (mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
        {
            InvalidateSetup(true);
        }
    }

    if (mHasSetup)
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        int pendingMBStart = EMPTY;
        int furthestIntoMB = EMPTY;
        double height = 0.0;

        if (mSetupType == OP_BUY)
        {
            if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
            {
                return;
            }

            if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestIntoMB))
            {
                return;
            }

            double highestValue = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
            double lowestValue = iLow(mEntrySymbol, mEntryTimeFrame, furthestIntoMB);

            height = highestValue - lowestValue;
        }
        else if (mSetupType == OP_SELL)
        {
            if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
            {
                return;
            }

            if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestIntoMB))
            {
                return;
            }

            double highestValue = iHigh(mEntrySymbol, mEntryTimeFrame, furthestIntoMB);
            double lowestValue = iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);

            height = highestValue - lowestValue;
        }

        if (height > tempMBState.Height() || pendingMBStart > tempMBState.Width())
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void MBCluster::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBCluster>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MBCluster>(this, false);
}

bool MBCluster::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    // MqlTick currentTick;
    // if (!SymbolInfoTick(Symbol(), currentTick))
    // {
    //     RecordError(GetLastError());
    //     return false;
    // }

    MBState *firstMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!firstMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    int dojiIndex = 1;
    bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber, dojiIndex);
    if (!dojiInZone)
    {
        return hasTicket;
    }

    int pendingMBStart = EMPTY;
    int zoneStart = tempZoneState.StartIndex() - tempZoneState.EntryOffset();

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.HasPendingBullishMB())
        {
            return false;
        }

        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.HasPendingBearishMB())
        {
            return false;
        }

        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }
    }

    // bool impulse = zoneStart < 15 || pendingMBStart <= 7;

    bool furthestInZone = EAHelper::CandleIsInZone<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber, dojiIndex, true);
    return hasTicket || (furthestInZone);
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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<MBCluster>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
    }
}

void MBCluster::ManageCurrentPendingSetupTicket()
{
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

void MBCluster::ManageCurrentActiveSetupTicket()
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
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }

        //     // close if we put in a bearish candle
        //     if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

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
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     // close if we put in a bullish candle
        //     if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

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
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<MBCluster>(this, mBEAdditionalPips);
    // }

    if (movedPips || mEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBCluster>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<MBCluster>(this, mCurrentSetupTicket);
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
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBCluster>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MBCluster>(this);
}

void MBCluster::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBCluster>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MBCluster>(this, ticketIndex);
}

void MBCluster::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<MBCluster>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void MBCluster::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBCluster>(this, partialedTicket, newTicketNumber);
}

void MBCluster::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBCluster>(this, ticket, Period());
}

void MBCluster::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBCluster>(this, error, additionalInformation);
}

void MBCluster::Reset()
{
}