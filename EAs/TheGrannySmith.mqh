//+------------------------------------------------------------------+
//|                                                    TheGrannySmith.mqh |
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

class TheGrannySmith : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    int mSetupMBsCreated;

    datetime mEntryCandleTime;
    datetime mStopLossCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;
    int mLastEntryZone;

    int mMBCount;
    int mLastDay;

    double mImbalanceCandlePercentChange;

public:
    TheGrannySmith(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheGrannySmith();

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

TheGrannySmith::TheGrannySmith(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;
    mFirstMBInSetupNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheGrannySmith>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheGrannySmith, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheGrannySmith, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<TheGrannySmith>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<TheGrannySmith>(this);
    }

    mSetupMBsCreated = 0;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;

    mLastEntryMB = EMPTY;
    mLastEntryZone = EMPTY;

    mMBCount = 0;
    mLastDay = 0;

    mImbalanceCandlePercentChange = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();
}

TheGrannySmith::~TheGrannySmith()
{
}

void TheGrannySmith::Run()
{
    EAHelper::RunDrawMBT<TheGrannySmith>(this, mSetupMBT);
}

bool TheGrannySmith::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheGrannySmith>(this) /* && (Hour() >= 16 && Hour() < 23) */;
}

void TheGrannySmith::CheckSetSetup()
{
    if (mLastDay != Day())
    {
        mMBCount = 0;
        mLastDay = Day();
    }

    // if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    // {
    //     mSetupMBsCreated = mSetupMBT.MBsCreated();
    //     mMBCount += 1;
    // }

    if (EAHelper::CheckSetSingleMBSetup<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        // MBState *tempMBState;
        // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        // {
        //     return;
        // }

        // if (!tempMBState.HasImpulseValidation())
        // {
        //     return;
        // }

        mHasSetup = true;
    }
}

void TheGrannySmith::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        mHasSetup = false;
        mFirstMBInSetupNumber = EMPTY;
    }
}

void TheGrannySmith::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheGrannySmith>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;
}

bool TheGrannySmith::Confirmation()
{
    bool zoneIsHolding = false;
    int error = EAHelper::MostRecentMBZoneIsHolding<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);
    if (error != ERR_NO_ERROR)
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

    double minWickLength = 18;
    if (mSetupType == OP_BUY)
    {
        if (MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, 1), iClose(mEntrySymbol, mEntryTimeFrame, 1)) - iLow(mEntrySymbol, mEntryTimeFrame, 1) < minWickLength)
        {
            return false;
        }

        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) > tempZoneState.EntryPrice())
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) - MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, 1), iClose(mEntrySymbol, mEntryTimeFrame, 1)) < minWickLength)
        {
            return false;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) < tempZoneState.EntryPrice())
        {
            return false;
        }
    }

    double minPercentChange = 0.5;
    double mbValChange = MathAbs((iOpen(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex()) - iClose(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex())) /
                                 iOpen(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex()));

    mbValChange = false;
    int zoneImbalance = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    double zoneImbalanceChange = MathAbs((iOpen(mEntrySymbol, mEntryTimeFrame, zoneImbalance) - iClose(mEntrySymbol, mEntryTimeFrame, zoneImbalance)) /
                                         iOpen(mEntrySymbol, mEntryTimeFrame, zoneImbalance));

    bool hasConfirmation = zoneIsHolding && ((mbValChange > (minPercentChange / 100)) || (zoneImbalanceChange > (minPercentChange / 100)));

    if (hasConfirmation)
    {
        mEntryCandleTime = iTime(Symbol(), Period(), 1);
        mStopLossCandleTime = iTime(Symbol(), Period(), 1);
    }

    return hasConfirmation;
}

void TheGrannySmith::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    MBState *mostRecentMB;
    if (!mSetupMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return;
    }

    ZoneState *holdingZone;
    if (!mostRecentMB.GetClosestValidZone(holdingZone))
    {
        return;
    }

    int type;
    double entry;
    double stopLoss;

    if (mSetupType == OP_BUY)
    {
        entry = Ask;
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < stopLoss)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = Bid;
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > stopLoss)
        {
            return;
        }
    }

    int ticket = OrderSend(mEntrySymbol, mSetupType, 0.1, entry, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
    EAHelper::PostPlaceOrderChecks<TheGrannySmith>(this, ticket, GetLastError());
    // EAHelper::PlaceStopOrderForCandelBreak<TheGrannySmith>(this, mEntrySymbol, mEntryTimeFrame, mEntryCandleTime, mStopLossCandleTime);

    mLastEntryMB = mostRecentMB.Number();
    mLastEntryZone = holdingZone.Number();

    if (mLastEntryMB != mostRecentMB.Number() || mLastEntryZone != holdingZone.Number())
    {
    }
}

void TheGrannySmith::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (entryCandleIndex >= 2)
    {
        InvalidateSetup(true);
    }

    // EAHelper::CheckBrokePastCandle<TheGrannySmith>(this, mEntrySymbol, mEntryTimeFrame, mSetupType, mEntryCandleTime);
    // EAHelper::CheckEditStopLossForTheLittleDipper<TheGrannySmith>(this);
}

void TheGrannySmith::ManageCurrentActiveSetupTicket()
{
    // Test BE with candle past
    // Test with Trail with candles after they close up to BE
    // EAHelper::MoveToBreakEvenAfterMBValidation<TheGrannySmith>(this, mSetupMBT, mLastEntryMB);
    // EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry<TheGrannySmith>(this);
}

bool TheGrannySmith::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheGrannySmith>(this, ticket);
}

void TheGrannySmith::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<TheGrannySmith>(this);
}

void TheGrannySmith::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<TheGrannySmith>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT, mMBCount, mLastEntryZone);
}

void TheGrannySmith::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheGrannySmith>(this, oldTicketIndex, newTicketNumber);
}

void TheGrannySmith::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheGrannySmith>(this, ticket, Period());
}

void TheGrannySmith::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheGrannySmith>(this, error, additionalInformation);
}

void TheGrannySmith::Reset()
{
    mMBCount = 0;
}