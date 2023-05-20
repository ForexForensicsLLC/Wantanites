//+------------------------------------------------------------------+
//|                                                    EntryRulesMB.mqh |
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

class EntryRulesMB : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    bool mClosedOutsideEntry;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    EntryRulesMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~EntryRulesMB();

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

EntryRulesMB::EntryRulesMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EntryRulesMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<EntryRulesMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EntryRulesMB, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;
    mClosedOutsideEntry = false;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

EntryRulesMB::~EntryRulesMB()
{
}

double EntryRulesMB::RiskPercent()
{
    return mRiskPercent;
}

void EntryRulesMB::Run()
{
    EAHelper::RunDrawMBT<EntryRulesMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool EntryRulesMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<EntryRulesMB>(this) && EAHelper::WithinTradingSession<EntryRulesMB>(this);
}

void EntryRulesMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight) || tempMBState.Height() < OrderHelper::PipsToRange(mMinMBHeight))
        {
            return;
        }

        if (EAHelper::MBWasCreatedAfterSessionStart<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            mHasSetup = true;
        }
    }
}

void EntryRulesMB::CheckInvalidateSetup()
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
}

void EntryRulesMB::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<EntryRulesMB>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<EntryRulesMB>(this, false);
}

bool EntryRulesMB::Confirmation()
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

    bool furthestCandleInZone = EAHelper::CandleIsInZone<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber, 2, true) ||
                                EAHelper::CandleIsInZone<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber, 1, true);
    if (!furthestCandleInZone)
    {
        return false;
    }

    bool brokeFurther = CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, 1);
    if (!brokeFurther)
    {
        return false;
    }

    // bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber, 1);
    // if (!dojiInZone)
    // {
    //     return false;
    // }

    // MBState *tempMBState;
    // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    // {
    //     return false;
    // }

    // ZoneState *tempZoneState;
    // if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    // {
    //     return false;
    // }

    // int start = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    // if (start < 5)
    // {
    //     return false;
    // }

    int pendingMBStart = EMPTY;
    // bool impulseAway = false;
    // bool impulseBack = false;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        //     for (int i = start - 4; i >= pendingMBStart; i--)
        //     {
        //         if (((iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i + 4)) / iClose(mEntrySymbol, mEntryTimeFrame, i) * 100) >= 0.2)
        //         {
        //             impulseAway = true;
        //             break;
        //         }
        //     }

        //     for (int i = 1; i <= pendingMBStart; i++)
        //     {
        //         if (((iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i + 4)) / iClose(mEntrySymbol, mEntryTimeFrame, i) * 100) <= -0.2)
        //         {
        //             impulseBack = true;
        //             break;
        //         }
        //     }

        // if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex() < OrderHelper::PipsToRange(300)))
        // {
        //     return false;
        // }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        //     for (int i = start - 4; i >= pendingMBStart; i--)
        //     {
        //         if (((iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i + 4)) / iClose(mEntrySymbol, mEntryTimeFrame, i) * 100) <= -0.2)
        //         {
        //             impulseAway = true;
        //             break;
        //         }
        //     }

        //     for (int i = 1; i <= pendingMBStart; i++)
        //     {
        //         if (((iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i + 4)) / iClose(mEntrySymbol, mEntryTimeFrame, i) * 100) >= 0.2)
        //         {
        //             impulseBack = true;
        //             break;
        //         }
        //     }

        // if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex() - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) < OrderHelper::PipsToRange(300)))
        // {
        //     return false;
        // }
    }

    // 0.22, 0.2, 0.35, 0.36
    // int dojiIndex = 1;
    // bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber, dojiIndex);
    // bool furthestInZone = EAHelper::CandleIsInZone<EntryRulesMB>(this, mSetupMBT, mFirstMBInSetupNumber, 2, true);
    // bool brokeFruther = CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, 1);

    // return hasTicket || (brokeFruther && furthestInZone);
    // return impulseAway && impulseBack;
    return true;
}

void EntryRulesMB::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
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

    int pendingMBState = EMPTY;
    double entry = 0.0;
    double stopLoss = 0.0;
    double rrToMBValidation = 0.0;
    double stopLossStart = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBState))
        {
            return;
        }

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2) - OrderHelper::PipsToRange(mStopLossPaddingPips),
                           iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()));

        // double candleLow = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));
        // double mbLow = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());

        // if (candleLow - mbLow <= OrderHelper::PipsToRange(150))
        // {
        //     stopLossStart = MathMin(mbLow, candleLow);
        // }
        // else
        // {
        //     stopLossStart = MathMin(tempZoneState.ExitPrice(), candleLow);
        // }

        // stopLoss = stopLossStart - OrderHelper::PipsToRange(mStopLossPaddingPips);

        // double entryToMBVal = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBState) - entry;
        // if (entryToMBVal <= 0)
        // {
        //     return;
        // }

        // double stopLossRange = entry - stopLoss;
        // if (stopLossRange <= 0)
        // {
        //     return;
        // }

        // rrToMBValidation = entryToMBVal / stopLossRange;
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBState))
        {
            return;
        }

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips),
                           iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()));

        // double candleHigh = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));
        // double mbHigh = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());

        // if (mbHigh - candleHigh <= OrderHelper::PipsToRange(150))
        // {
        //     stopLossStart = MathMax(mbHigh, candleHigh);
        // }
        // else
        // {
        //     stopLossStart = MathMax(tempZoneState.ExitPrice(), candleHigh);
        // }

        // stopLoss = stopLossStart + OrderHelper::PipsToRange(mStopLossPaddingPips);

        // double entryToMBVal = entry - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBState);
        // if (entryToMBVal <= 0)
        // {
        //     return;
        // }

        // double stopLossRange = stopLoss - entry;
        // if (stopLossRange <= 0)
        // {
        //     return;
        // }

        // rrToMBValidation = entryToMBVal / stopLossRange;
    }

    // if (rrToMBValidation < 1)
    // {
    //     return;
    // }

    EAHelper::PlaceStopOrder<EntryRulesMB>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
        mClosedOutsideEntry = false;
    }
}

void EntryRulesMB::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    // if (entryCandleIndex > 1)
    // {
    //     InvalidateSetup(true);
    // }

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

void EntryRulesMB::ManageCurrentActiveSetupTicket()
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

        // close if we pushed 20% into our SL
        double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // // TODO: instead of doing this, just BE
        // if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
        // {
        //     double highestBody = 0.0;
        //     if (!MQLHelper::GetHighestBodyBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 0, true, highestBody))
        //     {
        //         return;
        //     }

        //     if (highestBody > OrderOpenPrice())
        //     {
        //         mClosedOutsideEntry = true;
        //     }
        // }

        // // close if we closed out of our SL but came back
        // if (mClosedOutsideEntry && currentTick.bid <= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
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

        // close if we push 20% into our SL
        double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
        // {
        //     double lowestBody = 0.0;
        //     if (!MQLHelper::GetLowestBodyBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 0, true, lowestBody))
        //     {
        //         return;
        //     }

        //     if (lowestBody < OrderOpenPrice())
        //     {
        //         mClosedOutsideEntry = true;
        //     }
        // }

        // // close if we closed out of our SL but came back
        // if (mClosedOutsideEntry && currentTick.ask >= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // BE after we validate the MB we entered in
    // if (mSetupMBT.MBsCreated() - 1 != mEntryMB)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<EntryRulesMB>(this, mBEAdditionalPips);
    // }

    if (movedPips /*|| mEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<EntryRulesMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<EntryRulesMB>(this, mCurrentSetupTicket);
}

bool EntryRulesMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<EntryRulesMB>(this, ticket);
}

void EntryRulesMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<EntryRulesMB>(this, mPreviousSetupTickets[ticketIndex]);
}

void EntryRulesMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EntryRulesMB>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<EntryRulesMB>(this);
}

void EntryRulesMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EntryRulesMB>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<EntryRulesMB>(this, ticketIndex);
}

void EntryRulesMB::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<EntryRulesMB>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void EntryRulesMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<EntryRulesMB>(this, partialedTicket, newTicketNumber);
}

void EntryRulesMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EntryRulesMB>(this, ticket, Period());
}

void EntryRulesMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EntryRulesMB>(this, error, additionalInformation);
}

void EntryRulesMB::Reset()
{
}