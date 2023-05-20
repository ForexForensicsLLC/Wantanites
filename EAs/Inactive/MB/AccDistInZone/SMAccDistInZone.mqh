//+------------------------------------------------------------------+
//|                                              SMAccDistInZone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Trackers/CandleStickPatternTracker.mqh>

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class SMAccDistInZone : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    CandleStickPatternTracker *mCSPT;

    int mFirstMBInSetupNumber;

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

public:
    SMAccDistInZone(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, CandleStickPatternTracker *&cspt);
    ~SMAccDistInZone();

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

SMAccDistInZone::SMAccDistInZone(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, CandleStickPatternTracker *&cspt)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = mbt;
    mCSPT = cspt;
    mFirstMBInSetupNumber = EMPTY;

    mSetupType = setupType;

    mEntryCandleTime = 0;
    mBarCount = 0;

    mCrossedAboveSMA = false;
    mCrossedBelowSMA = false;

    mTimeFrame = 60;

    mCrossedSMATime = EMPTY;

    ArrayResize(mStrategyMagicNumbers, 0);

    // EAHelper::FindSetPreviousAndCurrentSetupTickets<SMAccDistInZone>(this);
    // EAHelper::UpdatePreviousSetupTicketsRRAcquried<SMAccDistInZone, PartialTradeRecord>(this);
    // EAHelper::SetPreviousSetupTicketsOpenData<SMAccDistInZone, MultiTimeFrameEntryTradeRecord>(this);
}

SMAccDistInZone::~SMAccDistInZone()
{
}

void SMAccDistInZone::Run()
{
    mCSPT.Update();
    int currentBars = iBars(Symbol(), Period());
    if (currentBars > mBarCount)
    {
        EAHelper::RunDrawMBT<SMAccDistInZone>(this, mSetupMBT);
    }

    mBarCount = iBars(Symbol(), Period());
}

bool SMAccDistInZone::AllowedToTrade()
{
    return EAHelper::BelowSpread<SMAccDistInZone>(this);
}

void SMAccDistInZone::CheckSetSetup()
{
    mLastState = 3;
    int currentBars = iBars(Symbol(), Period());
    if (currentBars > mBarCount)
    {
        double sma = iMA(Symbol(), Period(), 200, 0, MODE_SMA, PRICE_CLOSE, 1);
        if (mSetupType == OP_BUY)
        {
            if (iLow(Symbol(), Period(), 1) > sma)
            {
                if (EAHelper::CheckSetSingleMBSetup<SMAccDistInZone>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
                {
                    mHasSetup = true;
                }
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(Symbol(), Period(), 1) < sma)
            {
                if (EAHelper::CheckSetSingleMBSetup<SMAccDistInZone>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
                {
                    mHasSetup = true;
                }
            }
        }
    }
}

void SMAccDistInZone::CheckInvalidateSetup()
{
    mLastState = 4;

    int currentBars = iBars(Symbol(), Period());
    if (currentBars > mBarCount)
    {
        double sma = iMA(Symbol(), Period(), 200, 0, MODE_SMA, PRICE_CLOSE, 1);
        if (mSetupType == OP_BUY)
        {
            if (iLow(Symbol(), Period(), 1) < sma)
            {
                InvalidateSetup(true);

                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(Symbol(), Period(), 1) > sma)
            {
                InvalidateSetup(true);

                return;
            }
        }

        if (EAHelper::CheckBrokeMBRangeStart<SMAccDistInZone>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            InvalidateSetup(true);

            return;
        }

        if (!mHasSetup)
        {
            return;
        }

        // End of Confirmation TF First MB
        if (EAHelper::CheckBrokeMBRangeEnd<SMAccDistInZone>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            InvalidateSetup(false);
            return;
        }
    }
}

void SMAccDistInZone::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;

    mHasSetup = false;

    mCrossedBelowSMA = false;
    mCrossedAboveSMA = false;

    mCrossedSMATime = 0;

    EAHelper::InvalidateSetup<SMAccDistInZone>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
}

bool SMAccDistInZone::Confirmation()
{
    mLastState = 5;

    int currentBars = iBars(Symbol(), 1);
    if (currentBars > mBarCount)
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return false;
        }

        if (!tempMBState.ClosestValidZoneIsHolding(tempMBState.EndIndex() + 1))
        {
            return false;
        }

        if (mSetupType == OP_BUY)
        {
            // if (mCSPT.HasAccumulation())
            // {

            // }
        }
        else if (mSetupType == OP_SELL)
        {
            if (mCSPT.DistributionHasLPSY())
            {
                return true;
            }
        }
    }

    return mCurrentSetupTicket.Number() != EMPTY;
}

void SMAccDistInZone::PlaceOrders()
{
    // if (mPreviousSetupTickets.Size() > 0)
    // {
    //     mHasSetup = false;

    //     mCrossedBelowSMA = false;
    //     mCrossedAboveSMA = false;

    //     mCrossedSMATime = 0;

    //     return;
    // }

    mLastState = 6;

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    if (mSetupType == OP_SELL)
    {
        int sows = iBarShift(Symbol(), Period(), mCSPT.DistributionSignOfWeaknessStart());

        if (iHigh(Symbol(), Period(), 1) > iHigh(Symbol(), Period(), sows))
        {
            return;
        }

        if (iHigh(Symbol(), Period(), 1) > iLow(Symbol(), Period(), sows))
        {
            GetLastError();
            RefreshRates();
            double stopLoss = iHigh(Symbol(), Period(), sows) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
            int ticket = OrderSend(Symbol(), OP_SELL, 0.1, Ask, 10, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);

            string info = "SOWS: " + sows;
            RecordError(-321, info);

            EAHelper::PostPlaceOrderChecks<SMAccDistInZone>(this, ticket, GetLastError());
            mHasSetup = false;

            mCrossedBelowSMA = false;
            mCrossedAboveSMA = false;

            mCrossedSMATime = 0;
        }
    }
}

void SMAccDistInZone::ManageCurrentPendingSetupTicket()
{
    mLastState = 6;
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int error = mCurrentSetupTicket.SelectIfOpen("Managing Order");
    if (error != Errors::NO_ERROR)
    {
        RecordError(-55);
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(Symbol(), Period(), 1) < OrderStopLoss())
        {
            mHasSetup = false;

            mCrossedBelowSMA = false;
            mCrossedAboveSMA = false;

            mCrossedSMATime = 0;

            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(Symbol(), Period(), 1) > OrderStopLoss())
        {
            mHasSetup = false;

            mCrossedBelowSMA = false;
            mCrossedAboveSMA = false;

            mCrossedSMATime = 0;

            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void SMAccDistInZone::ManageCurrentActiveSetupTicket()
{
}

bool SMAccDistInZone::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // mLastState = 7;
    return false;
}

void SMAccDistInZone::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<SMAccDistInZone>(this, ticketIndex);
}

void SMAccDistInZone::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<SMAccDistInZone>(this);
}

void SMAccDistInZone::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<SMAccDistInZone>(this, ticketIndex);
}

void SMAccDistInZone::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<SMAccDistInZone>(this);
}

void SMAccDistInZone::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<SMAccDistInZone>(this, oldTicketIndex, newTicketNumber);
}

void SMAccDistInZone::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<SMAccDistInZone>(this, ticket, 60);
}

void SMAccDistInZone::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<SMAccDistInZone>(this, error, additionalInformation);
}

void SMAccDistInZone::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}