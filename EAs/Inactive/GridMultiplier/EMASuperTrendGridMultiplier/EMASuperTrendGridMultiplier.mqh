//+------------------------------------------------------------------+
//|                                                    TimeGridMultiplier.mqh |
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

#include <Wantanites\Framework\Objects\SuperTrend.mqh>
#include <Wantanites\Framework\Objects\PriceGridTracker.mqh>
#include <Wantanites\Framework\Objects\Dictionary.mqh>

class TimeGridMultiplier : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    PriceGridTracker *mPGT;
    SuperTrend *mST;
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
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt, SuperTrend *&st);
    ~TimeGridMultiplier();

    double EMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index); }
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
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt, SuperTrend *&st)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPGT = pgt;
    mST = st;
    mLevelsWithTickets = new Dictionary<int, int>();

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLotSize = 0.0;
    mMaxEquityDrawDown = 0.0;

    mBarCount = 0;
    mLastDay = Day();

    mStartingEquity = 0;
    mPreviousAchievedLevel = 1000;
    mCloseAllTickets = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TimeGridMultiplier>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TimeGridMultiplier, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TimeGridMultiplier, SingleTimeFrameEntryTradeRecord>(this);
}

TimeGridMultiplier::~TimeGridMultiplier()
{
    delete mLevelsWithTickets;
}

void TimeGridMultiplier::Run()
{
    mPGT.Draw();
    mST.Draw();
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
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    if (mST.Direction(0) == mSetupType)
    {
        if (mSetupType == OP_BUY)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > EMA(1) && currentTick.bid <= EMA(1))
            {
                mHasSetup = true;
                mPGT.SetStartingPrice(currentTick.bid);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < EMA(1) && currentTick.bid >= EMA(1))
            {
                mHasSetup = true;
                mPGT.SetStartingPrice(currentTick.bid);
            }
        }
    }
}

void TimeGridMultiplier::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(true);
    }
}

void TimeGridMultiplier::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<TimeGridMultiplier>(this, deletePendingOrder, mStopTrading, error);

    mPreviousAchievedLevel = 1000;
    mStartingEquity = 0;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
    mPGT.Reset();
}

bool TimeGridMultiplier::Confirmation()
{
    // going to closes all tickets
    if (mPGT.AtMaxLevel())
    {
        return false;
    }

    if (mPGT.CurrentLevel() != mPreviousAchievedLevel && !mLevelsWithTickets.HasKey(mPGT.CurrentLevel()))
    {
        mPreviousAchievedLevel = mPGT.CurrentLevel();
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
        // don't want to place a tp on the last level because they we won't call ManagePreviousSetupTickets on it to check that we are at the last level
        takeProfit = mPGT.CurrentLevel() == mPGT.MaxLevel() - 1 ? 0.0 : mPGT.LevelPrice(mPGT.CurrentLevel() + 1);
        // stopLoss = mPGT.LevelPrice(mPGT.CurrentLevel() - 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        // don't want to place a tp on the last level because they we won't call ManagePreviousSetupTickets on it to check that we are at the last level
        takeProfit = MathAbs(mPGT.CurrentLevel()) == mPGT.MaxLevel() - 1 ? 0.0 : mPGT.LevelPrice(mPGT.CurrentLevel() - 1);
        // stopLoss = mPGT.LevelPrice(mPGT.CurrentLevel() + 1);
    }

    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountBalance();
    }

    EAHelper::PlaceMarketOrder<TimeGridMultiplier>(this, entry, stopLoss, mLotSize, mSetupType, takeProfit);
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLevelsWithTickets.Add(mPGT.CurrentLevel(), mCurrentSetupTicket.Number());
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

    if (mPGT.AtMaxLevel())
    {
        mCloseAllTickets = true;
        mPreviousSetupTickets[ticketIndex].Close();

        return;
    }

    if (mST.Direction(0) != mSetupType)
    {
        mCloseAllTickets = true;
        mPreviousSetupTickets[ticketIndex].Close();

        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<TimeGridMultiplier>(this, mStartingEquity);
    if (equityPercentChange <= mMaxEquityDrawDown)
    {
        Print("Max Equity Draw Down Achieved: ", equityPercentChange, ", Max Equity Draw Down: ", mMaxEquityDrawDown);
        mCloseAllTickets = true;
        mPreviousSetupTickets[ticketIndex].Close();

        return;
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
        mLevelsWithTickets.RemoveByValue(mPreviousSetupTickets[ticketIndex].Number());
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
}