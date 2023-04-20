//+------------------------------------------------------------------+
//|                                                    MBCluster.mqh |
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

class MBCluster : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBCluster();

    double MinHeightDifferencePercent() { return 0.4; }
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

MBCluster::MBCluster(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
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
        MBState *firstMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBState))
        {
            return;
        }

        if (EAHelper::CheckSetSingleMBSetup<MBCluster>(this, mSetupMBT, mSecondMBInSetupNumber, mSetupType))
        {
            if (mSecondMBInSetupNumber != mFirstMBInSetupNumber + 1)
            {
                mSecondMBInSetupNumber = EMPTY;
                return;
            }
            else if (mSecondMBInSetupNumber > mFirstMBInSetupNumber + 1)
            {
                InvalidateSetup(true);
                return;
            }

            ZoneState *tempZoneState;
            if (firstMBState.GetDeepestHoldingZone(tempZoneState))
            {
                bool entryWithinMB = EAHelper::PriceIsFurtherThanPercentIntoMB<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.EntryPrice(), 0);
                if (!entryWithinMB)
                {
                    return;
                }

                if (tempZoneState.StartIndex() >= firstMBState.EndIndex())
                {
                    MBState *secondMBState;
                    if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, secondMBState))
                    {
                        return;
                    }

                    if (firstMBState.EndIndex() - secondMBState.StartIndex() > 1)
                    {
                        return;
                    }

                    if (mSetupType == OP_BUY)
                    {
                        if (iLow(mEntrySymbol, mEntryTimeFrame, secondMBState.LowIndex()) < iLow(mEntrySymbol, mEntryTimeFrame, firstMBState.LowIndex()))
                        {
                            return;
                        }
                    }
                    else if (mSetupType == OP_SELL)
                    {
                        if (iHigh(mEntrySymbol, mEntryTimeFrame, secondMBState.HighIndex()) > iHigh(mEntrySymbol, mEntryTimeFrame, firstMBState.HighIndex()))
                        {
                            return;
                        }
                    }

                    double maxHeight = MathMax(firstMBState.Height(), secondMBState.Height());
                    double minHeight = MathMin(firstMBState.Height(), secondMBState.Height());

                    int maxWidth = MathMax(firstMBState.Width(), secondMBState.Width());
                    int minWidth = MathMin(firstMBState.Width(), secondMBState.Width());

                    bool minHeightWidthPercent = minHeight / maxHeight >= 0.5 && minWidth / maxWidth >= 0.5;
                    bool minPercentIntoPreviousMinHeightPercent = minHeight / maxHeight >= 0.3 && secondMBState.Width() < 1.5 * firstMBState.Width() &&
                                                                  EAHelper::PriceIsFurtherThanPercentIntoMB<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber,
                                                                                                                       secondMBState.PercentOfMBPrice(0.3), 0);

                    if (minHeightWidthPercent || minPercentIntoPreviousMinHeightPercent)
                    {
                        mHasSetup = true;
                    }
                }
            }
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

    if (mFirstMBInSetupNumber != EMPTY)
    {
        if (mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 2)
        {
            InvalidateSetup(true);
        }

        MBState *firstMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBState))
        {
            return;
        }

        ZoneState *tempZoneState;

        if (!firstMBState.GetDeepestHoldingZone(tempZoneState))
        {
            InvalidateSetup(true);
        }
    }

    if (mSecondMBInSetupNumber != EMPTY && mSecondMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
    }
}

void MBCluster::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<MBCluster>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MBCluster>(this, false);

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mThirdMBInSetupNumber = EMPTY;
}

bool MBCluster::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    MBState *firstMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBState))
    {
        return false;
    }

    MBState *secondMBState;
    if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, secondMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    bool zoneIsHolding = secondMBState.GetDeepestHoldingZone(tempZoneState);
    if (!zoneIsHolding)
    {
        return false;
    }

    bool entryWithinMB = EAHelper::PriceIsFurtherThanPercentIntoMB<MBCluster>(this, mSetupMBT, mSecondMBInSetupNumber, tempZoneState.EntryPrice(), 0);
    if (!entryWithinMB)
    {
        return false;
    }

    int entryCandle = 1;
    bool inZone = EAHelper::CandleIsInZone<MBCluster>(this, mSetupMBT, mSecondMBInSetupNumber, entryCandle, false);
    if (!inZone)
    {
        return hasTicket;
    }

    bool hasDoji = false;
    int hasDojiError = EAHelper::DojiInsideMostRecentMBsHoldingZone<MBCluster>(this, mSetupMBT, mSecondMBInSetupNumber, hasDoji, entryCandle);

    if (tempZoneState.EndIndex() < secondMBState.EndIndex())
    {
        return false;
    }

    bool brokeFurther = false;
    double highest = 0.0;
    double lowest = 0.0;
    double percentOfPendingMB = 0.0;
    int pendingMBWidth = EMPTY;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBWidth))
        {
            return false;
        }

        // this should probably be dependent on the size of the MBs. the large the mb the longer we can wait between them
        if (secondMBState.EndIndex() - pendingMBWidth > 1)
        {
            return false;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, secondMBState.EndIndex(), 0, true, highest))
        {
            return false;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, secondMBState.EndIndex() - 1, 0, true, lowest))
        {
            return false;
        }

        if (lowest < iLow(mEntrySymbol, mEntryTimeFrame, secondMBState.LowIndex()))
        {
            return false;
        }

        percentOfPendingMB = highest - ((highest - lowest) * 0.2);
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBWidth))
        {
            return false;
        }

        // this should probably be dependent on the size of the MBs. the large the mb the longer we can wait between them
        if (secondMBState.EndIndex() - pendingMBWidth > 1)
        {
            return false;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, secondMBState.EndIndex() - 1, 0, true, highest))
        {
            return false;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, secondMBState.EndIndex(), 0, true, lowest))
        {
            return false;
        }

        if (highest > iHigh(mEntrySymbol, mEntryTimeFrame, secondMBState.HighIndex()))
        {
            return false;
        }

        percentOfPendingMB = lowest + ((highest - lowest) * 0.3);
    }

    double pendingMBHeight = highest - lowest;
    double minWidthPercent = 0.3;

    double minHeightBetweenSecond = MathMin(secondMBState.Height(), pendingMBHeight);
    double maxHeightBetweenSecond = MathMax(secondMBState.Height(), pendingMBHeight);

    double minWidthBetweenSecond = MathMin(secondMBState.Width(), pendingMBWidth);
    double maxWidthBetweenSecond = MathMax(secondMBState.Width(), pendingMBWidth);

    double minHeightBetweenFirst = MathMin(firstMBState.Height(), pendingMBHeight);
    double maxHeightBetweenFirst = MathMax(firstMBState.Height(), pendingMBHeight);

    double minWidthBetweenFirst = MathMin(firstMBState.Width(), pendingMBWidth);
    double maxWidthBetweenFisrt = MathMax(firstMBState.Width(), pendingMBWidth);

    bool minHeightWdithPercentBetweenFirst = minHeightBetweenFirst / maxHeightBetweenFirst >= 0.5 && minWidthBetweenFirst / maxWidthBetweenFisrt >= minWidthPercent;
    bool minPercentIntoPreviousMinHeightPercentFirst = minHeightBetweenFirst / maxHeightBetweenFirst >= 0.3 && minWidthBetweenFirst / maxWidthBetweenFisrt >= minWidthPercent &&
                                                       EAHelper::PriceIsFurtherThanPercentIntoMB<MBCluster>(this, mSetupMBT, mFirstMBInSetupNumber,
                                                                                                            percentOfPendingMB, 0);

    bool minHeightWdithPercentBetweenSecond = minHeightBetweenSecond / maxHeightBetweenSecond >= 0.5 && minWidthBetweenSecond / maxWidthBetweenSecond >= minWidthPercent;
    bool minPercentIntoPreviousMinHeightPercentSecond = minHeightBetweenSecond / maxHeightBetweenSecond >= 0.3 && minWidthBetweenFirst / maxWidthBetweenFisrt >= minWidthPercent &&
                                                        EAHelper::PriceIsFurtherThanPercentIntoMB<MBCluster>(this, mSetupMBT, mSecondMBInSetupNumber,
                                                                                                             percentOfPendingMB, 0);

    bool cluster = false;
    if (minHeightWdithPercentBetweenFirst || minPercentIntoPreviousMinHeightPercentFirst || minHeightWdithPercentBetweenSecond || minPercentIntoPreviousMinHeightPercentSecond)
    {
        cluster = true;
    }

    return hasTicket || (zoneIsHolding && hasDoji && cluster);
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
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<MBCluster>(this, currentTick.ask, stopLoss);
        }
        else if (entry > currentTick.ask)
        {
            EAHelper::PlaceStopOrder<MBCluster>(this, entry, stopLoss);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<MBCluster>(this, currentTick.bid, stopLoss);
        }
        else if (entry < currentTick.bid)
        {
            EAHelper::PlaceStopOrder<MBCluster>(this, entry, stopLoss);
        }
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mSecondMBInSetupNumber;
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

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBCluster>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool MBCluster::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBCluster>(this, ticket);
}

void MBCluster::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<MBCluster>(this, ticketIndex);
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
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBCluster>(this);
}

void MBCluster::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBCluster>(this, oldTicketIndex, newTicketNumber);
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