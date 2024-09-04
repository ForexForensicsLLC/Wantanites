//+------------------------------------------------------------------+
//|                                                    LiquidationEngulfing.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>

class LiquidationEngulfing : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;

    double mMinPercentBody;
    double mMinBodyPips;

public:
    LiquidationEngulfing(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~LiquidationEngulfing();

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void PreRun();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void PreManageTickets();
    virtual void ManageCurrentPendingSetupTicket(Ticket &ticket);
    virtual void ManageCurrentActiveSetupTicket(Ticket &ticket);
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(Ticket &ticket);
    virtual void CheckCurrentSetupTicket(Ticket &ticket);
    virtual void CheckPreviousSetupTicket(Ticket &ticket);
    virtual void RecordTicketOpenData(Ticket &ticket);
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

LiquidationEngulfing::LiquidationEngulfing(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = setupMBT;
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;

    mMinPercentBody = 0.0;
    mMinBodyPips = 0.0;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<LiquidationEngulfing>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<LiquidationEngulfing, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<LiquidationEngulfing, SingleTimeFrameEntryTradeRecord>(this);

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

LiquidationEngulfing::~LiquidationEngulfing()
{
}

void LiquidationEngulfing::PreRun()
{
    EARunHelper::ShowOpenTicketProfit<LiquidationEngulfing>(this);
    mMBT.Draw();
}

bool LiquidationEngulfing::AllowedToTrade()
{
    return EARunHelper::BelowSpread<LiquidationEngulfing>(this) && EARunHelper::WithinTradingSession<LiquidationEngulfing>(this);
}

void LiquidationEngulfing::CheckSetSetup()
{
    if (EASetupHelper::CheckSetSingleMBSetup<LiquidationEngulfing>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
    {
        if (mFirstMBInSetupNumber != 55)
        {
            return;
        }

        mHasSetup = true;
    }
}

void LiquidationEngulfing::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != ConstantValues::EmptyInt)
    {
        // invalidate if we are not the most recent MB
        if (mMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            // Print("New MB INvalidation");
            InvalidateSetup(true);
        }
    }
}

void LiquidationEngulfing::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<LiquidationEngulfing>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;
}

bool LiquidationEngulfing::Confirmation()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return false;
    }

    if (!EASetupHelper::MostRecentMBZoneIsHolding<LiquidationEngulfing>(this, mMBT, mFirstMBInSetupNumber))
    {
        return false;
    }

    bool confirmation = false;
    if (SetupType() == SignalType::Bullish)
    {
        confirmation = iLow(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), 2) &&
                       iClose(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), 2) &&
                       EASetupHelper::CandleIsInZone<LiquidationEngulfing>(this, mMBT, mFirstMBInSetupNumber, 1, false);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        confirmation = iHigh(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), 2) &&
                       iClose(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), 2) &&
                       EASetupHelper::CandleIsInZone<LiquidationEngulfing>(this, mMBT, mFirstMBInSetupNumber, 1, false);
    }

    return confirmation;
}

void LiquidationEngulfing::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        stopLoss = iLow(EntrySymbol(), EntryTimeFrame(), 1);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        stopLoss = iHigh(EntrySymbol(), EntryTimeFrame(), 1);
    }

    EAOrderHelper::PlaceMarketOrder<LiquidationEngulfing>(this, entry, stopLoss);
}

void LiquidationEngulfing::PreManageTickets()
{
}

void LiquidationEngulfing::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void LiquidationEngulfing::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool LiquidationEngulfing::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void LiquidationEngulfing::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void LiquidationEngulfing::CheckCurrentSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<LiquidationEngulfing>(this, ticket);
}

void LiquidationEngulfing::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void LiquidationEngulfing::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<LiquidationEngulfing>(this, ticket);
}

void LiquidationEngulfing::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EARecordHelper::RecordPartialTradeRecord<LiquidationEngulfing>(this, partialedTicket, newTicketNumber);
}

void LiquidationEngulfing::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<LiquidationEngulfing>(this, ticket);
}

void LiquidationEngulfing::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<LiquidationEngulfing>(this, methodName, error, additionalInformation);
}

bool LiquidationEngulfing::ShouldReset()
{
    return false;
}

void LiquidationEngulfing::Reset()
{
}