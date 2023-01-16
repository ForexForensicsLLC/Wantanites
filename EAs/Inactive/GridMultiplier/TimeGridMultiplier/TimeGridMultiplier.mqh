//+------------------------------------------------------------------+
//|                                                    TimeGridMultiplier.mqh |
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
#include <SummitCapital\Framework\Objects\TimeGridTracker.mqh>

class TimeGridMultiplier : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeGridTracker *mTGT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLotSize;

    int mBarCount;
    int mLastDay;
    int mFurthestAchievedLevel;

public:
    TimeGridMultiplier(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeGridTracker *&tgt);
    ~TimeGridMultiplier();

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

TimeGridMultiplier::TimeGridMultiplier(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeGridTracker *&tgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTGT = tgt;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLotSize = 0.0;

    mBarCount = 0;
    mLastDay = Day();
    mFurthestAchievedLevel = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TimeGridMultiplier>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TimeGridMultiplier, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TimeGridMultiplier, SingleTimeFrameEntryTradeRecord>(this);
}

TimeGridMultiplier::~TimeGridMultiplier()
{
}

void TimeGridMultiplier::Run()
{
    mTGT.Draw();
    EAHelper::Run<TimeGridMultiplier>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool TimeGridMultiplier::AllowedToTrade()
{
    return EAHelper::BelowSpread<TimeGridMultiplier>(this) && EAHelper::WithinTradingSession<TimeGridMultiplier>(this);
}

void TimeGridMultiplier::CheckSetSetup()
{
    if (mSetupType == OP_BUY)
    {
    }
    else if (mSetupType == OP_SELL)
    {
    }

    // reached a new level that we haven't been at before
    if (mTGT.CurrentLevel() <= 1 &&
        mTGT.CurrentLevel() > -6 &&
        mTGT.CurrentLevel() < mFurthestAchievedLevel)
    {
        mHasSetup = true;
        mFurthestAchievedLevel = mTGT.CurrentLevel();
    }
}

void TimeGridMultiplier::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // if (mLastDay != Day() || mTGT.CurrentLevel() >= 1)
    // {
    //     InvalidateSetup(true);
    //     mFurthestAchievedLevel = 0; // move this here so that we dont' reset it when we invalidate after placing an order
    // }
}

void TimeGridMultiplier::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TimeGridMultiplier>(this, deletePendingOrder, mStopTrading, error);
}

bool TimeGridMultiplier::Confirmation()
{
    return true;
}

void TimeGridMultiplier::PlaceOrders()
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
        entry = currentTick.ask;
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = mTGT.LevelPrice(mTGT.CurrentLevel() + 1);
    }

    EAHelper::PlaceMarketOrder<TimeGridMultiplier>(this, entry, stopLoss, mLotSize);
    InvalidateSetup(false);
}

void TimeGridMultiplier::ManageCurrentPendingSetupTicket()
{
}

void TimeGridMultiplier::ManageCurrentActiveSetupTicket()
{
}

bool TimeGridMultiplier::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void TimeGridMultiplier::ManagePreviousSetupTicket(int ticketIndex)
{
    // no matter what close if we've hit the 6th level
    if (mTGT.CurrentLevel() == -6)
    {
        mPreviousSetupTickets[0].Close();
        return;
    }

    if (mSetupType == OP_BUY)
    {
        // close all buys that we've accumulated once we retrace into the positive levels
        if (mTGT.CurrentLevel() == 1)
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // should close the previous ticket after we've entered a new one
        if (mPreviousSetupTickets.Size() >= 2)
        {
            mPreviousSetupTickets[0].Close();
        }
    }
}

void TimeGridMultiplier::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeGridMultiplier>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TimeGridMultiplier>(this);
}

void TimeGridMultiplier::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeGridMultiplier>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TimeGridMultiplier>(this, ticketIndex);
}

void TimeGridMultiplier::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TimeGridMultiplier>(this);
}

void TimeGridMultiplier::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TimeGridMultiplier>(this, partialedTicket, newTicketNumber);
}

void TimeGridMultiplier::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TimeGridMultiplier>(this, ticket, Period());
}

void TimeGridMultiplier::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TimeGridMultiplier>(this, error, additionalInformation);
}

void TimeGridMultiplier::Reset()
{
}