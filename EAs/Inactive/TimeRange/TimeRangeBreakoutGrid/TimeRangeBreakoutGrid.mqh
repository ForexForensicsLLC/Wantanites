//+------------------------------------------------------------------+
//|                                                    StartOfDayTimeRangeBreakout.mqh |
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

class StartOfDayTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;
    PriceGridTracker *mPGT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;
    int mLastHour;

    int mCloseHour;
    int mCloseMinute;

    double mLastPriceLevel;
    double mFurthestPriceLevel;
    bool mCloseAllTickets;

    double mLotSize;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb, PriceGridTracker *&pgt);
    ~StartOfDayTimeRangeBreakout();

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

StartOfDayTimeRangeBreakout::StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb, PriceGridTracker *&pgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;
    mPGT = pgt;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();
    mLastHour = Hour();

    mCloseHour = 0;
    mCloseMinute = 0;

    mLastPriceLevel = 1000;
    mFurthestPriceLevel = 1000;
    mCloseAllTickets = false;

    mLotSize = 0.0;
    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayTimeRangeBreakout>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<StartOfDayTimeRangeBreakout, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

StartOfDayTimeRangeBreakout::~StartOfDayTimeRangeBreakout()
{
}

void StartOfDayTimeRangeBreakout::Run()
{
    EAHelper::RunDrawTimeRange<StartOfDayTimeRangeBreakout>(this, mTRB);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
    mLastHour = Hour();
}

bool StartOfDayTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::CheckSetSetup()
{
    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        if (mSetupType == OP_BUY)
        {
            // mPGT.SetStartingPriceAndLevelPips(mTRB.RangeHigh(), OrderHelper::RangeToPips(mTRB.RangeHeight()));
            mPGT.SetStartingPriceAndLevelPips(mTRB.RangeHigh(), 100);

            mHasSetup = true;
        }
        else if (mSetupType == OP_SELL)
        {
            // mPGT.SetStartingPriceAndLevelPips(mTRB.RangeLow(), OrderHelper::RangeToPips(mTRB.RangeHeight()));
            mPGT.SetStartingPriceAndLevelPips(mTRB.RangeLow(), 100);
            mHasSetup = true;
        }
    }
}

void StartOfDayTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day())
    {
        InvalidateSetup(true);
    }

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        mCloseAllTickets = false;
    }
}

void StartOfDayTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<StartOfDayTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);

    mLastPriceLevel = 1000;
    mFurthestPriceLevel = 1000;
}

bool StartOfDayTimeRangeBreakout::Confirmation()
{
    if (mSetupType == OP_BUY)
    {
        if (mPGT.CurrentLevel() >= 0 &&
            (mPGT.CurrentLevel() > mLastPriceLevel || mLastPriceLevel == 1000))
        {
            mLastPriceLevel = mPGT.CurrentLevel();
            if (mPGT.CurrentLevel() > mFurthestPriceLevel || mFurthestPriceLevel == 1000)
            {
                mFurthestPriceLevel = mPGT.CurrentLevel();
            }

            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (mPGT.CurrentLevel() <= 0 &&
            mPGT.CurrentLevel() < mLastPriceLevel)
        {
            mLastPriceLevel = mPGT.CurrentLevel();
            if (mPGT.CurrentLevel() < mFurthestPriceLevel)
            {
                mFurthestPriceLevel = mPGT.CurrentLevel();
            }

            return true;
        }
    }

    return false;
}

void StartOfDayTimeRangeBreakout::PlaceOrders()
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
        if (entry < mTRB.RangeHigh())
        {
            return;
        }
        stopLoss = entry - (mTRB.RangeHeight() * 2);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        if (entry > mTRB.RangeLow())
        {
            return;
        }
        stopLoss = entry + (mTRB.RangeHeight() * 2);
    }

    EAHelper::PlaceMarketOrder<StartOfDayTimeRangeBreakout>(this, entry, stopLoss, mLotSize);

    // mCurrentSetupTicket.SelectIfOpen("Adding tp");

    // int maxTakeProfitLevel = 8;
    // double takeProfit = 0.0;

    // if (mSetupType == OP_BUY)
    // {
    //     // takeProfit = OrderOpenPrice() + (MathMax(8 - mPGT.CurrentLevel(), 1) * mTRB.RangeHeight());
    //     takeProfit = OrderOpenPrice() + mTRB.RangeHeight();
    //     OrderModify(mCurrentSetupTicket.Number(), OrderOpenPrice(), OrderStopLoss(), takeProfit, OrderExpiration(), clrNONE);
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     // takeProfit = OrderOpenPrice() - (MathMax(8 - mPGT.CurrentLevel(), 1) * mTRB.RangeHeight());
    //     takeProfit = OrderOpenPrice() - mTRB.RangeHeight();
    //     OrderModify(mCurrentSetupTicket.Number(), OrderOpenPrice(), OrderStopLoss(), takeProfit, OrderExpiration(), clrNONE);
    // }
}

void StartOfDayTimeRangeBreakout::ManageCurrentPendingSetupTicket()
{
}

void StartOfDayTimeRangeBreakout::ManageCurrentActiveSetupTicket()
{
    // if (EAHelper::CloseTicketIfPastTime<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute))
    // {
    //     return;
    // }

    // double slDistance = MathAbs(mCurrentSetupTicket.OpenPrice() - mCurrentSetupTicket.mOriginalStopLoss);
    // double pipsToWait = OrderHelper::RangeToPips(slDistance * 4);

    // EAHelper::MoveToBreakEvenAfterPips<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket, OrderHelper::RangeToPips(mTRB.RangeHeight()), 0.0);
}

bool StartOfDayTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return false;
    // return EAHelper::TicketStopLossIsMovedToBreakEven<StartOfDayTimeRangeBreakout>(this, ticket);
    return true;
}

void StartOfDayTimeRangeBreakout::ManagePreviousSetupTicket(int ticketIndex)
{
    if (mCloseAllTickets)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        return;
    }

    if (EAHelper::CloseTicketIfPastTime<StartOfDayTimeRangeBreakout>(this, mPreviousSetupTickets[ticketIndex], mCloseHour, mCloseMinute))
    {
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    // double profit = 0.0;
    // for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
    // {
    //     mPreviousSetupTickets[i].SelectIfOpen("Adding profit");
    //     profit += OrderProfit();
    // }

    // double finalProfit = AccountBalance() + profit;
    // double equityPercentChange = (finalProfit - AccountBalance()) / finalProfit * 100;
    // if (equityPercentChange < -20)
    // {
    //     mCloseAllTickets = true;
    // }

    // if (mSetupType == OP_BUY)
    // {
    //     if (mPGT.CurrentLevel() > 0 && currentTick.bid < mTRB.RangeHigh())
    //     {
    //         mPreviousSetupTickets[ticketIndex].Close();
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (mPGT.CurrentLevel() < 0 && currentTick.ask > mTRB.RangeLow())
    //     {
    //         mPreviousSetupTickets[ticketIndex].Close();
    //     }
    // }

    // double middleLevelPlusOne = (mFurthestPriceLevel / 2);
    // if (mSetupType == OP_BUY)
    // {
    //     middleLevelPlusOne += 1;
    //     if (mFurthestPriceLevel < 5)
    //     {
    //         return;
    //     }

    //     if (currentTick.bid < mPGT.LevelPrice(middleLevelPlusOne))
    //     {
    //         mCloseAllTickets = true;
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     middleLevelPlusOne -= 1;
    //     if (mFurthestPriceLevel > 5)
    //     {
    //         return;
    //     }

    //     if (currentTick.ask > mPGT.LevelPrice(middleLevelPlusOne))
    //     {
    //         mCloseAllTickets = true;
    //     }
    // }

    mPreviousSetupTickets[ticketIndex].SelectIfOpen("Trailing SL");
    if (mSetupType == OP_BUY)
    {
        if (currentTick.bid - OrderStopLoss() >= (mTRB.RangeHeight() * 2) && Hour() != mLastHour)
        {
            OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), OrderStopLoss() + mTRB.RangeHeight(), OrderTakeProfit(), OrderExpiration(), clrNONE);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (OrderStopLoss() - currentTick.ask >= (mTRB.RangeHeight() * 2) && Hour() != mLastHour)
        {
            OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), OrderStopLoss() - mTRB.RangeHeight(), OrderTakeProfit(), OrderExpiration(), clrNONE);
        }
    }
}

void StartOfDayTimeRangeBreakout::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StartOfDayTimeRangeBreakout>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<StartOfDayTimeRangeBreakout>(this, ticketIndex);
}

void StartOfDayTimeRangeBreakout::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<StartOfDayTimeRangeBreakout>(this, partialedTicket, newTicketNumber);
}

void StartOfDayTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<StartOfDayTimeRangeBreakout>(this, ticket, Period());
}

void StartOfDayTimeRangeBreakout::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<StartOfDayTimeRangeBreakout>(this, error, additionalInformation);
}

void StartOfDayTimeRangeBreakout::Reset()
{
}