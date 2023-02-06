//+------------------------------------------------------------------+
//|                                                    GridHedgeContinuation.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\EA\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>
#include <WantaCapital\Framework\Objects\TimeGridTracker.mqh>

#include <WantaCapital\Framework\Symbols\NASDAQ.mqh>

class GridHedgeContinuation : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeGridTracker *mTGT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mStartingEquity;
    int mLastAchievedLevel;

    double mLotSize;
    double mTargetPips;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    GridHedgeContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                          CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                          CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeGridTracker *&tgt);
    ~GridHedgeContinuation();

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
    virtual bool ShouldReset();
    virtual void Reset();
};

GridHedgeContinuation::GridHedgeContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeGridTracker *&tgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTGT = tgt;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mStartingEquity = 0;
    mLastAchievedLevel = 10000;

    mEntryPaddingPips = 0.0;
    mTargetPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<GridHedgeContinuation>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<GridHedgeContinuation, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<GridHedgeContinuation, SingleTimeFrameEntryTradeRecord>(this);
}

GridHedgeContinuation::~GridHedgeContinuation()
{
}

void GridHedgeContinuation::Run()
{
    mTGT.Draw();
    EAHelper::Run<GridHedgeContinuation>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool GridHedgeContinuation::AllowedToTrade()
{
    return EAHelper::BelowSpread<GridHedgeContinuation>(this) && EAHelper::WithinTradingSession<GridHedgeContinuation>(this);
}

void GridHedgeContinuation::CheckSetSetup()
{
    if (mStartingEquity == 0)
    {
        mStartingEquity = AccountBalance();
    }

    if (mTGT.CurrentLevel() > 0 &&
        (mTGT.CurrentLevel() != mLastAchievedLevel || mLastAchievedLevel == 10000))
    {
        mHasSetup = true;
        mLastAchievedLevel = mTGT.CurrentLevel();
        return;
    }

    if (mTGT.CurrentLevel() < 0 &&
        mTGT.CurrentLevel() != mLastAchievedLevel)
    {
        mHasSetup = true;
        mLastAchievedLevel = mTGT.CurrentLevel();
        return;
    }
}

void GridHedgeContinuation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day())
    {
        // move these here so that we dont' reset it when we invalidate after placing an order
        mLastAchievedLevel = 10000;
        mStartingEquity = 0;

        InvalidateSetup(true);
    }
}

void GridHedgeContinuation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<GridHedgeContinuation>(this, deletePendingOrder, mStopTrading, error);
}

bool GridHedgeContinuation::Confirmation()
{
    return true;
}

void GridHedgeContinuation::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    int type = EMPTY;
    double lotSize = mLotSize;

    if (mTGT.CurrentLevel() > 0)
    {
        entry = currentTick.ask;
        type = OP_BUY;
    }
    else if (mTGT.CurrentLevel() < 0)
    {
        entry = currentTick.bid;
        type = OP_SELL;
    }

    double currentDrawdown = 0.0;
    double currentLots = 0.0;
    double lossesToCover = 0.0;
    Print("Tickets: ", mPreviousSetupTickets.Size());
    for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
    {
        mPreviousSetupTickets[i].SelectIfOpen("Adding drawdown");
        currentDrawdown += OrderProfit();
        if (OrderType() != type)
        {
            currentLots += OrderLots();
            lossesToCover += (OrderLots() * NASDAQ::PipValuePerLot() *
                              ((MarketInfo(Symbol(), MODE_SPREAD) / 10 * 2) + mTargetPips + OrderHelper::RangeToPips(MathAbs(entry - OrderOpenPrice()))));
        }
    }

    Print("Current Drawdown: ", currentDrawdown, ", Current Lots: ", currentLots, ", Losses To Cover: ", lossesToCover);
    double valuePerPipPerLot = NASDAQ::PipValuePerLot();
    double equityTarget = (AccountBalance() * 0.001) /* + MathAbs(lossesToCover)*/;
    double profitPerPip = equityTarget / mTargetPips;
    lotSize = equityTarget / valuePerPipPerLot / mTargetPips;
    Print("Value / Pip / Lot: ", valuePerPipPerLot, ", Pip Target: ", mTargetPips, ", Equity Target: ", equityTarget, ", Profit / Pip: ", profitPerPip, ", Lots: ", lotSize);

    lotSize += (currentLots * 2);
    EAHelper::PlaceMarketOrder<GridHedgeContinuation>(this, entry, 0.0, lotSize, type, 0.0);
    InvalidateSetup(false);
}

void GridHedgeContinuation::ManageCurrentPendingSetupTicket()
{
}

void GridHedgeContinuation::ManageCurrentActiveSetupTicket()
{
}

bool GridHedgeContinuation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void GridHedgeContinuation::ManagePreviousSetupTicket(int ticketIndex)
{
    if (EAHelper::CloseTicketIfPastTime<GridHedgeContinuation>(this, mPreviousSetupTickets[ticketIndex], 23, 0))
    {
        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<GridHedgeContinuation>(this, mStartingEquity);
    // Print("Equity Percent Change: ", equityPercentChange);
    if (equityPercentChange >= 0.1 || equityPercentChange <= -10)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        mStopTrading = true;
    }
}

void GridHedgeContinuation::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<GridHedgeContinuation>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<GridHedgeContinuation>(this);
}

void GridHedgeContinuation::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<GridHedgeContinuation>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<GridHedgeContinuation>(this, ticketIndex);
}

void GridHedgeContinuation::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<GridHedgeContinuation>(this);
}

void GridHedgeContinuation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<GridHedgeContinuation>(this, partialedTicket, newTicketNumber);
}

void GridHedgeContinuation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<GridHedgeContinuation>(this, ticket, Period());
}

void GridHedgeContinuation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<GridHedgeContinuation>(this, error, additionalInformation);
}

bool GridHedgeContinuation::ShouldReset()
{
    return !EAHelper::WithinTradingSession<GridHedgeContinuation>(this);
}

void GridHedgeContinuation::Reset()
{
    mStopTrading = false;
}