//+------------------------------------------------------------------+
//|                                                    ImpulseContinuation.mqh |
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

class ImpulseContinuation : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mConfirmationMBT;

    int mFirstMBInConfirmationNumber;
    double mMinPercentChange;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mBEAdditionalPips;

    datetime mSetupCandleTime;
    datetime mEntryCandleTime;
    int mEntryMB;

    int mSetupBarCount;
    int mEntryBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mSetupTimeFrame;
    string mSetupSymbol;

public:
    ImpulseContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&confirmationMBT);
    ~ImpulseContinuation();

    double EMA(int index) { return iMA(mSetupSymbol, mSetupTimeFrame, 9, 0, MODE_EMA, PRICE_CLOSE, index); }
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

ImpulseContinuation::ImpulseContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&confirmationMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mConfirmationMBT = confirmationMBT;

    mMinPercentChange = 0.0;
    mFirstMBInConfirmationNumber = EMPTY;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseContinuation>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseContinuation, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseContinuation, MultiTimeFrameEntryTradeRecord>(this);

    mSetupBarCount = 0;
    mEntryBarCount = 0;

    mSetupCandleTime = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupSymbol = Symbol();
    mSetupTimeFrame = Period();

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

ImpulseContinuation::~ImpulseContinuation()
{
}

double ImpulseContinuation::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<ImpulseContinuation>(this, 5, 0.5);
}

void ImpulseContinuation::Run()
{
    EAHelper::RunDrawMBT<ImpulseContinuation>(this, mConfirmationMBT);

    mSetupBarCount = iBars(mSetupSymbol, mSetupTimeFrame);
    mEntryBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseContinuation::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseContinuation>(this) && EAHelper::WithinTradingSession<ImpulseContinuation>(this);
}

void ImpulseContinuation::CheckSetSetup()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    bool furtherThanEMA = false;
    bool hasPercentChange = false;
    bool hasImpulse = false;

    for (int i = 0; i <= 10; i++)
    {
        datetime candleTime = iTime(mSetupSymbol, mSetupTimeFrame, i);
        if (TimeHour(candleTime) <= 14)
        {
            return;
        }

        double percentChange = CandleStickHelper::PercentChange(mSetupSymbol, mSetupTimeFrame, i);
        if (mSetupType == OP_BUY)
        {
            // do 0.98 since I want 1 but will allow for .02 variance
            hasPercentChange = percentChange >= mMinPercentChange;
            furtherThanEMA = currentTick.bid >= EMA(0);
        }
        else if (mSetupType == OP_SELL)
        {
            // do 0.98 since I want 1 but will allow for .02 variance
            hasPercentChange = percentChange <= -mMinPercentChange;
            furtherThanEMA = currentTick.ask <= EMA(0);
        }

        if (hasPercentChange && furtherThanEMA)
        {
            hasImpulse = true;
            mSetupCandleTime = candleTime;
            break;
        }
    }

    if (hasImpulse)
    {
        if (EAHelper::CheckSetSingleMBSetup<ImpulseContinuation>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
        {
            if (EAHelper::MBWithinWidth<ImpulseContinuation>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, 0, 100))
            {
                mHasSetup = true;
            }
        }
    }
}

void ImpulseContinuation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    int setupBars = iBars(mSetupSymbol, mSetupTimeFrame);
    if (setupBars > mSetupBarCount)
    {
        if (mSetupCandleTime > 0)
        {
            int setupCandleIndex = iBarShift(mSetupSymbol, mSetupTimeFrame, mSetupCandleTime);
            if (setupCandleIndex > 1 && mHasSetup)
            {
                if (mSetupType == OP_BUY)
                {
                    if (CandleStickHelper::GetLowestBodyPart(mSetupSymbol, mSetupTimeFrame, 1) < EMA(1))
                    {
                        InvalidateSetup(true);
                        return;
                    }
                }
                else if (mSetupType == OP_SELL)
                {
                    if (CandleStickHelper::GetHighestBodyPart(mSetupSymbol, mSetupTimeFrame, 1) > EMA(1))
                    {
                        InvalidateSetup(true);
                        return;
                    }
                }
            }
        }
    }

    int entryBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (entryBars > mEntryBarCount)
    {
        if (mFirstMBInConfirmationNumber != EMPTY && mFirstMBInConfirmationNumber != mConfirmationMBT.MBsCreated() - 1)
        {
            InvalidateSetup(true);
        }
    }
}

void ImpulseContinuation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseContinuation>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBConfirmation<ImpulseContinuation>(this, false);

    mSetupCandleTime = 0;
}

bool ImpulseContinuation::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return hasTicket;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    MBState *tempMBState;
    if (!mConfirmationMBT.GetMB(mFirstMBInConfirmationNumber, tempMBState))
    {
        return false;
    }

    bool dojiInZone = false;
    int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<ImpulseContinuation>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, dojiInZone);
    if (TerminalErrors::IsTerminalError(error))
    {
        RecordError(error);
    }

    bool hasPendingMB = false;
    int width = EMPTY;
    double height = 0.0;
    int furthestIndex = EMPTY;

    if (mSetupType == OP_BUY)
    {
        if (!mConfirmationMBT.CurrentBullishRetracementIndexIsValid(width))
        {
            return false;
        }

        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, width, 0, false, furthestIndex))
        {
            return false;
        }

        height = iHigh(mEntrySymbol, mEntryTimeFrame, width) - iLow(mEntrySymbol, mEntryTimeFrame, furthestIndex);
        hasPendingMB = mConfirmationMBT.HasPendingBullishMB();
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mConfirmationMBT.CurrentBearishRetracementIndexIsValid(width))
        {
            return false;
        }

        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, width, 0, false, furthestIndex))
        {
            return false;
        }

        height = iHigh(mEntrySymbol, mEntryTimeFrame, furthestIndex) - iLow(mEntrySymbol, mEntryTimeFrame, width);
        hasPendingMB = mConfirmationMBT.HasPendingBearishMB();
    }

    double percentOfHeight = 0.0;
    if (tempMBState.Height() > height)
    {
        percentOfHeight = height / tempMBState.Height();
    }
    else
    {
        percentOfHeight = tempMBState.Height() / height;
    }

    // force pending mb and previous mb to be within 30% of each other
    if (percentOfHeight < 0.3)
    {
        return false;
    }

    if (width > 50 || furthestIndex > 3)
    {
        return false;
    }

    return hasTicket || (dojiInZone && hasPendingMB);
}

void ImpulseContinuation::PlaceOrders()
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
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<ImpulseContinuation>(this, currentTick.ask, stopLoss);
        }
        else if (entry > currentTick.ask)
        {
            EAHelper::PlaceStopOrder<ImpulseContinuation>(this, entry, stopLoss);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<ImpulseContinuation>(this, currentTick.bid, stopLoss);
        }
        else if (entry < currentTick.bid)
        {
            EAHelper::PlaceStopOrder<ImpulseContinuation>(this, entry, stopLoss);
        }
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInConfirmationNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ImpulseContinuation::ManageCurrentPendingSetupTicket()
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

    if (entryCandleIndex > 3)
    {
        InvalidateSetup(true);
    }
}

void ImpulseContinuation::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    // BE after we validate the MB we entered in
    if (mConfirmationMBT.MBsCreated() - 1 != mEntryMB)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseContinuation>(this, mBEAdditionalPips);
    }
}

bool ImpulseContinuation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseContinuation>(this, ticket);
}

void ImpulseContinuation::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<ImpulseContinuation>(this, ticketIndex);
}

void ImpulseContinuation::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseContinuation>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseContinuation>(this);
}

void ImpulseContinuation::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseContinuation>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseContinuation>(this, ticketIndex);
}

void ImpulseContinuation::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseContinuation>(this);
}

void ImpulseContinuation::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseContinuation>(this, oldTicketIndex, newTicketNumber);
}

void ImpulseContinuation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseContinuation>(this, ticket, Period());
}

void ImpulseContinuation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseContinuation>(this, error, additionalInformation);
}

void ImpulseContinuation::Reset()
{
}