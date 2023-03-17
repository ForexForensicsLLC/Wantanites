//+------------------------------------------------------------------+
//|                                                    MidCross.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

enum Mode
{
    Profit,
    Survive
};

class MidCross : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    Mode mMode;

    ObjectList<EconomicEvent> *mEconomicEvents;
    List<string> *mEconomicEventTitles;
    List<string> *mEconomicEventSymbols;

    bool mLoadedTodaysEvents;
    bool mCloseAllTickets;

public:
    MidCross(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~MidCross();

    double UpperBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, shift); }
    double MiddleBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, shift); }
    double LowerBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, shift); }

    double EMA(int shift) { return iMA(mEntrySymbol, mEntryTimeFrame, 100, 0, MODE_EMA, PRICE_CLOSE, shift); }

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
    virtual void RecordError(int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

MidCross::MidCross(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMode = Mode::Profit;

    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedTodaysEvents = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MidCross>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MidCross, SingleTimeFrameEntryTradeRecord>(this);
}

MidCross::~MidCross()
{
    delete mEconomicEvents;
}

void MidCross::PreRun()
{
    if (mMode == Mode::Profit && mPreviousSetupTickets.Size() > 0)
    {
        mMode = Mode::Survive;
    }
    else if (mPreviousSetupTickets.Size() == 0)
    {
        mMode = Mode::Profit;
    }
}

bool MidCross::AllowedToTrade()
{
    return EAHelper::BelowSpread<MidCross>(this) && EAHelper::WithinTradingSession<MidCross>(this);
}

void MidCross::CheckSetSetup()
{
    if (!mLoadedTodaysEvents)
    {
        EAHelper::GetEconomicEventsForDate<MidCross>(this, TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, ImpactEnum::HighImpact);
        mLoadedTodaysEvents = true;
    }

    if (!mEconomicEvents.IsEmpty())
    {
        mStopTrading = true;
        return;
    }

    if (mMode == Mode::Profit)
    {
        if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
        {
            return;
        }

        if (SetupType() == OP_BUY && CurrentTick().Bid() > EMA(0))
        {
            mHasSetup = true;
        }
        else if (SetupType() == OP_SELL && CurrentTick().Bid() < EMA(0))
        {
            mHasSetup = true;
        }
    }
    else
    {
        if (SetupType() == OP_BUY && CurrentTick().Bid() < LowerBand(0))
        {
            double distanceFromLastOrder = mPreviousSetupTickets[mPreviousSetupTickets.Size() - 1].OpenPrice() - CurrentTick().Bid();
            if (distanceFromLastOrder > OrderHelper::PipsToRange(mMinOrderDistance))
            {
                mHasSetup = true;
            }
        }
        else if (SetupType() == OP_SELL && CurrentTick().Bid() > UpperBand(0))
        {
            double distanceFromLastOrder = CurrentTick().Bid() - mPreviousSetupTickets[mPreviousSetupTickets.Size() - 1].OpenPrice();
            if (distanceFromLastOrder > OrderHelper::PipsToRange(mMinOrderDistance))
            {
                mHasSetup = true;
            }
        }
    }
}

void MidCross::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mMode == Mode::Profit)
    {
        if (SetupType() == OP_BUY && CurrentTick().Bid() < EMA(0))
        {
            InvalidateSetup(false);
        }
        else if (SetupType() == OP_SELL && CurrentTick().Bid() > EMA(0))
        {
            InvalidateSetup(false);
        }
    }
}

void MidCross::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MidCross>(this, deletePendingOrder, mStopTrading, error);
}

bool MidCross::Confirmation()
{
    if (mMode == Mode::Profit)
    {
        if (SetupType() == OP_BUY)
        {
            return iClose(mEntrySymbol, mEntryTimeFrame, 2) < MiddleBand(2) && iClose(mEntrySymbol, mEntryTimeFrame, 1) > MiddleBand(1);
        }
        else if (SetupType() == OP_SELL)
        {
            return iClose(mEntrySymbol, mEntryTimeFrame, 2) > MiddleBand(2) && iClose(mEntrySymbol, mEntryTimeFrame, 1) < MiddleBand(1);
        }
    }

    return mMode == Mode::Survive;
}

void MidCross::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
    }

    if (mMode == Mode::Profit)
    {
        if (SetupType() == OP_BUY)
        {
            takeProfit = entry + OrderHelper::PipsToRange(mTakeProfitPips);
            // stopLoss = LowerBand(0);
        }
        else if (SetupType() == OP_SELL)
        {
            takeProfit = entry - OrderHelper::PipsToRange(mTakeProfitPips);
            // stopLoss = UpperBand(0);
        }
    }

    EAHelper::PlaceMarketOrder<MidCross>(this, entry, stopLoss, 0.0, SetupType(), takeProfit);
    InvalidateSetup(false);
}

void MidCross::PreManageTickets()
{
    if (mMode == Mode::Survive)
    {
        double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<DonchianChannelGrid>(this, AccountBalance());
        if (equityPercentChange > mFurthestEquityDrawDownPercent)
        {
            mFurthestEquityDrawDownPercent = equityPercentChange;
            mFurthestEquityDrawDownTime = TimeCurrent();
        }

        double totalEquityPercentChange = (AccountEquity() - AccountBalance()) / AccountBalance() * 100;
        if (totalEquityPercentChange < mFurthestTotalEquityDrawDownPercent)
        {
            mFurthestTotalEquityDrawDownPercent = totalEquityPercentChange;
            mFurthestTotalEquityDrawDownTime = TimeCurrent();
        }

        if (equityPercentChange >= .2)
        {
            mCloseAllTickets = true;
            mInvalidateWhenAllTicketsAreClosed = true;
            return;
        }
    }
}

void MidCross::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void MidCross::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool MidCross::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void MidCross::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
    }
}

void MidCross::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void MidCross::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void MidCross::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MidCross>(this, ticket);
}

void MidCross::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MidCross>(this, partialedTicket, newTicketNumber);
}

void MidCross::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MidCross>(this, ticket, Period());
}

void MidCross::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MidCross>(this, error, additionalInformation);
}

bool MidCross::ShouldReset()
{
    return !EAHelper::WithinTradingSession<MidCross>(this);
}

void MidCross::Reset()
{
    mStopTrading = false;
    mLoadedTodaysEvents = false;

    mEconomicEvents.Clear();
}