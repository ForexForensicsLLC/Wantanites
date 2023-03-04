//+------------------------------------------------------------------+
//|                                                    GridHedge.mqh |
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
#include <Wantanites\Framework\Objects\PriceGridTracker.mqh>

class GridHedge : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    PriceGridTracker *mPGT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    int mFurthestAchievedLevel;
    bool mSetupCompleted;

    double mStartingEquity;
    double mMaxEquityDrawDown;

    double mLotSize;
    datetime mEntryCandleTime;

public:
    GridHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt);
    ~GridHedge();

    double RSI(int index) { return iRSI(mEntrySymbol, mEntryTimeFrame, 14, PRICE_CLOSE, index); }
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

GridHedge::GridHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPGT = pgt;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mFurthestAchievedLevel = -1;
    mSetupCompleted = false;

    mStartingEquity = 0.0;
    mMaxEquityDrawDown = 0.0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<GridHedge>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<GridHedge, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<GridHedge, SingleTimeFrameEntryTradeRecord>(this);
}

GridHedge::~GridHedge()
{
    Print("Max Equity Draw Down: ", mMaxEquityDrawDown);
}

void GridHedge::Run()
{
    EAHelper::Run<GridHedge>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool GridHedge::AllowedToTrade()
{
    return EAHelper::BelowSpread<GridHedge>(this) && EAHelper::WithinTradingSession<GridHedge>(this);
}

void GridHedge::CheckSetSetup()
{
    if (RSI(2) >= 70 && RSI(1) < 70)
    {
        mPGT.SetStartingPrice(iOpen(mEntrySymbol, mEntryTimeFrame, 0));
        mHasSetup = true;
    }
}

void GridHedge::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupCompleted)
    {
        InvalidateSetup(false);
    }
}

void GridHedge::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<GridHedge>(this, deletePendingOrder, mStopTrading, error);

    mSetupCompleted = false;
    mFurthestAchievedLevel = -1;
    mPGT.Reset();
}

bool GridHedge::Confirmation()
{
    if (mPGT.CurrentLevel() > mFurthestAchievedLevel)
    {
        mFurthestAchievedLevel = mPGT.CurrentLevel();
        return true;
    }

    return false;
}

void GridHedge::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    double lotSize = mLotSize;
    double takeProfit = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        takeProfit = mPGT.LevelPrice(mPGT.CurrentLevel() + 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        takeProfit = mPGT.LevelPrice(mPGT.CurrentLevel() - 1);
        if (mPreviousSetupTickets.Size() == 0)
        {
            lotSize *= 2;
        }
        else
        {
            lotSize *= MathPow(2, mPreviousSetupTickets.Size() + 1);
        }
    }

    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountBalance();
    }

    EAHelper::PlaceMarketOrder<GridHedge>(this, entry, stopLoss, lotSize, mSetupType, takeProfit);
}

void GridHedge::ManageCurrentPendingSetupTicket()
{
}

void GridHedge::ManageCurrentActiveSetupTicket()
{
}

bool GridHedge::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void GridHedge::ManagePreviousSetupTicket(int ticketIndex)
{
    double currentEquity = (AccountEquity() - mStartingEquity) / AccountEquity() * 100;
    if (currentEquity < mMaxEquityDrawDown)
    {
        mMaxEquityDrawDown = currentEquity;
    }

    // pushed down one level, should be able to close everything with a profit
    if (mPGT.CurrentLevel() == (mFurthestAchievedLevel - 1))
    {
        mPreviousSetupTickets[ticketIndex].Close();
        mSetupCompleted = true;
        return;
    }
}

void GridHedge::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<GridHedge>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<GridHedge>(this);
}

void GridHedge::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<GridHedge>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<GridHedge>(this, ticketIndex);
}

void GridHedge::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<GridHedge>(this);
}

void GridHedge::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<GridHedge>(this, partialedTicket, newTicketNumber);
}

void GridHedge::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<GridHedge>(this, ticket, Period());
}

void GridHedge::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<GridHedge>(this, error, additionalInformation);
}

void GridHedge::Reset()
{
}