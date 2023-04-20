//+------------------------------------------------------------------+
//|                                                    TinyMBValidation.mqh |
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

class TinyMBValidation : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mMaxMBPips;

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
    TinyMBValidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TinyMBValidation();

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

TinyMBValidation::TinyMBValidation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMaxMBPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TinyMBValidation>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TinyMBValidation, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TinyMBValidation, SingleTimeFrameEntryTradeRecord>(this);

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

TinyMBValidation::~TinyMBValidation()
{
}

double TinyMBValidation::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<TinyMBValidation>(this, 5, 0.5);
}

void TinyMBValidation::Run()
{
    EAHelper::RunDrawMBT<TinyMBValidation>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool TinyMBValidation::AllowedToTrade()
{
    return EAHelper::BelowSpread<TinyMBValidation>(this) && EAHelper::WithinTradingSession<TinyMBValidation>(this);
}

void TinyMBValidation::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<TinyMBValidation>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.EndIndex() > 1)
        {
            return;
        }

        if (tempMBState.Height() > OrderHelper::PipsToRange(mMaxMBPips))
        {
            return;
        }

        MBState *prevMBState;
        if (!mSetupMBT.GetPreviousMB(mFirstMBInSetupNumber, prevMBState))
        {
            return;
        }

        if (mSetupType == OP_BUY)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, prevMBState.HighIndex()) - iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) < OrderHelper::PipsToRange(0))
            {
                return;
            }

            mHasSetup = true;
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, prevMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) < OrderHelper::PipsToRange(0))
            {
                return;
            }

            mHasSetup = true;
        }
    }
}

void TinyMBValidation::CheckInvalidateSetup()
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

        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            InvalidateSetup(true);
            return;
        }

        if (tempMBState.EndIndex() > 1)
        {
            InvalidateSetup(true);
        }
    }
}

void TinyMBValidation::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<TinyMBValidation>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<TinyMBValidation>(this, false);
}

bool TinyMBValidation::Confirmation()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    double maxDistanceFromMBVal = 30;
    bool closeEnoughToMBVal = false;
    if (mSetupType == OP_BUY)
    {
        closeEnoughToMBVal = currentTick.ask - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) < OrderHelper::PipsToRange(maxDistanceFromMBVal);
    }
    else if (mSetupType == OP_SELL)
    {
        closeEnoughToMBVal = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - currentTick.bid < OrderHelper::PipsToRange(maxDistanceFromMBVal);
    }

    return mCurrentSetupTicket.Number() != EMPTY || closeEnoughToMBVal;
}

void TinyMBValidation::PlaceOrders()
{
    if (mFirstMBInSetupNumber == mEntryMB)
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

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());
    }

    EAHelper::PlaceMarketOrder<TinyMBValidation>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void TinyMBValidation::ManageCurrentPendingSetupTicket()
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

    // if (mSetupType == OP_BUY && entryCandleIndex > 1)
    // {
    //     if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (mSetupType == OP_SELL && entryCandleIndex > 1)
    // {
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
}

void TinyMBValidation::ManageCurrentActiveSetupTicket()
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
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips /*|| mEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TinyMBValidation>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool TinyMBValidation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TinyMBValidation>(this, ticket);
}

void TinyMBValidation::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<TinyMBValidation>(this, mPreviousSetupTickets[ticketIndex]);
}

void TinyMBValidation::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TinyMBValidation>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TinyMBValidation>(this);
}

void TinyMBValidation::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TinyMBValidation>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TinyMBValidation>(this, ticketIndex);
}

void TinyMBValidation::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<TinyMBValidation>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void TinyMBValidation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TinyMBValidation>(this, partialedTicket, newTicketNumber);
}

void TinyMBValidation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TinyMBValidation>(this, ticket, Period());
}

void TinyMBValidation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TinyMBValidation>(this, error, additionalInformation);
}

void TinyMBValidation::Reset()
{
}