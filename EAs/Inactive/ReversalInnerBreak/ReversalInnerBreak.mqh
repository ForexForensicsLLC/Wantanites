//+------------------------------------------------------------------+
//|                                                    ReversalInnerBreak.mqh |
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

class ReversalInnerBreak : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    bool mEnteredOnSetup;

    double mMinMBPips;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPip;
    double mLargeBodyPips;
    double mPushFurtherPips;

    int mSetupMBsCreated;

    datetime mFirstOppositeCandleTime;
    datetime mSetupCandleStartTime;

    datetime mEntryCandleTime;
    datetime mStopLossCandleTime;
    datetime mBreakCandleTime;
    int mBarCount;
    int mManageCurrentSetupBarCount;
    int mConfirmationBarCount;
    int mSetupBarCount;
    int mCheckInvalidateSetupBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mSetupTimeFrame;
    string mSetupSymbol;

    int mLastEntryMB;
    int mLastEntryZone;

    int mMBCount;
    int mLastDay;
    int mEntryMBNumber;

    double mImbalanceCandlePercentChange;

public:
    ReversalInnerBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ReversalInnerBreak();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }
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

ReversalInnerBreak::ReversalInnerBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mEnteredOnSetup = false;

    mMinMBPips = 0.0;
    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPip = 0.0;
    mLargeBodyPips = 0.0;
    mPushFurtherPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ReversalInnerBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ReversalInnerBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ReversalInnerBreak, MultiTimeFrameEntryTradeRecord>(this);

    mSetupMBsCreated = 0;

    mFirstOppositeCandleTime = 0;
    mSetupCandleStartTime = 0;
    mBreakCandleTime = 0;

    mConfirmationBarCount = 0;
    mBarCount = 0;
    mManageCurrentSetupBarCount = 0;
    mCheckInvalidateSetupBarCount = 0;
    mSetupBarCount = 0;
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;

    mLastEntryMB = EMPTY;
    mLastEntryZone = EMPTY;

    mMBCount = 0;
    mLastDay = 0;

    mImbalanceCandlePercentChange = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupSymbol = Symbol();
    mSetupTimeFrame = 15;

    mEntryMBNumber = EMPTY;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

ReversalInnerBreak::~ReversalInnerBreak()
{
}

double ReversalInnerBreak::RiskPercent()
{
    return mRiskPercent;
}

void ReversalInnerBreak::Run()
{
    EAHelper::RunDrawMBT<ReversalInnerBreak>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ReversalInnerBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<ReversalInnerBreak>(this) && EAHelper::WithinTradingSession<ReversalInnerBreak>(this) &&
           mLastEntryMB < mSetupMBT.MBsCreated() - 1;
}

void ReversalInnerBreak::CheckSetSetup()
{
    // looking for opposite MB
    int setupType = mSetupType == OP_BUY ? OP_SELL : OP_BUY;
    if (EAHelper::CheckSetSingleMBSetup<ReversalInnerBreak>(this, mSetupMBT, mFirstMBInSetupNumber, setupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        int furthest = EMPTY;
        int width = EMPTY;
        double height = 0.0;
        bool brokeCandle = false;
        bool oppositeCandle = false;
        double furthestBeforeFurthest = 0.0;
        double impulsePips = 0.0;
        bool hasImpulseCandle = false;

        if (mSetupType == OP_BUY)
        {
            if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(furthest))
            {
                return;
            }

            width = tempMBState.HighIndex();
            height = iHigh(mEntrySymbol, mEntryTimeFrame, width) - iLow(mEntrySymbol, mEntryTimeFrame, furthest);
            oppositeCandle = CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1);

            for (int i = 1; i < furthest; i++)
            {
                if (iClose(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1))
                {
                    brokeCandle = true;
                    break;
                }
            }

            if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, furthest + 5, furthest, true, furthestBeforeFurthest))
            {
                return;
            }

            impulsePips = OrderHelper::PipsToRange(furthestBeforeFurthest - iLow(mEntrySymbol, mEntryTimeFrame, furthest));
            for (int i = furthest + 1; i <= furthest + 5; i++)
            {
                if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) <= -0.08 &&
                    CandleStickHelper::HasImbalance(setupType, mEntrySymbol, mEntryTimeFrame, i))
                {
                    hasImpulseCandle = true;
                    break;
                }
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(furthest))
            {
                return;
            }

            width = tempMBState.LowIndex();
            height = iHigh(mEntrySymbol, mEntryTimeFrame, furthest) - iLow(mEntrySymbol, mEntryTimeFrame, width);
            oppositeCandle = CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1);
            for (int i = 1; i < furthest; i++)
            {
                if (iClose(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1))
                {
                    brokeCandle = true;
                    break;
                }
            }

            if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, furthest + 5, furthest, true, furthestBeforeFurthest))
            {
                return;
            }

            impulsePips = OrderHelper::PipsToRange(iHigh(mEntrySymbol, mEntryTimeFrame, furthest) - furthestBeforeFurthest);
            for (int i = furthest + 1; i <= furthest + 5; i++)
            {
                if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= 0.08 &&
                    CandleStickHelper::HasImbalance(setupType, mEntrySymbol, mEntryTimeFrame, i))
                {
                    hasImpulseCandle = true;
                    break;
                }
            }
        }

        // only take the break from the furthest point
        if (furthest > 3)
        {
            return;
        }

        // make sure we have a decent sized move to work with
        if (width < 10 || height < OrderHelper::PipsToRange(1250) || (impulsePips < 750 && !hasImpulseCandle))
        {
            return;
        }

        if (!brokeCandle)
        {
            return;
        }

        if (!oppositeCandle)
        {
            return;
        }

        mHasSetup = true;
        mSetupCandleStartTime = iTime(mEntrySymbol, mEntryTimeFrame, furthest);
        mFirstOppositeCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ReversalInnerBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }

    if (mHasSetup)
    {
        int setupCandleStartIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mSetupCandleStartTime);
        int firstOppositeCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFirstOppositeCandleTime);
        if (mSetupType == OP_BUY)
        {
            // candle if we push past than the candle before the break
            if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, setupCandleStartIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }

            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, firstOppositeCandleIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            // candle if we push past than the candle before the break
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, setupCandleStartIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }

            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, firstOppositeCandleIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }
        }
    }
}

void ReversalInnerBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ReversalInnerBreak>(this, deletePendingOrder, false, error);
    mStopLossCandleTime = 0;

    mFirstMBInSetupNumber = EMPTY;
}

bool ReversalInnerBreak::Confirmation()
{
    // bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    // int bars = iBars(mEntrySymbol, mEntryTimeFrame);
    // if (bars <= mBarCount)
    // {
    //     return hasTicket;
    // }

    // // bool isBigDipper = EAHelper::CandleIsBigDipper<ReversalInnerBreak>(this);
    // return hasTicket || isBigDipper;

    return true;
}

void ReversalInnerBreak::PlaceOrders()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips) + OrderHelper::PipsToRange(mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<ReversalInnerBreak>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        // InvalidateSetup(false);
    }
}

void ReversalInnerBreak::ManageCurrentPendingSetupTicket()
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
            // InvalidateSetup(true);
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            // InvalidateSetup(true);
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void ReversalInnerBreak::ManageCurrentActiveSetupTicket()
{
    if (!mLastEntryMB != mFirstMBInSetupNumber)
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ReversalInnerBreak>(this, mBEAdditionalPip);
    }
}

bool ReversalInnerBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ReversalInnerBreak>(this, ticket);
}

void ReversalInnerBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<ReversalInnerBreak>(this, ticketIndex);
}

void ReversalInnerBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ReversalInnerBreak>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ReversalInnerBreak>(this);
}

void ReversalInnerBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ReversalInnerBreak>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ReversalInnerBreak>(this, ticketIndex);
}

void ReversalInnerBreak::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<ReversalInnerBreak>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT, mMBCount, mLastEntryZone);
}

void ReversalInnerBreak::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ReversalInnerBreak>(this, oldTicketIndex, newTicketNumber);
}

void ReversalInnerBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ReversalInnerBreak>(this, ticket, Period());
}

void ReversalInnerBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ReversalInnerBreak>(this, error, additionalInformation);
}

void ReversalInnerBreak::Reset()
{
    mMBCount = 0;
}