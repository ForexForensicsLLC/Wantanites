//+------------------------------------------------------------------+
//|                                                   MBRecorder.mqh |
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

class MBRecorder : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

    bool mCrossedAboveSMA;
    bool mCrossedBelowSMA;

    datetime mCrossedSMATime;

    int mTimeFrame;

    int mLastMB;

public:
    MBRecorder(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~MBRecorder();

    virtual int MagicNumber() { return 7; }

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

MBRecorder::MBRecorder(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = mbt;
    mFirstMBInSetupNumber = EMPTY;

    mSetupType = setupType;

    mEntryCandleTime = 0;
    mBarCount = 0;

    mCrossedAboveSMA = false;
    mCrossedBelowSMA = false;

    mTimeFrame = 60;

    mCrossedSMATime = EMPTY;

    mLastMB = EMPTY;

    ArrayResize(mStrategyMagicNumbers, 0);

    // EAHelper::FindSetPreviousAndCurrentSetupTickets<MBRecorder>(this);
    // EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBRecorder, PartialTradeRecord>(this);
    // EAHelper::SetPreviousSetupTicketsOpenData<MBRecorder, MultiTimeFrameEntryTradeRecord>(this);
}

MBRecorder::~MBRecorder()
{
}

void MBRecorder::Run()
{
    int currentBars = iBars(Symbol(), Period());
    if (currentBars > mBarCount)
    {
        EAHelper::RunDrawMBT<MBRecorder>(this, mSetupMBT);
    }

    mBarCount = iBars(Symbol(), Period());
}

bool MBRecorder::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBRecorder>(this);
}

void MBRecorder::CheckSetSetup()
{
    mLastState = 3;
    if (mSetupMBT.MBsCreated() > mLastMB)
    {
        if (EAHelper::CheckSetDoubleMBSetup<MBRecorder>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mSetupType))
        {
            mHasSetup = true;
        }

        mLastMB = mSetupMBT.MBsCreated();
    }
}

void MBRecorder::CheckInvalidateSetup()
{
    mLastState = 4;

    // int currentBars = iBars(Symbol(), Period());
    // if (currentBars > mBarCount)
    // {
    //     if (EAHelper::CheckBrokeMBRangeStart<MBRecorder>(this, mSetupMBT, mFirstMBInSetupNumber))
    //     {
    //         InvalidateSetup(true);

    //         return;
    //     }

    //     if (!mHasSetup)
    //     {
    //         return;
    //     }

    //     // End of Confirmation TF First MB
    //     if (EAHelper::CheckBrokeMBRangeEnd<MBRecorder>(this, mSetupMBT, mSecondMBInSetupNumber))
    //     {
    //         InvalidateSetup(false);
    //         return;
    //     }
    // }
}

void MBRecorder::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;

    mHasSetup = false;

    mCrossedBelowSMA = false;
    mCrossedAboveSMA = false;

    mCrossedSMATime = 0;

    EAHelper::InvalidateSetup<MBRecorder>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
}

bool MBRecorder::Confirmation()
{
    mLastState = 5;

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    if (!tempMBState.ClosestValidZoneIsHolding(tempMBState.EndIndex() + 1))
    {
        InvalidateSetup(false);
        return false;
    }

    return true;
}

void MBRecorder::PlaceOrders()
{
    RecordError(-123);
    InvalidateSetup(false);
}

void MBRecorder::ManageCurrentPendingSetupTicket()
{
}

void MBRecorder::ManageCurrentActiveSetupTicket()
{
}

bool MBRecorder::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void MBRecorder::ManagePreviousSetupTicket(int ticketIndex)
{
}

void MBRecorder::CheckCurrentSetupTicket()
{
}

void MBRecorder::CheckPreviousSetupTicket(int ticketIndex)
{
}

void MBRecorder::RecordTicketOpenData()
{
}

void MBRecorder::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
}

void MBRecorder::RecordTicketCloseData(Ticket &ticket)
{
}

void MBRecorder::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBRecorder>(this, error, additionalInformation);
}

void MBRecorder::Reset()
{
}