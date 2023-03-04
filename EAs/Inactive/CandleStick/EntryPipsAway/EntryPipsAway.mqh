//+------------------------------------------------------------------+
//|                                                    EntryPipsAway.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class EntryPipsAway : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mPipsFromOpen;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    EntryPipsAway(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                  CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                  CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~EntryPipsAway();

    virtual double RiskPercent() { return mRiskPercent; }

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
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

EntryPipsAway::EntryPipsAway(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPipsFromOpen = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EntryPipsAway>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<EntryPipsAway, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EntryPipsAway, SingleTimeFrameEntryTradeRecord>(this);
}

EntryPipsAway::~EntryPipsAway()
{
}

void EntryPipsAway::Run()
{
    EAHelper::Run<EntryPipsAway>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool EntryPipsAway::AllowedToTrade()
{
    return EAHelper::BelowSpread<EntryPipsAway>(this) && EAHelper::WithinTradingSession<EntryPipsAway>(this);
}

void EntryPipsAway::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    mHasSetup = true;
}

void EntryPipsAway::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void EntryPipsAway::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<EntryPipsAway>(this, deletePendingOrder, mStopTrading, error);
}

bool EntryPipsAway::Confirmation()
{
    return true;
}

void EntryPipsAway::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask + OrderHelper::PipsToRange(mPipsFromOpen);
        stopLoss = entry - OrderHelper::PipsToRange(mMinStopLossPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid - OrderHelper::PipsToRange(mPipsFromOpen);
        stopLoss = entry + OrderHelper::PipsToRange(mMinStopLossPips);
    }

    EAHelper::PlaceStopOrder<EntryPipsAway>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void EntryPipsAway::ManageCurrentPendingSetupTicket()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (orderPlaceIndex >= 1)
    {
        InvalidateSetup(true);
    }
}

void EntryPipsAway::ManageCurrentActiveSetupTicket()
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (openIndex >= 1)
    {
        mCurrentSetupTicket.Close();
    }

    EAHelper::MoveToBreakEvenAfterPips<EntryPipsAway>(this, mCurrentSetupTicket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool EntryPipsAway::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<EntryPipsAway>(this, ticket);
}

void EntryPipsAway::ManagePreviousSetupTicket(int ticketIndex)
{
    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mPreviousSetupTickets[ticketIndex].OpenTime());
    if (openIndex >= 1)
    {
        mPreviousSetupTickets[ticketIndex].Close();
    }
}

void EntryPipsAway::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EntryPipsAway>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<EntryPipsAway>(this);
}

void EntryPipsAway::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EntryPipsAway>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<EntryPipsAway>(this, ticketIndex);
}

void EntryPipsAway::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<EntryPipsAway>(this);
}

void EntryPipsAway::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<EntryPipsAway>(this, partialedTicket, newTicketNumber);
}

void EntryPipsAway::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EntryPipsAway>(this, ticket, Period());
}

void EntryPipsAway::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EntryPipsAway>(this, error, additionalInformation);
}

void EntryPipsAway::Reset()
{
}