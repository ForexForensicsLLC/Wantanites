//+------------------------------------------------------------------+
//|                                                        Sinji.mqh |
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

class Sinji : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    LiquidationSetupTracker *mSetupLST;

    int mTimeFrame;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mBarCount;

    datetime mEntryCandleTime;

public:
    Sinji(int setupType, int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
          CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
          CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, LiquidationSetupTracker *&lst, MBTracker *&setupMBT);
    ~Sinji();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishSingji : MagicNumbers::BearishSinji; }

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

Sinji::Sinji(int setupType, int timeFrame, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, LiquidationSetupTracker *&lst, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupLST = lst;
    mSetupMBT = setupMBT;

    mSetupType = setupType;
    mTimeFrame = timeFrame;
    mFirstMBInSetupNumber = EMPTY;
    mEntryCandleTime = 0;

    mBarCount = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<Sinji>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<Sinji, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<Sinji, SingleTimeFrameEntryTradeRecord>(this);

    ArrayResize(mStrategyMagicNumbers, 0);
}

Sinji::~Sinji()
{
}

void Sinji::Run()
{
    EAHelper::RunDrawMBT<Sinji>(this, mSetupMBT);

    mBarCount = iBars(Symbol(), mTimeFrame);
}

bool Sinji::AllowedToTrade()
{
    return EAHelper::BelowSpread<Sinji>(this);
}

void Sinji::CheckSetSetup()
{
    if (EAHelper::CheckSetFirstMBBreakAfterConsecutiveMBs<Sinji>(this, mSetupMBT, 3, mFirstMBInSetupNumber))
    {
        mHasSetup = true;
    }
}

void Sinji::CheckInvalidateSetup()
{
    if (EAHelper::CheckBrokeMBRangeStart<Sinji>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        EAHelper::InvalidateSetup<Sinji>(this, true, false);
        EAHelper::ResetSingleMBSetup<Sinji>(this, false);

        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (EAHelper::CheckBrokeMBRangeEnd<Sinji>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        EAHelper::InvalidateSetup<Sinji>(this, false, false);
        EAHelper::ResetSingleMBSetup<Sinji>(this, false);

        return;
    }
}

void Sinji::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    RecordError(-300);
    EAHelper::InvalidateSetup<Sinji>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
}

bool Sinji::Confirmation()
{
    // int currentBars = iBars(Symbol(), mTimeFrame);

    // bool hasConfirmation = false;
    // if (currentBars > mBarCount)
    // {
    //     int error = EAHelper::DojiBreakInsideLiquidationSetupMBsHoldingZone<Sinji>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, hasConfirmation);
    //     if (error != ERR_NO_ERROR)
    //     {
    //         RecordError(error);

    //         EAHelper::InvalidateSetup<Sinji>(this, true, false);
    //         EAHelper::ResetSingleMBSetup<Sinji>(this, false);

    //         return false;
    //     }
    // }

    // return hasConfirmation || mCurrentSetupTicket.Number() != EMPTY;

    MBState *secondPreviousInPreviousRun;
    if (!mSetupMBT.GetNthMostRecentMB(2, secondPreviousInPreviousRun))
    {
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        if (iHigh(Symbol(), 15, 0) > iHigh(Symbol(), 15, secondPreviousInPreviousRun.HighIndex()))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iLow(Symbol(), 15, 0) < iLow(Symbol(), 15, secondPreviousInPreviousRun.LowIndex()))
        {
            return false;
        }
    }

    return mCurrentSetupTicket.Number() != EMPTY || (mFirstMBInSetupNumber != EMPTY &&
                                                     ((mSetupMBT.HasPendingBullishMB() && mSetupType == OP_BUY && SetupHelper::BullishEngulfing(Symbol(), 15, 1)) ||
                                                      (mSetupMBT.HasPendingBearishMB() && mSetupType == OP_SELL && SetupHelper::BearishEngulfing(Symbol(), 15, 1))));
}

void Sinji::PlaceOrders()
{
    if (EAHelper::PrePlaceOrderChecks<Sinji>(this))
    {
        EAHelper::PlaceStopOrderForCandelBreak<Sinji>(this, Symbol(), 15, 1);
        mEntryCandleTime = iTime(Symbol(), mTimeFrame, 1);
    }
}

void Sinji::ManageCurrentPendingSetupTicket()
{
    int currentBars = iBars(Symbol(), mTimeFrame);
    if (currentBars > mBarCount)
    {
        EAHelper::CheckEditStopLossForPendingMBValidation<Sinji>(this, mSetupMBT, mFirstMBInSetupNumber);
    }
}

void Sinji::ManageCurrentActiveSetupTicket()
{
    // int currentBars = iBars(Symbol(), mTimeFrame);
    // if (currentBars > mBarCount)
    // {
    //     EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry<Sinji>(this);
    // }

    // EAHelper::CheckTrailStopLossWithMBs(this, mSetupMBT, mFirstMBInSetupNumber);

    EAHelper::MoveToBreakEvenAfterMBValidation<Sinji>(this, mSetupMBT, mFirstMBInSetupNumber);
}

bool Sinji::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<Sinji>(this, ticket);
}

void Sinji::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<Sinji>(this, ticketIndex);
}

void Sinji::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<Sinji>(this);
}

void Sinji::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<Sinji>(this, ticketIndex);
}

void Sinji::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<Sinji>(this);
}

void Sinji::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Sinji>(this, oldTicketIndex, newTicketNumber);
}

void Sinji::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<Sinji>(this, ticket, mTimeFrame);
}

void Sinji::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<Sinji>(this, error, additionalInformation);
}

void Sinji::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}