//+------------------------------------------------------------------+
//|                                                      MBEntry.mqh |
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

class MBEntry : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mLastCheckedSetupMB;
    int mLastCheckedConfirmationMB;

    int mFirstMBInSetupNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

    int mTimeFrame;

    int mEASetupType;
    int mTempFirstMBInSetup;

public:
    MBEntry(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
            CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
            CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBEntry();

    virtual int MagicNumber() { return mEASetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }

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

MBEntry::MBEntry(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;

    mFirstMBInSetupNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBEntry>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBEntry, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBEntry, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<MBEntry>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<MBEntry>(this);
    }

    mSetupMBsCreated = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mTimeFrame = 1;
    mTempFirstMBInSetup = EMPTY;
}

MBEntry::~MBEntry()
{
}

void MBEntry::Run()
{
    int currentCandles = iBars(Symbol(), Period());
    if (currentCandles > mBarCount)
    {
        EAHelper::RunDrawMBT<MBEntry>(this, mSetupMBT);

        mBarCount = currentCandles;
    }
}

bool MBEntry::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBEntry>(this);
}

void MBEntry::CheckSetSetup()
{
    if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    {
        if (EAHelper::CheckSetSingleMBSetup<MBEntry>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
        {
            mHasSetup = true;
        }

        mSetupMBsCreated = mSetupMBT.MBsCreated();
    }
}

void MBEntry::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        mFirstMBInSetupNumber = EMPTY;
        InvalidateSetup(true);
    }
}

void MBEntry::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBEntry>(this, deletePendingOrder, false, error);
}

bool MBEntry::Confirmation()
{
    // bool hasConfirmation = false;
    // int error = EAHelper::ImbalanceDojiInZone<MBEntry>(this, mSetupMBT, mFirstMBInSetupNumber, 0.2, hasConfirmation);
    // if (error != ERR_NO_ERROR)
    // {
    //     mHasSetup = false;
    //     mFirstMBInSetupNumber = EMPTY;
    //     return false;
    // }
    if (!mSetupMBT.MBIsMostRecent(mFirstMBInSetupNumber))
    {
        RecordError(-1);
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        RecordError(-2);
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        // RecordError(-3);
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        if (iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 2) < iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 2) &&
            iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) < iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 1))
        {
            double firstLow = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), 2);
            return firstLow <= tempZoneState.EntryPrice() && firstLow >= tempZoneState.ExitPrice();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 2) > iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 2) &&
            iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) > iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 1))
        {
            double firstHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), 2);
            return firstHigh >= tempZoneState.EntryPrice() && firstHigh <= tempZoneState.ExitPrice();
        }
    }

    return false;
}

void MBEntry::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    mLastState = 6;

    double entryPrice;
    double stopLoss;
    int type;

    if (mSetupType == OP_BUY)
    {
        entryPrice = iHigh(Symbol(), Period(), 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
        stopLoss = iLow(Symbol(), Period(), 2) - OrderHelper::PipsToRange(mStopLossPaddingPips);
        type = OP_BUYSTOP;
    }
    else if (mSetupType == OP_SELL)
    {
        entryPrice = iLow(Symbol(), Period(), 1);
        stopLoss = iHigh(Symbol(), Period(), 2) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips);
        type = OP_SELLSTOP;
    }

    GetLastError();
    int ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
    EAHelper::PostPlaceOrderChecks<MBEntry>(this, ticket, GetLastError());
    // MBState *tempMBState;
    // if (!mSetupMBT.GetNthMostRecentMB(0, tempMBState))
    // {
    //     RecordError(TerminalErrors::MB_DOES_NOT_EXIST);
    // }

    // EAHelper::PlaceStopOrderForCandelBreak<MBEntry>(this, Symbol(), Period(), 1);
    // if (MathAbs(iHigh(Symbol(), Period(), tempMBState.HighIndex()) - iLow(Symbol(), Period(), tempMBState.LowIndex())) <= 70)
    // {
    // int type = EMPTY;
    // double entryPrice = 0.0;
    // double stopLoss = 0.0;
    // int ticket = EMPTY;

    // GetLastError();
    // if (mEASetupType == OP_BUY && tempMBState.Type() == OP_BUY)
    // {
    //     type = OP_BUY;
    //     entryPrice = Ask;
    //     stopLoss = iLow(Symbol(), Period(), tempMBState.LowIndex()) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    // }
    // else if (mEASetupType == OP_SELL && tempMBState.Type() == OP_SELL)
    // {
    //     type = OP_SELL;
    //     entryPrice = Bid;
    //     stopLoss = iHigh(Symbol(), Period(), tempMBState.HighIndex()) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    // }

    // if (type != EMPTY)
    // {
    //     ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
    //     EAHelper::PostPlaceOrderChecks<MBEntry>(this, ticket, GetLastError());

    //     string info = "Total MBs: " + mSetupMBT.MBsCreated() + " Current MB: " + tempMBState.Number();
    //     RecordError(-777, info);
    // }
    //}

    mHasSetup = false;
}

void MBEntry::ManageCurrentPendingSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int selectError = mCurrentSetupTicket.SelectIfOpen("Managing");
    if (selectError != ERR_NO_ERROR)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(Symbol(), Period(), 1) < OrderStopLoss())
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(Symbol(), Period(), 1) > OrderStopLoss())
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void MBEntry::ManageCurrentActiveSetupTicket()
{
}

bool MBEntry::MoveToPreviousSetupTickets(Ticket &ticket)
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return false;
    }

    bool isActive;
    int activeError = mCurrentSetupTicket.IsActive(isActive);
    if (activeError != ERR_NO_ERROR)
    {
        return false;
    }

    return isActive;
}

void MBEntry::ManagePreviousSetupTicket(int ticketIndex)
{
    // EAHelper::CheckPartialPreviousSetupTicket<MBEntry>(this, ticketIndex);
}

void MBEntry::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<MBEntry>(this);
}

void MBEntry::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<MBEntry>(this, ticketIndex);
}

void MBEntry::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<MBEntry>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT);
}

void MBEntry::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBEntry>(this, oldTicketIndex, newTicketNumber);
}

void MBEntry::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBEntry>(this, ticket, Period());
}

void MBEntry::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBEntry>(this, error, additionalInformation);
}

void MBEntry::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}