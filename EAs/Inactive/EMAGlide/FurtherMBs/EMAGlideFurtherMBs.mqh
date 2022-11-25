//+------------------------------------------------------------------+
//|                                                    EMAGlideFurtherMBs.mqh |
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

class EMAGlideFurtherMBs : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    double mMaxMBHeight;
    double mMinMBGap;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    EMAGlideFurtherMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~EMAGlideFurtherMBs();

    double EMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index); }
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

EMAGlideFurtherMBs::EMAGlideFurtherMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;

    mFirstMBInSetupNumber = EMPTY;
    mMaxMBHeight = 0.0;
    mMinMBGap = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EMAGlideFurtherMBs>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<EMAGlideFurtherMBs, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EMAGlideFurtherMBs, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

EMAGlideFurtherMBs::~EMAGlideFurtherMBs()
{
}

double EMAGlideFurtherMBs::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<EMAGlideFurtherMBs>(this, 5, 0.5);
}

void EMAGlideFurtherMBs::Run()
{
    EAHelper::RunDrawMBT<EMAGlideFurtherMBs>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool EMAGlideFurtherMBs::AllowedToTrade()
{
    return EAHelper::BelowSpread<EMAGlideFurtherMBs>(this) && EAHelper::WithinTradingSession<EMAGlideFurtherMBs>(this);
}

void EMAGlideFurtherMBs::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    bool hasGap = false;
    int pendingMBStart = EMPTY;
    if (mSetupType == OP_BUY)
    {
        for (int i = 0; i <= 4; i++)
        {
            MBState *tempMBState;
            if (!mSetupMBT.GetNthMostRecentMB(i, tempMBState))
            {
                return;
            }

            MBState *previousMBState;
            if (!mSetupMBT.GetPreviousMB(tempMBState.Number(), previousMBState))
            {
                return;
            }

            if (i == 0)
            {
                // our 2 most recent mbs have to be the same type
                if (tempMBState.Type() != OP_BUY || previousMBState.Type() != OP_BUY)
                {
                    return;
                }

                int furthestBodyInMBOne = EMPTY;
                if (!MQLHelper::GetLowestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.StartIndex(), tempMBState.EndIndex(), true, furthestBodyInMBOne))
                {
                    return;
                }

                if (iOpen(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBOne) < EMA(furthestBodyInMBOne) ||
                    iClose(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBOne) < EMA(furthestBodyInMBOne))
                {
                    return;
                }

                int furthestBodyInMBTwo = EMPTY;
                if (!MQLHelper::GetLowestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, previousMBState.StartIndex(), previousMBState.EndIndex(), true, furthestBodyInMBTwo))
                {
                    return;
                }

                if (iOpen(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBTwo) < EMA(furthestBodyInMBTwo) ||
                    iClose(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBTwo) < EMA(furthestBodyInMBTwo))
                {
                    return;
                }

                if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
                {
                    return;
                }

                bool greaterPushUpThanFirstMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) >
                                                      tempMBState.Height();

                if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) > iHigh(mEntrySymbol, mEntryTimeFrame, previousMBState.HighIndex()))
                {
                    if (greaterPushUpThanFirstMBHeight)
                    {
                        hasGap = true;
                        continue;
                    }
                }

                MBState *twoPreviousMBState;
                if (!mSetupMBT.GetPreviousMB(previousMBState.Number(), twoPreviousMBState))
                {
                    return;
                }

                if (iLow(mEntrySymbol, mEntryTimeFrame, previousMBState.LowIndex()) > iHigh(mEntrySymbol, mEntryTimeFrame, twoPreviousMBState.HighIndex()))
                {
                    bool greaterPushUpThanSecondMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) -
                                                               iHigh(mEntrySymbol, mEntryTimeFrame, previousMBState.HighIndex()) >
                                                           previousMBState.Height();

                    if (greaterPushUpThanFirstMBHeight || greaterPushUpThanSecondMBHeight)
                    {
                        hasGap = true;
                    }
                }
            }

            if (iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) < iHigh(mEntrySymbol, mEntryTimeFrame, previousMBState.HighIndex()))
            {
                return;
            }

            if (i < 4)
            {
                // all but the first mb has to be created after the session starts
                if (!EAHelper::CandleIsWithinSession<EMAGlideFurtherMBs>(this, mEntrySymbol, mEntryTimeFrame, tempMBState.StartIndex()))
                {
                    return;
                }
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        for (int i = 0; i <= 4; i++)
        {
            MBState *tempMBState;
            if (!mSetupMBT.GetNthMostRecentMB(i, tempMBState))
            {
                return;
            }

            MBState *previousMBState;
            if (!mSetupMBT.GetPreviousMB(tempMBState.Number(), previousMBState))
            {
                return;
            }

            if (i == 0)
            {
                // our 2 most recent mbs have to be the same type
                if (tempMBState.Type() != OP_SELL || previousMBState.Type() != OP_SELL)
                {
                    return;
                }

                int furthestBodyInMBOne = EMPTY;
                if (!MQLHelper::GetHighestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.StartIndex(), tempMBState.EndIndex(), true, furthestBodyInMBOne))
                {
                    return;
                }

                if (iOpen(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBOne) > EMA(furthestBodyInMBOne) ||
                    iClose(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBOne) > EMA(furthestBodyInMBOne))
                {
                    return;
                }

                int furthestBodyInMBTwo = EMPTY;
                if (!MQLHelper::GetHighestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, previousMBState.StartIndex(), previousMBState.EndIndex(), true, furthestBodyInMBTwo))
                {
                    return;
                }

                if (iOpen(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBTwo) > EMA(furthestBodyInMBTwo) ||
                    iClose(mEntrySymbol, mEntryTimeFrame, furthestBodyInMBTwo) > EMA(furthestBodyInMBTwo))
                {
                    return;
                }

                if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
                {
                    return;
                }

                bool greaterPushDownThanFirstMBHeight = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) >
                                                        tempMBState.Height();

                if (iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) < iLow(mEntrySymbol, mEntryTimeFrame, previousMBState.LowIndex()))
                {
                    if (greaterPushDownThanFirstMBHeight)
                    {
                        hasGap = true;
                        continue;
                    }
                }

                MBState *twoPreviousMBState;
                if (!mSetupMBT.GetPreviousMB(previousMBState.Number(), twoPreviousMBState))
                {
                    return;
                }

                if (iHigh(mEntrySymbol, mEntryTimeFrame, previousMBState.HighIndex()) < iLow(mEntrySymbol, mEntryTimeFrame, twoPreviousMBState.LowIndex()))
                {
                    bool greaterPushDownThanSecondMBHeight = iLow(mEntrySymbol, mEntryTimeFrame, previousMBState.LowIndex()) -
                                                                 iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) >
                                                             previousMBState.Height();

                    if (greaterPushDownThanFirstMBHeight || greaterPushDownThanSecondMBHeight)
                    {
                        hasGap = true;
                        return;
                    }
                }
            }

            if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) > iLow(mEntrySymbol, mEntryTimeFrame, previousMBState.LowIndex()))
            {
                return;
            }

            if (i < 4)
            {
                // all but the first mb has to be created after the session starts
                if (!EAHelper::CandleIsWithinSession<EMAGlideFurtherMBs>(this, mEntrySymbol, mEntryTimeFrame, tempMBState.StartIndex()))
                {
                    return;
                }
            }
        }
    }

    if (hasGap)
    {
        mHasSetup = true;
        mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;
    }
}

void EMAGlideFurtherMBs::CheckInvalidateSetup()
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

void EMAGlideFurtherMBs::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<EMAGlideFurtherMBs>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<EMAGlideFurtherMBs>(this, false);
}

bool EMAGlideFurtherMBs::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    bool doji = EAHelper::DojiInsideMostRecentMBsHoldingZone<EMAGlideFurtherMBs>(this, mSetupMBT, mFirstMBInSetupNumber);
    // bool furthestInZone = EAHelper::CandleIsInZone<EMAGlideFurtherMBs>(this, mSetupMBT, mFirstMBInSetupNumber, 1, true);

    return hasTicket || (doji);
}

void EMAGlideFurtherMBs::PlaceOrders()
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

    double entry = 0.0;
    double stopLoss = 0.0;
    int pendingMBStart = 0;

    if (mSetupType == OP_BUY)
    {
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        // // stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips),
        // //                    iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()));
        // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 2) - OrderHelper::PipsToRange(mStopLossPaddingPips);

        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        // stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips),
        //                    iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()));
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 2) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips);

        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        entry = iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
    }

    EAHelper::PlaceStopOrder<EMAGlideFurtherMBs>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void EMAGlideFurtherMBs::ManageCurrentPendingSetupTicket()
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

void EMAGlideFurtherMBs::ManageCurrentActiveSetupTicket()
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
    bool furtherThanEntry = false;

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // if (entryIndex > 20)
    // {
    //     movedPips = true;
    // }

    // if (mEntryMB != mSetupMBT.MBsCreated() - 1 && !movedPips)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<EMAGlideFurtherMBs>(this, 0.0);
    // }
    // else if (movedPips || mEntryMB != mSetupMBT.MBsCreated() - 1)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<EMAGlideFurtherMBs>(this, mBEAdditionalPips);
    // }

    if (movedPips || mSetupMBT.MBsCreated() > mEntryMB + 2)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<EMAGlideFurtherMBs>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool EMAGlideFurtherMBs::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<EMAGlideFurtherMBs>(this, ticket);
}

void EMAGlideFurtherMBs::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<EMAGlideFurtherMBs>(this, mPreviousSetupTickets[ticketIndex]);
}

void EMAGlideFurtherMBs::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EMAGlideFurtherMBs>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<EMAGlideFurtherMBs>(this);
}

void EMAGlideFurtherMBs::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EMAGlideFurtherMBs>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<EMAGlideFurtherMBs>(this, ticketIndex);
}

void EMAGlideFurtherMBs::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<EMAGlideFurtherMBs>(this);
}

void EMAGlideFurtherMBs::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<EMAGlideFurtherMBs>(this, partialedTicket, newTicketNumber);
}

void EMAGlideFurtherMBs::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EMAGlideFurtherMBs>(this, ticket, Period());
}

void EMAGlideFurtherMBs::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EMAGlideFurtherMBs>(this, error, additionalInformation);
}

void EMAGlideFurtherMBs::Reset()
{
}