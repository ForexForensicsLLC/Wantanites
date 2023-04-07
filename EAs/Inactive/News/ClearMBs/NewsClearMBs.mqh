//+------------------------------------------------------------------+
//|                                                    NewsClearMBs.mqh |
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

#include <Wantanites\Framework\Objects\DataObjects\EconomicEvent.mqh>

enum Mode
{
    Profit,
    Survive
};

class NewsClearMBs : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    Mode mMode;

    MBTracker *mMBT;

    ObjectList<EconomicEvent> *mEconomicEvents;

    List<string> *mNewsTitles;
    List<string> *mNewsSymbols;

    bool mLoadedTodaysEvents;

    int mFirstMBInSetupNumber;

    double mPipsToWatiBeforeBE;
    double mBEAdditionalPips;

    bool mClearMBs;
    int mClearHour;
    int mClearMinute;

    int mCloseHour;
    int mCloseMinute;

public:
    NewsClearMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~NewsClearMBs();

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

NewsClearMBs::NewsClearMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMode = Mode::Profit;

    mMBT = mbt;

    mEconomicEvents = new ObjectList<EconomicEvent>();
    mLoadedTodaysEvents = false;

    mFirstMBInSetupNumber = EMPTY;

    mPipsToWatiBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mClearMBs = true;
    mClearHour = 0;
    mClearMinute = 0;

    mCloseHour = 0;
    mCloseMinute = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<NewsClearMBs>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<NewsClearMBs, SingleTimeFrameEntryTradeRecord>(this);
}

NewsClearMBs::~NewsClearMBs()
{
    delete mEconomicEvents;
}

void NewsClearMBs::PreRun()
{
    if (mClearMBs && Hour() == mClearHour && Minute() == mClearMinute)
    {
        mMBT.Clear();
        mClearMBs = false;
    }

    if ((mCurrentSetupTickets.Size() > 0 || mPreviousSetupTickets.Size() > 0) && Hour() == mCloseHour && Minute() == mCloseMinute)
    {
        EAHelper::CloseAllCurrentAndPreviousSetupTickets<NewsClearMBs>(this);
    }

    mMBT.DrawNMostRecentMBs(-1);
    mMBT.DrawZonesForNMostRecentMBs(-1);
}

bool NewsClearMBs::AllowedToTrade()
{
    return EAHelper::BelowSpread<NewsClearMBs>(this) && EAHelper::WithinTradingSession<NewsClearMBs>(this);
}

void NewsClearMBs::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    if (mMBT.MBsCreated() <= 0)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<NewsClearMBs>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
    {
        mHasSetup = true;
    }
}

void NewsClearMBs::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        InvalidateSetup(false);
    }
}

void NewsClearMBs::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;
    EAHelper::InvalidateSetup<NewsClearMBs>(this, deletePendingOrder, mStopTrading, error);
}

bool NewsClearMBs::Confirmation()
{
    if (!mLoadedTodaysEvents)
    {
        EAHelper::GetEconomicEventsForDate<NewsClearMBs>(this, TimeGMT(), mNewsTitles, mNewsSymbols, ImpactEnum::HighImpact);
        mLoadedTodaysEvents = true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return false;
    }

    // this doesn't need to be offseted by MQls utc offset for some reason? Maybe its taken into account already?
    datetime timeCurrent = TimeGMT();
    int minTimeDifference = 60 * 5; // 5  minutes in seconds

    for (int i = 0; i < mEconomicEvents.Size(); i++)
    {
        // already past event
        if (timeCurrent > mEconomicEvents[i].Date())
        {
            continue;
        }

        // we are 5 minutes within a new event
        if (mEconomicEvents[i].Date() - timeCurrent <= minTimeDifference)
        {
            // remove it so that we don't enter on it again
            mEconomicEvents.Remove(i);
            return true;
        }
    }

    return false;
}

void NewsClearMBs::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        stopLoss = entry - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        stopLoss = entry + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceMarketOrder<NewsClearMBs>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void NewsClearMBs::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void NewsClearMBs::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<NewsClearMBs>(this, ticket);
    EAHelper::MoveToBreakEvenAfterPips<NewsClearMBs>(this, ticket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

void NewsClearMBs::PreManageTickets()
{
}

bool NewsClearMBs::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<NewsClearMBs>(this, ticket);
}

void NewsClearMBs::ManagePreviousSetupTicket(Ticket &ticket)
{
    EAHelper::CheckPartialTicket<NewsClearMBs>(this, ticket);
}

void NewsClearMBs::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void NewsClearMBs::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void NewsClearMBs::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<NewsClearMBs>(this, ticket);
}

void NewsClearMBs::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<NewsClearMBs>(this, partialedTicket, newTicketNumber);
}

void NewsClearMBs::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<NewsClearMBs>(this, ticket, Period());
}

void NewsClearMBs::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<NewsClearMBs>(this, error, additionalInformation);
}

bool NewsClearMBs::ShouldReset()
{
    return !EAHelper::WithinTradingSession<NewsClearMBs>(this);
}

void NewsClearMBs::Reset()
{
    mStopTrading = false;
    mLoadedTodaysEvents = false;
    mClearMBs = true;

    InvalidateSetup(true);

    mEconomicEvents.Clear();
}