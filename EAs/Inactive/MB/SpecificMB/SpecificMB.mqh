//+------------------------------------------------------------------+
//|                                                    SpecificMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

#include <Wantanites\Framework\Objects\Indicators\Time\TimeRangeBreakout.mqh>

class SpecificMB : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;
    int mLastMB;

    List<int> *mMBsToEnterOn;

public:
    SpecificMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~SpecificMB();

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

SpecificMB::SpecificMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mLastMB = EMPTY;

    mMBsToEnterOn = new List<int>();
    mMBsToEnterOn.Add(36);
    mMBsToEnterOn.Add(37);
    mMBsToEnterOn.Add(38);
    mMBsToEnterOn.Add(39);
    mMBsToEnterOn.Add(40);
    mMBsToEnterOn.Add(41);
    mMBsToEnterOn.Add(42);
    mMBsToEnterOn.Add(44);

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<SpecificMB>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<SpecificMB, SingleTimeFrameEntryTradeRecord>(this);
}

SpecificMB::~SpecificMB()
{
}

void SpecificMB::PreRun()
{
    mMBT.Draw();
}

bool SpecificMB::AllowedToTrade()
{
    return EARunHelper::BelowSpread<SpecificMB>(this) && EARunHelper::WithinTradingSession<SpecificMB>(this);
}

void SpecificMB::CheckSetSetup()
{
    if (mMBT.GetNthMostRecentMBsType(0) == SetupType())
    {
        int currentMB = mMBT.MBsCreated() - 1;
        if (currentMB != mLastMB && mMBsToEnterOn.Contains(currentMB))
        {
            mLastMB = currentMB;
            mHasSetup = true;
        }
    }
}

void SpecificMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void SpecificMB::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<SpecificMB>(this, deletePendingOrder, mStopTrading, error);
}

bool SpecificMB::Confirmation()
{
    return EASetupHelper::MostRecentMBZoneIsHolding<SpecificMB>(this, mMBT, mMBT.MBsCreated() - 1);
}

void SpecificMB::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
    }

    EAOrderHelper::PlaceMarketOrder<SpecificMB>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void SpecificMB::PreManageTickets()
{
}

void SpecificMB::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void SpecificMB::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool SpecificMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void SpecificMB::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (SetupType() == SignalType::Bearish)
    {
        if (Day() == 24 && Hour() == 18)
        {
            ticket.Close();
        }
    }
}

void SpecificMB::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void SpecificMB::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void SpecificMB::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<SpecificMB>(this, ticket);
}

void SpecificMB::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void SpecificMB::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<SpecificMB>(this, ticket);
}

void SpecificMB::RecordError(string methodName, int error, string additionalInformation = "")
{
    // EARecordHelper::RecordSingleTimeFrameErrorRecord<SpecificMB>(this, methodName, error, additionalInformation);
}

bool SpecificMB::ShouldReset()
{
    return !EARunHelper::WithinTradingSession<SpecificMB>(this);
}

void SpecificMB::Reset()
{
    mStopTrading = false;
}