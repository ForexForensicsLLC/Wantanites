//+------------------------------------------------------------------+
//|                                                    TimeHedge.mqh |
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

class TimeHedge : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mCloseEquityPercentGain;
    double mCloseEquityPercentLoss;

    double mPipsFromOpen;

    double mLotSize;

    int mCloseHour;
    int mCloseMinute;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mStartingEquity;
    bool mCloseAllTickets;

public:
    TimeHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~TimeHedge();

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

TimeHedge::TimeHedge(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mCloseEquityPercentGain = 0.0;
    mCloseEquityPercentLoss = 0.0;

    mPipsFromOpen = 0.0;

    mCloseHour = 0;
    mCloseMinute = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mStartingEquity = 0.0;
    mCloseAllTickets = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TimeHedge>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TimeHedge, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TimeHedge, SingleTimeFrameEntryTradeRecord>(this);

    ArrayResize(mStrategyMagicNumbers, 2);

    mStrategyMagicNumbers[0] = -1;
    mStrategyMagicNumbers[1] = -2;
}

TimeHedge::~TimeHedge()
{
}

void TimeHedge::Run()
{
    EAHelper::Run<TimeHedge>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool TimeHedge::AllowedToTrade()
{
    return EAHelper::BelowSpread<TimeHedge>(this) && EAHelper::WithinTradingSession<TimeHedge>(this);
}

void TimeHedge::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (Hour() == mTradingSessions[0].HourStart() && Minute() == mTradingSessions[0].MinuteStart())
    {
        mHasSetup = true;
    }
}

void TimeHedge::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void TimeHedge::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TimeHedge>(this, deletePendingOrder, mStopTrading, error);
}

bool TimeHedge::Confirmation()
{
    return true;
}

void TimeHedge::PlaceOrders()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    mStartingEquity = AccountEquity();

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.bid + OrderHelper::PipsToRange(mPipsFromOpen);
        EAHelper::PlaceStopOrder<TimeHedge>(this, entry, 0.0, mLotSize, false, 0.0, OP_BUY);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid + OrderHelper::PipsToRange(mPipsFromOpen);
        EAHelper::PlaceLimitOrder<TimeHedge>(this, entry, 0.0, mLotSize, false, 0.0, OP_SELL);
    }

    InvalidateSetup(false);
}

void TimeHedge::ManageCurrentPendingSetupTicket()
{
    int otherEAOrderCount = 0;
    int error = OrderHelper::CountOtherEAOrders(false, mStrategyMagicNumbers, otherEAOrderCount);
    if (otherEAOrderCount < 2)
    {
        mCurrentSetupTicket.Close();
        mCurrentSetupTicket.SetNewTicket(EMPTY);
        return;
    }

    if (EAHelper::CloseTicketIfPastTime<TimeHedge>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute))
    {
        mCurrentSetupTicket.SetNewTicket(EMPTY);
        return;
    }
}

void TimeHedge::ManageCurrentActiveSetupTicket()
{
    int otherEAOrderCount = 0;
    int error = OrderHelper::CountOtherEAOrders(false, mStrategyMagicNumbers, otherEAOrderCount);
    if (otherEAOrderCount < 2)
    {
        mCurrentSetupTicket.Close();
        return;
    }

    if (EAHelper::CloseTicketIfPastTime<TimeHedge>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute))
    {
        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<TimeHedge>(this, mStartingEquity);
    if (equityPercentChange <= mCloseEquityPercentLoss || equityPercentChange >= mCloseEquityPercentGain)
    {
        mCurrentSetupTicket.Close();
    }
}

bool TimeHedge::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void TimeHedge::ManagePreviousSetupTicket(int ticketIndex)
{
}

void TimeHedge::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeHedge>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TimeHedge>(this);
}

void TimeHedge::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TimeHedge>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TimeHedge>(this, ticketIndex);
}

void TimeHedge::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TimeHedge>(this);
}

void TimeHedge::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TimeHedge>(this, partialedTicket, newTicketNumber);
}

void TimeHedge::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TimeHedge>(this, ticket, Period());
}

void TimeHedge::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TimeHedge>(this, error, additionalInformation);
}

bool TimeHedge::ShouldReset()
{
    return !EAHelper::WithinTradingSession<TimeHedge>(this);
}

void TimeHedge::Reset()
{
    mStartingEquity = 0.0;
}