//+------------------------------------------------------------------+
//|                                                    StackIntoTrades.mqh |
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

class StackIntoTrades : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    int mFirstMBInSession;

    double mEntryPaddingPips;
    double mMaxEntrySlippage;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

public:
    StackIntoTrades(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~StackIntoTrades();

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

StackIntoTrades::StackIntoTrades(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mFirstMBInSession = EMPTY;

    mBarCount = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMaxEntrySlippage = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StackIntoTrades>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<StackIntoTrades, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StackIntoTrades, SingleTimeFrameEntryTradeRecord>(this);
}

double StackIntoTrades::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<StackIntoTrades>(this, 5, 0.5);
}

StackIntoTrades::~StackIntoTrades()
{
}

void StackIntoTrades::Run()
{
    EAHelper::RunDrawMBT<StackIntoTrades>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool StackIntoTrades::AllowedToTrade()
{
    return EAHelper::BelowSpread<StackIntoTrades>(this) && EAHelper::WithinTradingSession<StackIntoTrades>(this);
}

void StackIntoTrades::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    // need to make sure we are only trading if the first mb of the session matches our setup type
    if (mFirstMBInSession == EMPTY)
    {
        MBState *firstMBState;
        if (!mSetupMBT.GetNthMostRecentMB(0, firstMBState))
        {
            return;
        }

        if (EAHelper::CandleIsWithinSession<StackIntoTrades>(this, mEntrySymbol, mEntryTimeFrame, firstMBState.EndIndex()))
        {
            mFirstMBInSession = firstMBState.Number();

            if (firstMBState.Type() != mSetupType)
            {
                mStopTrading = true;
                return;
            }
        }
    }

    if (EAHelper::CheckSetSingleMBSetup<StackIntoTrades>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (EAHelper::CandleIsWithinSession<StackIntoTrades>(this, mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex()))
        {
            mHasSetup = true;
        }
    }
}

void StackIntoTrades::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);

            MBState *tempMBState;
            if (!mSetupMBT.GetNthMostRecentMB(0, tempMBState))
            {
                return;
            }

            if (tempMBState.Type() != mSetupType)
            {
                mStopTrading = true;
            }
        }
    }
}

void StackIntoTrades::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<StackIntoTrades>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
}

bool StackIntoTrades::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return hasTicket;
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

    int pendingMBStart = EMPTY;
    int furthestAfterMB = EMPTY;
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

        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 1, false, furthestAfterMB))
        {
            return false;
        }

        if (iLow(mEntrySymbol, mEntryTimeFrame, furthestAfterMB) > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        {
            return false;
        }

        return CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1) &&
               CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, 1);
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

        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 1, false, furthestAfterMB))
        {
            return false;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, furthestAfterMB) < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        {
            return false;
        }

        return CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1) &&
               CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, 1);
    }

    return false;
}

void StackIntoTrades::PlaceOrders()
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
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<StackIntoTrades>(this, entry, stopLoss, 0.0, true, mMaxEntrySlippage);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void StackIntoTrades::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);

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

    if (entryCandleIndex > 1)
    {
        InvalidateSetup(true);
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
}

void StackIntoTrades::ManageCurrentActiveSetupTicket()
{
}

bool StackIntoTrades::MoveToPreviousSetupTickets(Ticket &ticket)
{
    int selectError = ticket.SelectIfOpen("Managing");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return false;
    }

    // ticket has been activated
    return OrderType() <= 1;
}

void StackIntoTrades::ManagePreviousSetupTicket(int ticketIndex)
{
    int selectError = mPreviousSetupTickets[ticketIndex].SelectIfOpen("Managing");
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

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        if (entryIndex > 0)
        {
            // close if we fail to break with a body and we are above the entry
            if (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex + 1) &&
                currentTick.bid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mPreviousSetupTickets[ticketIndex].Close();
                return;
            }
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        if (entryIndex > 0)
        {
            // close if we fail to break with a body and we are below the entry
            if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex + 1) &&
                currentTick.ask < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mPreviousSetupTickets[ticketIndex].Close();
                return;
            }
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    bool atBE = false;
    int beError = mPreviousSetupTickets[ticketIndex].StopLossIsMovedToBreakEven(atBE);
    if (TerminalErrors::IsTerminalError(beError))
    {
        RecordError(beError);
    }
    else if (!atBE && movedPips && entryIndex >= 10)
    {
        EAHelper::MoveTicketToBreakEven<StackIntoTrades>(this, mPreviousSetupTickets[ticketIndex], mBEAdditionalPips);
    }

    EAHelper::CheckPartialTicket<StackIntoTrades>(this, mPreviousSetupTickets[ticketIndex]);
}

void StackIntoTrades::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StackIntoTrades>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<StackIntoTrades>(this);
}

void StackIntoTrades::CheckPreviousSetupTicket(int ticketIndex)
{
    int selectError = mPreviousSetupTickets[ticketIndex].SelectIfOpen("Managing");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    if (OrderCloseTime() > 0)
    {
        // stop trading if we took a loss
        if (OrderType() == OP_BUY && OrderClosePrice() < OrderOpenPrice())
        {
            InvalidateSetup(true);
            mStopTrading = true;
        }
        else if (OrderType() == OP_SELL && OrderClosePrice() > OrderOpenPrice())
        {
            InvalidateSetup(true);
            mStopTrading = true;
        }
    }

    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StackIntoTrades>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<StackIntoTrades>(this, ticketIndex);
}

void StackIntoTrades::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StackIntoTrades>(this);
}

void StackIntoTrades::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<StackIntoTrades>(this, partialedTicket, newTicketNumber);
}

void StackIntoTrades::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<StackIntoTrades>(this, ticket, Period());
}

void StackIntoTrades::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<StackIntoTrades>(this, error, additionalInformation);
}

void StackIntoTrades::Reset()
{
    mFirstMBInSession = EMPTY;
    mStopTrading = false;
}