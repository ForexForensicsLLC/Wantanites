//+------------------------------------------------------------------+
//|                                                      Wyckoff.mqh |
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
#include <Wantanites\Framework\Trackers\MBWyckoffTracker.mqh>

class Wyckoff : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mBiasMBT;
    MBTracker *mSetupMBT;
    MBWyckoffTracker *mMBWT;

    int mLastCheckedSetupMB;
    int mLastCheckedConfirmationMB;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

    int mTimeFrame;

    int mOrderPlacedOnMB;

public:
    Wyckoff(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
            CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
            CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&biasMBT, MBTracker *&setupMBT, MBWyckoffTracker *&mbwt);
    ~Wyckoff();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }

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

Wyckoff::Wyckoff(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&biasMBT, MBTracker *&setupMBT, MBWyckoffTracker *&mbwt)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mBiasMBT = biasMBT;
    mSetupMBT = setupMBT;
    mMBWT = mbwt;

    mSetupType = setupType;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<Wyckoff>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<Wyckoff, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<Wyckoff, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<Wyckoff>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<Wyckoff>(this);
    }

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mTimeFrame = 1;

    mOrderPlacedOnMB = EMPTY;
}

Wyckoff::~Wyckoff()
{
}

void Wyckoff::Run()
{
    EAHelper::RunDrawMBT<Wyckoff>(this, mSetupMBT);

    mSetupMBsCreated = mSetupMBT.MBsCreated();
}

bool Wyckoff::AllowedToTrade()
{
    return EAHelper::BelowSpread<Wyckoff>(this);
}

void Wyckoff::CheckSetSetup()
{
    if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    {
        MBState *biasMB;
        if (!mBiasMBT.GetNthMostRecentMB(0, biasMB))
        {
            return;
        }

        if (biasMB.Type() == mSetupType)
        {
            if (mMBWT.HasSetup())
            {
                mHasSetup = true;
            }
        }
    }
}

void Wyckoff::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    MBState *mostRecentMB;
    if (!mSetupMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        InvalidateSetup(true);
    }

    if (mostRecentMB.Type() != mSetupType)
    {
        InvalidateSetup(true);
    }
}

void Wyckoff::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<Wyckoff>(this, deletePendingOrder, false, error);
}

bool Wyckoff::Confirmation()
{
    MBState *tempMBState;
    if (!mSetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return false;
    }

    bool hasConfirmation;
    int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<Wyckoff>(this, mSetupMBT, mSetupMBT.MBsCreated() - 1, hasConfirmation);
    if (error != ERR_NO_ERROR)
    {
        return false;
    }

    return hasConfirmation;
}

void Wyckoff::PlaceOrders()
{
    if (mSetupMBsCreated != mOrderPlacedOnMB)
    {
        if (mCurrentSetupTicket.Number() != EMPTY)
        {
            return;
        }

        // EAHelper::PlaceStopOrderForPendingMBValidation<Wyckoff>(this, mSetupMBT, mSetupMBT.MBsCreated() - 1);

        EAHelper::PlaceStopOrderForCandelBreak<Wyckoff>(this, Symbol(), Period(), 1);
        mEntryCandleTime = iTime(Symbol(), Period(), 1);

        if (mCurrentSetupTicket.Number() != EMPTY)
        {
            mOrderPlacedOnMB = mSetupMBsCreated;
        }
    }
}

void Wyckoff::ManageCurrentPendingSetupTicket()
{
    // EAHelper::CheckditStopLossForPendingMBValidation<Wyckoff>(this, mSetupMBT, mSetupMBT.MBsCreated() - 1);
    EAHelper::CheckBrokePastCandle<Wyckoff>(this, Symbol(), Period(), mSetupType, mEntryCandleTime);
}

void Wyckoff::ManageCurrentActiveSetupTicket()
{
}

bool Wyckoff::MoveToPreviousSetupTickets(Ticket &ticket)
{
    bool isActive;
    int activeError = ticket.IsActive(isActive);
    if (activeError != ERR_NO_ERROR)
    {
        return false;
    }

    return isActive;
}

void Wyckoff::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<Wyckoff>(this, ticketIndex);
}

void Wyckoff::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<Wyckoff>(this);
}

void Wyckoff::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<Wyckoff>(this, ticketIndex);
}

void Wyckoff::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<Wyckoff>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT);
}

void Wyckoff::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Wyckoff>(this, oldTicketIndex, newTicketNumber);
}

void Wyckoff::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<Wyckoff>(this, ticket, Period());
}

void Wyckoff::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<Wyckoff>(this, error, additionalInformation);
}

void Wyckoff::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}