//+------------------------------------------------------------------+
//|                                                    ZoneExit.mqh |
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

class ZoneExit : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mMinValidationPercentChange;
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
    ZoneExit(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ZoneExit();

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

ZoneExit::ZoneExit(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinValidationPercentChange = 0.0;
    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ZoneExit>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ZoneExit, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ZoneExit, MultiTimeFrameEntryTradeRecord>(this);

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

ZoneExit::~ZoneExit()
{
}

double ZoneExit::RiskPercent()
{
    return mRiskPercent;
}

void ZoneExit::Run()
{
    EAHelper::RunDrawMBT<ZoneExit>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ZoneExit::AllowedToTrade()
{
    return EAHelper::BelowSpread<ZoneExit>(this) && EAHelper::WithinTradingSession<ZoneExit>(this);
}

void ZoneExit::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<ZoneExit>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (EAHelper::CandleIsAfterTime<ZoneExit>(this, mEntrySymbol, mEntryTimeFrame, 14, 30, tempMBState.StartIndex()))
        {
            if (MathAbs(CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex())) > mMinValidationPercentChange)
            {
                mHasSetup = true;
            }
        }
    }
}

void ZoneExit::CheckInvalidateSetup()
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

void ZoneExit::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ZoneExit>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<ZoneExit>(this, false);
}

bool ZoneExit::Confirmation()
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

        // have to re tap in the zone soon after the retracement starts
        if (pendingMBStart > 4)
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            // need to have all bearish candles into the zone
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                return false;
            }

            if (iLow(mEntrySymbol, mEntryTimeFrame, i) <= tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }

        if (firstCandleInZone == EMPTY || firstCandleInZone >= 2)
        {
            return false;
        }

        // previous candle needs to close in the zone
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > tempZoneState.EntryPrice())
        {
            return false;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart - 1, 0, true, furthestPoint))
        {
            return false;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - furthestPoint < OrderHelper::PipsToRange(mMinMBHeight))
        {
            return false;
        }

        // we are failing to break below the previous candle
        if (iClose(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1))
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

        // have to re tap in the zone soon after the retracement starts
        if (pendingMBStart > 4)
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            // need to have all bullish candles into the zone
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                return false;
            }

            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) >= tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }

        if (firstCandleInZone == EMPTY || firstCandleInZone >= 2)
        {
            return false;
        }

        // previous candle needs to close in the zone
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < tempZoneState.EntryPrice())
        {
            return false;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart - 1, 0, true, furthestPoint))
        {
            return false;
        }

        if (furthestPoint - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) < OrderHelper::PipsToRange(mMinMBHeight))
        {
            return false;
        }

        // we are failing to break below the previous candle
        if (iClose(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1))
        {
            return true;
        }
    }

    return false;
}

void ZoneExit::PlaceOrders()
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

    entry = tempZoneState.EntryPrice();
    stopLoss = tempZoneState.ExitPrice();

    // if (mSetupType == OP_BUY)
    // {
    //     if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
    //     {
    //         return;
    //     }

    //     if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
    //     {
    //         return;
    //     }

    //     // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
    //     // stopLoss = furthestPoint - OrderHelper::PipsToRange(mStopLossPaddingPips);
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
    //     {
    //         return;
    //     }

    //     if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
    //     {
    //         return;
    //     }

    //     entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
    //     stopLoss = furthestPoint + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    // }

    EAHelper::PlaceStopOrder<ZoneExit>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryZone = tempZoneState.Number();

        mFailedImpulseEntryTime = 0;
    }
}

void ZoneExit::ManageCurrentPendingSetupTicket()
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

void ZoneExit::ManageCurrentActiveSetupTicket()
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

    if (EAHelper::CloseIfPercentIntoStopLoss<ZoneExit>(this, mCurrentSetupTicket, 0.2))
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ZoneExit>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<ZoneExit>(this, mCurrentSetupTicket);
}

bool ZoneExit::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ZoneExit>(this, ticket);
}

void ZoneExit::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<ZoneExit>(this, mPreviousSetupTickets[ticketIndex]);
}

void ZoneExit::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ZoneExit>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ZoneExit>(this);
}

void ZoneExit::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ZoneExit>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ZoneExit>(this, ticketIndex);
}

void ZoneExit::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<ZoneExit>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void ZoneExit::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ZoneExit>(this, partialedTicket, newTicketNumber);
}

void ZoneExit::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ZoneExit>(this, ticket, Period());
}

void ZoneExit::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ZoneExit>(this, error, additionalInformation);
}

void ZoneExit::Reset()
{
}