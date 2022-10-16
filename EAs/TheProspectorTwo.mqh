//+------------------------------------------------------------------+
//|                                                TheProspectorTwo.mqh |
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

class TheProspectorTwo : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mFirstMBInSetupNumber;

    datetime mEntryCandleTime;

public:
    TheProspectorTwo(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheProspectorTwo();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::TheBullishProspector : MagicNumbers::TheBearishProspector; }
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

TheProspectorTwo::TheProspectorTwo(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;
    mFirstMBInSetupNumber = EMPTY;

    mBarCount = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEntryCandleTime = 0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheProspectorTwo>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheProspectorTwo, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheProspectorTwo, SingleTimeFrameEntryTradeRecord>(this);
}

TheProspectorTwo::~TheProspectorTwo()
{
}

double TheProspectorTwo::RiskPercent()
{
    // double riskPercent = 0.25;
    // double percentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;

    // // for each one percent that we lost, reduce risk by 0.05 %
    // while (percentLost >= 1)
    // {
    //     riskPercent -= 0.05;
    //     percentLost -= 1;
    // }

    // return riskPercent;
    return 0.0;
}

void TheProspectorTwo::Run()
{
    EAHelper::RunDrawMBT<TheProspectorTwo>(this, mSetupMBT);
}

bool TheProspectorTwo::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheProspectorTwo>(this) && (Hour() >= 16 && Hour() <= 18);
}

void TheProspectorTwo::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<TheProspectorTwo>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void TheProspectorTwo::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        mHasSetup = false;
        mFirstMBInSetupNumber = EMPTY;
    }
}

void TheProspectorTwo::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheProspectorTwo>(this, deletePendingOrder, false, error);
}

bool TheProspectorTwo::Confirmation()
{
    bool zoneIsHolding = false;
    int zoneIsHoldingError = EAHelper::MostRecentMBZoneIsHolding<TheProspectorTwo>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);
    if (zoneIsHoldingError != ERR_NO_ERROR)
    {
        InvalidateSetup(true);
        return false;
    }

    if (!zoneIsHolding)
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

    bool potentialDoji = false;
    bool withinZone = false;

    if (mSetupType == OP_BUY)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
                        iClose(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1);

        withinZone = iLow(mEntrySymbol, mEntryTimeFrame, 0) <= tempZoneState.EntryPrice() && iClose(mEntrySymbol, mEntryTimeFrame, 0) >= tempZoneState.ExitPrice();
    }
    else if (mSetupType == OP_SELL)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
                        iClose(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1);

        withinZone = iHigh(mEntrySymbol, mEntryTimeFrame, 0) >= tempZoneState.EntryPrice() && iClose(mEntrySymbol, mEntryTimeFrame, 0) <= tempZoneState.ExitPrice();
    }

    return mCurrentSetupTicket.Number() != EMPTY || (potentialDoji && withinZone);
}

void TheProspectorTwo::PlaceOrders()
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
    double stopLossPips = 1.3;

    if (mSetupType == OP_BUY)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);

        // don't place the order if it is going to activate right away
        if (currentTick.ask > entry)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);

        if (currentTick.bid < entry)
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<TheProspectorTwo>(this, entry, stopLoss, 0.1);
    mBarCount = currentBars;
    mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
}

void TheProspectorTwo::ManageCurrentPendingSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mEntryCandleTime == 0)
    {
        return;
    }

    if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 0)
    {
        mCurrentSetupTicket.Close();
    }
}

void TheProspectorTwo::ManageCurrentActiveSetupTicket()
{
    EAHelper::MoveToBreakEvenAsSoonAsPossible<TheProspectorTwo>(this, 1);
}

bool TheProspectorTwo::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheProspectorTwo>(this, ticket);
}

void TheProspectorTwo::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TheProspectorTwo>(this, ticketIndex);
}

void TheProspectorTwo::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheProspectorTwo>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheProspectorTwo>(this);
}

void TheProspectorTwo::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheProspectorTwo>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TheProspectorTwo>(this, ticketIndex);
}

void TheProspectorTwo::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheProspectorTwo>(this);
}

void TheProspectorTwo::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheProspectorTwo>(this, oldTicketIndex, newTicketNumber);
}

void TheProspectorTwo::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheProspectorTwo>(this, ticket, Period());
}

void TheProspectorTwo::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheProspectorTwo>(this, error, additionalInformation);
}

void TheProspectorTwo::Reset()
{
}
