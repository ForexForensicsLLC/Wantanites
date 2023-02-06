//+------------------------------------------------------------------+
//|                                                    ImpulseReversal.mqh |
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

#include <WantaCapital\Framework\Objects\PriceGridTracker.mqh>
#include <WantaCapital\Framework\Symbols\EURUSD.mqh>

class ImpulseReversal : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    PriceGridTracker *mPGT;

    double mLotSize;
    double mMinPercentChange;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mStartingEquity;
    bool mPlacedFirstTicket;
    int mLastPriceLevel;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

    double mMinEquityDrawDown;

public:
    ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt);
    ~ImpulseReversal();

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

ImpulseReversal::ImpulseReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPGT = pgt;

    mLotSize = 0.0;
    mMinPercentChange = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mStartingEquity = 0.0;
    mPlacedFirstTicket = false;
    mLastPriceLevel = 10000;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mMinEquityDrawDown = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseReversal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseReversal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseReversal, SingleTimeFrameEntryTradeRecord>(this);
}

ImpulseReversal::~ImpulseReversal()
{
    Print("Magic Number: ", MagicNumber(), ", Min Equity DD: ", mMinEquityDrawDown);
}

void ImpulseReversal::Run()
{
    EAHelper::Run<ImpulseReversal>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseReversal::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseReversal>(this) && (EAHelper::WithinTradingSession<ImpulseReversal>(this) || mPreviousSetupTickets.Size() > 0);
}

void ImpulseReversal::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    int furthestIndexCheck = 30;
    int furthestIndex = EMPTY;

    bool hasImbalance = false;
    bool hasMinPercentChange = false;

    if (mSetupType == OP_BUY)
    {
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, furthestIndexCheck, 0, true, furthestIndex))
        {
            return;
        }

        if (furthestIndex > 2)
        {
            return;
        }

        for (int i = 2; i <= 4; i++)
        {
            if (CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i))
            {
                hasImbalance = true;
            }

            if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mMinPercentChange))
            {
                hasMinPercentChange = true;
            }
        }

        if (!hasImbalance || !hasMinPercentChange)
        {
            return;
        }

        mHasSetup = true;
    }
    else if (mSetupType == OP_SELL)
    {
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, furthestIndexCheck, 0, true, furthestIndex))
        {
            return;
        }

        if (furthestIndex > 2)
        {
            return;
        }

        for (int i = 2; i <= 4; i++)
        {
            if (CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i))
            {
                hasImbalance = true;
            }

            if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= OrderHelper::PipsToRange(mMinPercentChange))
            {
                hasMinPercentChange = true;
            }
        }

        if (!hasImbalance || !hasMinPercentChange)
        {
            return;
        }

        mHasSetup = true;
    }
}

void ImpulseReversal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mPlacedFirstTicket && mPreviousSetupTickets.Size() == 0)
    {
        mStopTrading = true;
    }
}

void ImpulseReversal::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseReversal>(this, deletePendingOrder, mStopTrading, error);

    mStartingEquity = 0.0;
    mPlacedFirstTicket = false;
    mLastPriceLevel = 1000;
    mPGT.Reset();
}

bool ImpulseReversal::Confirmation()
{
    // if (mSetupType == OP_BUY)
    // {
    //     if (mPGT.CurrentLevel() <= 0 &&
    //         mPGT.CurrentLevel() < mLastPriceLevel)
    //     {
    //         mLastPriceLevel = mPGT.CurrentLevel();
    //         return true;
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (mPGT.CurrentLevel() >= 0 &&
    //         (mPGT.CurrentLevel() > mLastPriceLevel || mLastPriceLevel == 1000))
    //     {
    //         mLastPriceLevel = mPGT.CurrentLevel();
    //         return true;
    //     }
    // }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        return CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        return CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1);
    }

    return false;
}

void ImpulseReversal::PlaceOrders()
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

        if (mPreviousSetupTickets.Size() > 0 && entry > mPreviousSetupTickets[mPreviousSetupTickets.Size() - 1].OpenPrice())
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;

        if (mPreviousSetupTickets.Size() > 0 && entry < mPreviousSetupTickets[mPreviousSetupTickets.Size() - 1].OpenPrice())
        {
            return;
        }
    }

    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountEquity();
        mPlacedFirstTicket = true;
    }

    double lotSize = mLotSize;
    // int currentTickets = mPreviousSetupTickets.Size();
    // while (currentTickets >= 3)
    // {
    //     lotSize += mLotSize;
    //     currentTickets -= 3;
    // }

    double currentDrawdown = 0.0;
    for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
    {
        mPreviousSetupTickets[i].SelectIfOpen("Adding drawdown");
        currentDrawdown += OrderProfit();
        Print("Order Profit: ", OrderProfit());
    }

    double valuePerPipPerLot = EURUSD::PipValuePerLot();
    double pipTarget = 5;
    double equityTarget = (AccountBalance() * 0.001) + MathAbs(currentDrawdown);
    double profitPerPip = equityTarget / pipTarget;
    Print("Value / Pip / Lot: ", valuePerPipPerLot, ", Pip Target: ", pipTarget, ", Equity Target: ", equityTarget, ", Profit / Pip: ", profitPerPip);

    lotSize = equityTarget / valuePerPipPerLot / pipTarget;
    Print(lotSize);
    EAHelper::PlaceMarketOrder<ImpulseReversal>(this, entry, stopLoss, lotSize);
}

void ImpulseReversal::ManageCurrentPendingSetupTicket()
{
}

void ImpulseReversal::ManageCurrentActiveSetupTicket()
{
}

bool ImpulseReversal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void ImpulseReversal::ManagePreviousSetupTicket(int ticketIndex)
{
    // close all tickets if we are down 10% or up 1%
    double equityPercentChange = (AccountEquity() - mStartingEquity) / AccountEquity() * 100;
    // double equityTarget = MathMax(0.2 / mPreviousSetupTickets.Size(), 0.05);
    // double equityTarget = 1 / mPreviousSetupTickets.Size();
    double equityTarget = .1;

    if (equityPercentChange <= -100 || equityPercentChange > equityTarget)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        return;
    }

    if (equityPercentChange < mMinEquityDrawDown)
    {
        mMinEquityDrawDown = equityPercentChange;
    }
}

void ImpulseReversal::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseReversal>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseReversal>(this);
}

void ImpulseReversal::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseReversal>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseReversal>(this, ticketIndex);
}

void ImpulseReversal::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseReversal>(this);
}

void ImpulseReversal::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseReversal>(this, partialedTicket, newTicketNumber);
}

void ImpulseReversal::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseReversal>(this, ticket, Period());
}

void ImpulseReversal::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseReversal>(this, error, additionalInformation);
}

void ImpulseReversal::Reset()
{
    InvalidateSetup(false);
    mStopTrading = false;
}