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
    int mEntryMBNumber;

    double mImbalanceCandlePercentChange;

public:
    TheGrannySmith(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheGrannySmith();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }
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
    mEntryMBNumber = EMPTY;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

TheGrannySmith::~TheGrannySmith()
{
}

double TheGrannySmith::RiskPercent()
{
    double riskPercent = 0.25;

    double percentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;
    // for each one percent that we lost, reduce risk by 0.05 %
    while (percentLost >= 1)
    {
        riskPercent -= 0.05;
        percentLost -= 1;
    }

    return riskPercent;
}

void TheGrannySmith::Run()
{
    EAHelper::RunDrawMBT<TheGrannySmith>(this, mSetupMBT);
}

bool TheGrannySmith::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheGrannySmith>(this) /*&& (Hour() >= 16 && Hour() < 23)*/;
}

void TheGrannySmith::CheckSetSetup()
{
    if (mLastDay != Day())
    {
        mMBCount = 0;
        mLastDay = Day();
    }

    if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    {
        mSetupMBsCreated = mSetupMBT.MBsCreated();
        mMBCount += 1;
    }

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
    int entryCandle = 0;
    bool isTrue = false;
    int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, isTrue, entryCandle);
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

    // double minWickLength = 18;
    // if (mSetupType == OP_BUY)
    // {
    //     if (MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) - iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) <
    //         minWickLength)
    //     {
    //         return false;
    //     }

    //     if (iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) > tempZoneState.EntryPrice())
    //     {
    //         return false;
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) - MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) < minWickLength)
    //     {
    //         return false;
    //     }

    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) < tempZoneState.EntryPrice())
    //     {
    //         return false;
    //     }
    // }

    // double minPercentChange = 0.5; // Nas 15 min
    // double minPercentChange = 0.1; // Currencies & Gold & nas 5 min
    // double mbValChange = MathAbs((iOpen(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex()) - iClose(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex())) /
    //                              iOpen(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex()));

    // mbValChange = false;
    // int zoneImbalance = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    // double zoneImbalanceChange = MathAbs((iOpen(mEntrySymbol, mEntryTimeFrame, zoneImbalance) - iClose(mEntrySymbol, mEntryTimeFrame, zoneImbalance)) /
    //                                      iOpen(mEntrySymbol, mEntryTimeFrame, zoneImbalance));

    // bool hasConfirmation = isTrue && ((mbValChange > (minPercentChange / 100)) || (zoneImbalanceChange > (minPercentChange / 100)));

    bool hasConfirmation = isTrue;
    if (hasConfirmation)
    {
        mEntryCandleTime = iTime(Symbol(), Period(), entryCandle);
        mStopLossCandleTime = iTime(Symbol(), Period(), entryCandle);
        mEntryMBNumber = tempMBState.Number();
    }

    return hasConfirmation;
}

void TheGrannySmith::PlaceOrders()
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

    double entry = 0.0;
    double stopLoss = 0.0;
    // double stopLossPips = 30; // Nas
    double stopLossPips = 0.4; // Currencies
    // double stopLossPips = 1.3; // Gold

    if (mSetupType == OP_BUY)
    {
        entry = Ask;
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 0) - OrderHelper::PipsToRange(mStopLossPaddingPips);
        stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = Bid;
        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 0) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
        stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);
    }

    // double lotSize = OrderHelper::GetLotSize(stopLossPips, RiskPercent());
    int ticket = OrderSend(mEntrySymbol, mSetupType, 0.01, entry, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
    EAHelper::PostPlaceOrderChecks<TheGrannySmith>(this, ticket, GetLastError());
    //  EAHelper::PlaceStopOrderForCandelBreak<TheGrannySmith>(this, mEntrySymbol, mEntryTimeFrame, mEntryCandleTime, mStopLossCandleTime);
    //  EAHelper::PlaceStopOrderForTheLittleDipper<TheGrannySmith>(this);
    // EAHelper::PlaceStopOrder(this, entry, stopLoss);

    mLastEntryMB = mostRecentMB.Number();
    mLastEntryZone = holdingZone.Number();

    mBarCount = currentBars;
}

void TheGrannySmith::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (entryCandleIndex >= 2)
    {
        InvalidateSetup(true);
    }

    // EAHelper::CheckBrokePastCandle<TheGrannySmith>(this, mEntrySymbol, mEntryTimeFrame, mSetupType, mEntryCandleTime);
    //  EAHelper::CheckEditStopLossForTheLittleDipper<TheGrannySmith>(this);
}

void TheGrannySmith::ManageCurrentActiveSetupTicket()
{
    // Test BE with candle past
    // Test with Trail with candles after they close up to BE
    // EAHelper::MoveToBreakEvenAfterMBValidation<TheGrannySmith>(this, mSetupMBT, mLastEntryMB);
    // EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry<TheGrannySmith>(this, false);
    // EAHelper::CloseIfPriceCrossedTicketOpen<TheGrannySmith>(this, 1);
    EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this);
}

bool TheGrannySmith::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheGrannySmith>(this, ticket);
    // TODO: Switch to never move to previous setup tickets to conform to the FIFO Rule
    // Not doing it now so that I can see how for most of my trades run
    // return false;
}

void TheGrannySmith::ManagePreviousSetupTicket(int ticketIndex)
{
    // EAHelper::MoveStopLossToCoverCommissions<TheGrannySmith>(this);
    EAHelper::CheckPartialPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheGrannySmith>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheGrannySmith>(this);
}

void TheGrannySmith::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheGrannySmith>(this, mPreviousSetupTickets[ticketIndex]);
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