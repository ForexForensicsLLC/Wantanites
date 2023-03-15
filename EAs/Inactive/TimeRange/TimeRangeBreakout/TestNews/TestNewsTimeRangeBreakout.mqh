//+------------------------------------------------------------------+
//|                                                    TestNewsTimeRangeBreakout.mqh |
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

#include <Wantanites\Framework\Objects\Indicators\Time\TimeRangeBreakout.mqh>

class TestNewsTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;
    ObjectList<EconomicEvent> *mEconomicEvents;

    bool mLoadedEventsForToday;
    bool mDuringNews;

public:
    TestNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~TestNewsTimeRangeBreakout();

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

TestNewsTimeRangeBreakout::TestNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedEventsForToday = false;
    mDuringNews = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TestNewsTimeRangeBreakout>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TestNewsTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

TestNewsTimeRangeBreakout::~TestNewsTimeRangeBreakout()
{
    delete mEconomicEvents;
}

void TestNewsTimeRangeBreakout::PreRun()
{
    mTRB.Draw();
}

bool TestNewsTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<TestNewsTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<TestNewsTimeRangeBreakout>(this);
}

void TestNewsTimeRangeBreakout::CheckSetSetup()
{
    if (!mLoadedEventsForToday)
    {
        EAHelper::GetEconomicEventsForDate<TestNewsTimeRangeBreakout>(this, TimeGMT(), "", ImpactEnum::HighImpact);
        mLoadedEventsForToday = true;
    }

    if (EAHelper::MostRecentCandleBrokeTimeRange<TestNewsTimeRangeBreakout>(this))
    {
        mDuringNews = EAHelper::CurrentCandleIsDuringEconomicEvent<TestNewsTimeRangeBreakout>(this);
        mHasSetup = true;
    }
}

void TestNewsTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (LastDay() != Day())
    {
        InvalidateSetup(true);
    }
}

void TestNewsTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TestNewsTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);
}

bool TestNewsTimeRangeBreakout::Confirmation()
{
    return true;
}

void TestNewsTimeRangeBreakout::PlaceOrders()
{
    double newsPips = 25;
    double entry = 0.0;
    double stopLoss = 0.0;
    mRiskPercent = 1;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = mTRB.RangeLow();

        if (mDuringNews)
        {
            entry += OrderHelper::PipsToRange(newsPips);
            mRiskPercent = (entry - stopLoss) / (CurrentTick().Ask() - stopLoss);

            EAHelper::PlaceStopOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
        else
        {
            EAHelper::PlaceMarketOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = mTRB.RangeHigh();

        if (mDuringNews)
        {
            entry -= OrderHelper::PipsToRange(newsPips);
            mRiskPercent = (entry - stopLoss) / (CurrentTick().Ask() - stopLoss);

            EAHelper::PlaceStopOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
        else
        {
            EAHelper::PlaceMarketOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
    }

    mStopTrading = true;
}

void TestNewsTimeRangeBreakout::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::PreManageTickets()
{
}

bool TestNewsTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void TestNewsTimeRangeBreakout::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::CheckCurrentSetupTicket(Ticket &ticket)
{
    // close if we are down 1%
    if ((AccountEquity() - AccountBalance()) / AccountBalance() * 100 <= -1)
    {
        ticket.Close();
    }
}

void TestNewsTimeRangeBreakout::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TestNewsTimeRangeBreakout>(this, ticket);
}

void TestNewsTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void TestNewsTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TestNewsTimeRangeBreakout>(this, ticket, Period());
}

void TestNewsTimeRangeBreakout::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TestNewsTimeRangeBreakout>(this, error, additionalInformation);
}

bool TestNewsTimeRangeBreakout::ShouldReset()
{
    return !EAHelper::WithinTradingSession<TestNewsTimeRangeBreakout>(this);
}

void TestNewsTimeRangeBreakout::Reset()
{
    mStopTrading = false;
    mLoadedEventsForToday = false;
    mDuringNews = false;

    mEconomicEvents.Clear();
    EAHelper::CloseAllCurrentAndPreviousSetupTickets<TestNewsTimeRangeBreakout>(this);
}