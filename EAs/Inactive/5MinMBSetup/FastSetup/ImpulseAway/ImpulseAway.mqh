//+------------------------------------------------------------------+
//|                                                    ImpulseAway.mqh |
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

class ImpulseAway : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mMinDistanceFromZone;

    double mMinMBHeight;
    double mMaxMBHeight;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;
    int mEntryZone;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    ImpulseAway(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ImpulseAway();

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

ImpulseAway::ImpulseAway(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinDistanceFromZone = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseAway>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseAway, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseAway, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
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

ImpulseAway::~ImpulseAway()
{
}

double ImpulseAway::RiskPercent()
{
    return mRiskPercent;
}

void ImpulseAway::Run()
{
    EAHelper::RunDrawMBT<ImpulseAway>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseAway::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseAway>(this) && EAHelper::WithinTradingSession<ImpulseAway>(this);
}

void ImpulseAway::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<ImpulseAway>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void ImpulseAway::CheckInvalidateSetup()
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
            return;
        }
    }
}

void ImpulseAway::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseAway>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<ImpulseAway>(this, false);
}

bool ImpulseAway::Confirmation()
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

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    int pendingMBStart = EMPTY;
    double furthestPoint = 0.0;
    int firstCandleInZone = EMPTY;
    int candlesNotEnteredZone = 0;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        for (int i = tempZoneState.StartIndex() - tempZoneState.EntryOffset(); i > pendingMBStart; i--)
        {
            // need to have all bullish candles after the zone
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                return false;
            }
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - tempZoneState.EntryPrice() < OrderHelper::PipsToRange(mMinDistanceFromZone))
        {
            return false;
        }

        // have to re tap in the zone soon after the retracement starts
        if (pendingMBStart > 6)
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, i) <= tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }

        if (firstCandleInZone == EMPTY || firstCandleInZone >= 4)
        {
            return false;
        }

        // failed to break lower
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        for (int i = tempZoneState.StartIndex() - tempZoneState.EntryOffset(); i > pendingMBStart; i--)
        {
            // need to have all bearish candles after the zone
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                return false;
            }
        }

        if (tempZoneState.EntryPrice() - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) < OrderHelper::PipsToRange(mMinDistanceFromZone))
        {
            return false;
        }

        // have to re tap in the zone soon after the retracement starts
        if (pendingMBStart > 6)
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) >= tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }

        if (firstCandleInZone == EMPTY || firstCandleInZone >= 4)
        {
            return false;
        }

        // fail to go higher
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }

    return false;
}

void ImpulseAway::PlaceOrders()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    if (mFirstMBInSetupNumber == mLastEntryMB)
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

    int pendingMBStart = EMPTY;
    double furthestPoint = 0.0;

    double entry = 0.0;
    double stopLoss = 0.0;

    // entry = tempZoneState.EntryPrice();
    stopLoss = tempZoneState.ExitPrice();

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
        {
            return;
        }

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        // stopLoss = furthestPoint - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
        {
            return;
        }

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        // stopLoss = furthestPoint + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<ImpulseAway>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryZone = tempZoneState.Number();

        mFailedImpulseEntryTime = 0;
    }
}

void ImpulseAway::ManageCurrentPendingSetupTicket()
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

    if (entryCandleIndex > 0)
    {
        InvalidateSetup(true);
        return;
    }

    // if (mSetupType == OP_BUY)
    // {
    //     if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
}

void ImpulseAway::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mLastEntryMB != mFirstMBInSetupNumber && mFirstMBInSetupNumber != EMPTY)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
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

    if (EAHelper::CloseIfPercentIntoStopLoss<ImpulseAway>(this, mCurrentSetupTicket, 0.2))
    {
        return;
    }

    bool movedPips = false;
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips || mLastEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseAway>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<ImpulseAway>(this, mCurrentSetupTicket);
}

bool ImpulseAway::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseAway>(this, ticket);
}

void ImpulseAway::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<ImpulseAway>(this, mPreviousSetupTickets[ticketIndex]);
}

void ImpulseAway::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseAway>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseAway>(this);
}

void ImpulseAway::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseAway>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseAway>(this, ticketIndex);
}

void ImpulseAway::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<ImpulseAway>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void ImpulseAway::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseAway>(this, partialedTicket, newTicketNumber);
}

void ImpulseAway::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseAway>(this, ticket, Period());
}

void ImpulseAway::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseAway>(this, error, additionalInformation);
}

void ImpulseAway::Reset()
{
}