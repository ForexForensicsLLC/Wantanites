//+------------------------------------------------------------------+
//|                                                    TinyMBOutsideSecond.mqh |
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

class TinyMBOutsideSecond : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

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
    TinyMBOutsideSecond(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TinyMBOutsideSecond();

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

TinyMBOutsideSecond::TinyMBOutsideSecond(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mMinMBRatio = 0.0;
    mMaxMBRatio = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TinyMBOutsideSecond>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TinyMBOutsideSecond, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TinyMBOutsideSecond, MultiTimeFrameEntryTradeRecord>(this);

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

TinyMBOutsideSecond::~TinyMBOutsideSecond()
{
}

double TinyMBOutsideSecond::RiskPercent()
{
    return mRiskPercent;
}

void TinyMBOutsideSecond::Run()
{
    EAHelper::RunDrawMBT<TinyMBOutsideSecond>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool TinyMBOutsideSecond::AllowedToTrade()
{
    return EAHelper::BelowSpread<TinyMBOutsideSecond>(this) && EAHelper::WithinTradingSession<TinyMBOutsideSecond>(this);
}

void TinyMBOutsideSecond::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupMBT.HasNMostRecentConsecutiveMBs(3) &&
        mSetupMBT.GetNthMostRecentMBsType(0) == mSetupType)
    {
        mHasSetup = true;
        mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;
    }
}

void TinyMBOutsideSecond::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
    }

    // MBState *tempMBState;
    // if (!mSetupMBT.GetMB(mSecondMBInSetupNumber, tempMBState))
    // {
    //     InvalidateSetup(true);
    //     return;
    // }

    // int pendingMBStart = EMPTY;
    // double furthestPoint = 0.0;
    // double height = 0.0;

    // if (mSetupType == OP_BUY)
    // {
    //     if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }

    //     if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }

    //     if (furthestPoint < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }

    //     height = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - furthestPoint;
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }

    //     if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }

    //     if (furthestPoint > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }

    //     height = furthestPoint - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
    // }

    // if (height > OrderHelper::PipsToRange(mMaxMBHeight))
    // {
    //     InvalidateSetup(true);
    // }
}

void TinyMBOutsideSecond::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<TinyMBOutsideSecond>(this, deletePendingOrder, false, error);

    mFirstMBInSetupNumber = EMPTY;
}

bool TinyMBOutsideSecond::Confirmation()
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

    MBState *previousMBState;
    if (!mSetupMBT.GetPreviousMB(mFirstMBInSetupNumber, previousMBState))
    {
        return false;
    }

    int pendingMBStart = EMPTY;
    double furthestPoint = 0.0;
    double height = 0.0;

    if (mSetupType == OP_BUY)
    {
        // if (!mSetupMBT.HasPendingBullishMB())
        // {
        //     return false;
        // }

        // if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        // {
        //     return false;
        // }

        // if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint))
        // {
        //     return false;
        // }

        // if (furthestPoint < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        // {
        //     return false;
        // }

        // height = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - furthestPoint;

        if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) < iHigh(mEntrySymbol, mEntryTimeFrame, previousMBState.HighIndex()))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // if (!mSetupMBT.HasPendingBearishMB())
        // {
        //     return false;
        // }

        // if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        // {
        //     return false;
        // }

        // if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint))
        // {
        //     return false;
        // }

        // if (furthestPoint > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        // {
        //     return false;
        // }

        // height = furthestPoint - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);

        if (iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) > iLow(mEntrySymbol, mEntryTimeFrame, previousMBState.LowIndex()))
        {
            return false;
        }
    }

    if (tempMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight))
    {
        return false;
    }

    if (tempMBState.EndIndex() > 1)
    {
        return false;
    }

    return true;
}

void TinyMBOutsideSecond::PlaceOrders()
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

    int pendingMBStart = EMPTY;
    double entry = 0.0;
    double stopLoss = 0.0;
    double furthestPoint = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (currentTick.ask - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) > OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            return;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint))
        {
            return;
        }

        entry = currentTick.ask;
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) + OrderHelper::PipsToRange(mEntryPaddingPips);
        // stopLoss = furthestPoint - OrderHelper::PipsToRange(mStopLossPaddingPips);
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        // stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2) - OrderHelper::PipsToRange(mStopLossPaddingPips),
        //                    iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()));

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
        if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - currentTick.bid > OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            return;
        }

        entry = currentTick.bid;
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());
        // if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        // {
        //     return;
        // }

        // if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint))
        // {
        //     return;
        // }

        // entry = iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - OrderHelper::PipsToRange(mEntryPaddingPips);
        // stopLoss = furthestPoint + OrderHelper::PipsToRange(mStopLossPaddingPips);

        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        // stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips),
        //                    iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()));

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

    // EAHelper::PlaceStopOrder<TinyMBOutsideSecond>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);
    EAHelper::PlaceMarketOrder<TinyMBOutsideSecond>(this, entry, stopLoss);

    InvalidateSetup(false);
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
        mClosedOutsideEntry = false;
    }
}

void TinyMBOutsideSecond::ManageCurrentPendingSetupTicket()
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

    // if (mSetupType == OP_BUY)
    // {
    //     if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
}

void TinyMBOutsideSecond::ManageCurrentActiveSetupTicket()
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
        // double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        // if (percentIntoSL >= 0.2)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

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
        // double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        // if (percentIntoSL >= 0.2)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

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
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<TinyMBOutsideSecond>(this, mBEAdditionalPips);
    // }

    if (movedPips /*|| mEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TinyMBOutsideSecond>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<TinyMBOutsideSecond>(this, mCurrentSetupTicket);
}

bool TinyMBOutsideSecond::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TinyMBOutsideSecond>(this, ticket);
}

void TinyMBOutsideSecond::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<TinyMBOutsideSecond>(this, mPreviousSetupTickets[ticketIndex]);
}

void TinyMBOutsideSecond::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TinyMBOutsideSecond>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TinyMBOutsideSecond>(this);
}

void TinyMBOutsideSecond::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TinyMBOutsideSecond>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TinyMBOutsideSecond>(this, ticketIndex);
}

void TinyMBOutsideSecond::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TinyMBOutsideSecond>(this);
}

void TinyMBOutsideSecond::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TinyMBOutsideSecond>(this, partialedTicket, newTicketNumber);
}

void TinyMBOutsideSecond::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TinyMBOutsideSecond>(this, ticket, Period());
}

void TinyMBOutsideSecond::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TinyMBOutsideSecond>(this, error, additionalInformation);
}

void TinyMBOutsideSecond::Reset()
{
}