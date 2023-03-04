//+------------------------------------------------------------------+
//|                                                    ImpulseReversal.mqh |
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

class ImpulseReversal : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mMinPercentChange;
    datetime mCandleZoneTime;

    double mEntryPaddingPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPip;

    datetime mEntryCandleTime;

    int mBarCount;
    int mLastEntryMB;

    int mEntryTimeFrame;
    string mEntrySymbol;

public:
    ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ImpulseReversal();

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

ImpulseReversal::ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinPercentChange = 0.0;
    mCandleZoneTime = 0;

    mEntryPaddingPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPip = 0.0;

    mBarCount = 0;
    mEntryCandleTime = 0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseReversal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseReversal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseReversal, SingleTimeFrameEntryTradeRecord>(this);
}

ImpulseReversal::~ImpulseReversal()
{
}

double ImpulseReversal::RiskPercent()
{
    return mRiskPercent;
}

void ImpulseReversal::Run()
{
    EAHelper::RunDrawMBT<ImpulseReversal>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseReversal::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseReversal>(this) && EAHelper::WithinTradingSession<ImpulseReversal>(this) &&
           mLastEntryMB < mSetupMBT.MBsCreated() - 1;
}

void ImpulseReversal::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    // looking for opposite MB
    int setupType = mSetupType == OP_BUY ? OP_SELL : OP_BUY;
    if (EAHelper::CheckSetSingleMBSetup<ImpulseReversal>(this, mSetupMBT, mFirstMBInSetupNumber, setupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.EndIndex() > 10)
        {
            return;
        }

        int pendingMBStart = EMPTY;
        bool hasImpulse = false;
        if (mSetupType == OP_BUY)
        {
            for (int i = tempMBState.EndIndex(); i >= 1; i--)
            {
                if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) <= -mMinPercentChange)
                {
                    hasImpulse = true;
                    break;
                }
            }
        }
        else if (mSetupType == OP_SELL)
        {
            for (int i = tempMBState.EndIndex(); i >= 1; i--)
            {
                if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= mMinPercentChange)
                {
                    hasImpulse = true;
                    break;
                }
            }
        }

        if (hasImpulse)
        {
            if (CandleStickHelper::BrokeFurther(mSetupType, mEntrySymbol, mEntryTimeFrame, 1))
            {
                mCandleZoneTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                mHasSetup = true;
            }
        }
    }
}

void ImpulseReversal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
            return;
        }

        if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
        {
            return;
        }

        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (mSetupType == OP_BUY)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }

    if (mCandleZoneTime > 0 && iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
    {
        int candleZoneIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCandleZoneTime);
        if (mSetupType == OP_BUY)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, candleZoneIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, candleZoneIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }
}

void ImpulseReversal::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseReversal>(this, deletePendingOrder, false, error);

    mFirstMBInSetupNumber = EMPTY;
    mCandleZoneTime = 0;
}

bool ImpulseReversal::Confirmation()
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

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCandleZoneTime);
    if (zoneCandleIndex < 20)
    {
        return false;
    }

    double fiftyPercentOfCandleZone = iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) -
                                      ((iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) - iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex)) * 0.5);
    if (mSetupType == OP_BUY)
    {
        // fail to break further while within fifty percent of the zone
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < fiftyPercentOfCandleZone &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // fail to break further while within fifty percent of the zone
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > fiftyPercentOfCandleZone &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }

    return false;
}

void ImpulseReversal::PlaceOrders()
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

    EAHelper::PlaceStopOrder<ImpulseReversal>(this, entry, stopLoss, 0.0, true, mBEAdditionalPip);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ImpulseReversal::ManageCurrentPendingSetupTicket()
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
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void ImpulseReversal::ManageCurrentActiveSetupTicket()
{
    if (!mLastEntryMB != mFirstMBInSetupNumber)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
    }

    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (EAHelper::CloseIfPercentIntoStopLoss<ImpulseReversal>(this, mCurrentSetupTicket, 0.5))
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

    if (movedPips || mLastEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseReversal>(this, mBEAdditionalPip);
    }

    EAHelper::CheckPartialTicket<ImpulseReversal>(this, mCurrentSetupTicket);
}

bool ImpulseReversal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseReversal>(this, ticket);
}

void ImpulseReversal::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<ImpulseReversal>(this, mPreviousSetupTickets[ticketIndex]);
}

void ImpulseReversal::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseReversal>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseReversal>(this);
}

void ImpulseReversal::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseReversal>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseReversal>(this, ticketIndex);
}

void ImpulseReversal::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseReversal>(this);
}

void ImpulseReversal::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseReversal>(this, partialedTicket, newTicketNumber);
}

void ImpulseReversal::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseReversal>(this, ticket, Period());
}

void ImpulseReversal::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseReversal>(this, error, additionalInformation);
}

void ImpulseReversal::Reset()
{
}