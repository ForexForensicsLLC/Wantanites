//+------------------------------------------------------------------+
//|                                                    FFTradeManager.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>

class FFTradeManager : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mStopLossPrice;

public:
    FFTradeManager(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~FFTradeManager();

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

FFTradeManager::FFTradeManager(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mStopLossPrice = ConstantValues::EmptyDouble;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<FFTradeManager>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<FFTradeManager, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<FFTradeManager, SingleTimeFrameEntryTradeRecord>(this);

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

FFTradeManager::~FFTradeManager()
{
}

void FFTradeManager::PreRun()
{
    EARunHelper::ShowOpenTicketProfit<FFTradeManager>(this);
}

bool FFTradeManager::AllowedToTrade()
{
    return EARunHelper::BelowSpread<FFTradeManager>(this) && EARunHelper::WithinTradingSession<FFTradeManager>(this);
}

void FFTradeManager::CheckSetSetup()
{
}

void FFTradeManager::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void FFTradeManager::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<FFTradeManager>(this, deletePendingOrder, false, error);
    mStopLossPrice = ConstantValues::EmptyDouble;
}

bool FFTradeManager::Confirmation()
{
    return false;
}

void FFTradeManager::PlaceOrders()
{
    double entry = 0.0;
    double lotSize = 0.0;
    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        lotSize = EAOrderHelper::GetMaxLotSizeForMargin<FFTradeManager>(this, TicketType::Buy, entry, mStopLossPrice, 5);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        lotSize = EAOrderHelper::GetMaxLotSizeForMargin<FFTradeManager>(this, TicketType::Sell, entry, mStopLossPrice, 5);
    }

    EAOrderHelper::PlaceMarketOrder<FFTradeManager>(this, entry, mStopLossPrice, lotSize);
}

void FFTradeManager::PreManageTickets()
{
}

void FFTradeManager::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void FFTradeManager::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool FFTradeManager::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void FFTradeManager::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void FFTradeManager::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void FFTradeManager::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void FFTradeManager::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<FFTradeManager>(this, ticket);
}

void FFTradeManager::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EARecordHelper::RecordPartialTradeRecord<FFTradeManager>(this, partialedTicket, newTicketNumber);
}

void FFTradeManager::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<FFTradeManager>(this, ticket);
}

void FFTradeManager::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<FFTradeManager>(this, methodName, error, additionalInformation);
}

bool FFTradeManager::ShouldReset()
{
    return false;
}

void FFTradeManager::Reset()
{
}