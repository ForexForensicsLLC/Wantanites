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
#include <SummitCapital\Framework\Objects\Dictionary.mqh>

class TimeGridMultiplier : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeGridTracker *mTGT;
    Dictionary<int, int> *mLevelsWithTickets;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLotSize;
    double mMaxEquityDrawDown;

    int mBarCount;
    int mLastDay;

    double mStartingEquity;
    int mPreviousAchievedLevel;
    bool mCloseAllTickets;

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
    mLevelsWithTickets = new Dictionary<int, int>();

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLotSize = 0.0;
    mMaxEquityDrawDown = 0.0;

    mBarCount = 0;
    mLastDay = Day();

    mStartingEquity = 0;
    mPreviousAchievedLevel = 0;
    mCloseAllTickets = false;

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
    mHasSetup = true;
}

void TimeGridMultiplier::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day())
    {
        InvalidateSetup(true);
    }
}

void TimeGridMultiplier::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TimeGridMultiplier>(this, deletePendingOrder, mStopTrading, error);

    mPreviousAchievedLevel = 0;
    mStartingEquity = 0;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
}

bool TimeGridMultiplier::Confirmation()
{
    // this is where we would want to add any rules on levels to add such as max opposite levels, don't start opposite level until x level, etc.
    if (mTGT.CurrentLevel() != mPreviousAchievedLevel && !mLevelsWithTickets.HasKey(mTGT.CurrentLevel()))
    {
        mPreviousAchievedLevel = mTGT.CurrentLevel();
        return true;
    }

    return false;
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
    double takeProfit = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        takeProfit = mTGT.LevelPrice(mTGT.CurrentLevel() + 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        takeProfit = mTGT.LevelPrice(mTGT.CurrentLevel() - 1);
    }

    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountBalance();
    }

    EAHelper::PlaceMarketOrder<TimeGridMultiplier>(this, entry, stopLoss, mLotSize, mSetupType, takeProfit);
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLevelsWithTickets.Add(mTGT.CurrentLevel(), mCurrentSetupTicket.Number());
    }
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
    if (mCloseAllTickets)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<TimeGridMultiplier>(this, mStartingEquity);
    if (equityPercentChange <= mMaxEquityDrawDown)
    {
        mCloseAllTickets = true;
    }
}

void TimeGridMultiplier::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeGridMultiplier>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TimeGridMultiplier>(this);
}

void TimeGridMultiplier::CheckPreviousSetupTicket(int ticketIndex)
{
    bool isClosed = false;
    mPreviousSetupTickets[ticketIndex].IsClosed(isClosed);
    if (isClosed)
    {
        mLevelsWithTickets.RemoveByValue(mPreviousSetupTickets.Number());
    }

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
    InvalidateSetup(false);
}