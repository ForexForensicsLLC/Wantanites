//+------------------------------------------------------------------+
//|                                                    MBGridMultiplier.mqh |
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

#include <Wantanites\Framework\Objects\Indicators\Grid\GridTracker.mqh>
#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>

class MBGridMultiplier : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;
    GridTracker *mGT;
    Dictionary<int, int> *mLevelsWithTickets;

    int mFirstMBInSetupNumber;

    int mStartingNumberOfLevels;
    double mMinLevelPips;
    double mLotSize;
    double mMaxEquityDrawDown;

    bool mFirstTrade;

    double mStartingEquity;
    int mPreviousAchievedLevel;
    bool mCloseAllTickets;
    int mLevelProfitTargetHit;

public:
    MBGridMultiplier(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, GridTracker *&gt);
    ~MBGridMultiplier();

    void GetGridLevelsAndDistance(double totalDistance, int &levels, double &levelDistance);

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

MBGridMultiplier::MBGridMultiplier(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, GridTracker *&gt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mGT = gt;
    mLevelsWithTickets = new Dictionary<int, int>();

    mFirstMBInSetupNumber = EMPTY;

    mStartingNumberOfLevels = 0;
    mMinLevelPips = 0;
    mLotSize = 0.0;
    mMaxEquityDrawDown = 0.0;

    mFirstTrade = true;

    mStartingEquity = 0;
    mPreviousAchievedLevel = 1000;
    mCloseAllTickets = false;
    mLevelProfitTargetHit = -99;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBGridMultiplier>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBGridMultiplier, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBGridMultiplier, SingleTimeFrameEntryTradeRecord>(this);
}

MBGridMultiplier::~MBGridMultiplier()
{
    delete mLevelsWithTickets;
}

void MBGridMultiplier::PreRun()
{
    mMBT.DrawNMostRecentMBs(-1);
    mGT.Draw();
}

bool MBGridMultiplier::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBGridMultiplier>(this) && EAHelper::WithinTradingSession<MBGridMultiplier>(this);
}

void MBGridMultiplier::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<MBGridMultiplier>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
    {
        MBState *tempMBState;
        if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        double pipsThreshold = 3;
        if (SetupType() == OP_BUY)
        {
            if (!mMBT.HasPendingBullishMB())
            {
                return;
            }

            if (CurrentTick().Bid() < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) + OrderHelper::PipsToRange(pipsThreshold) &&
                CurrentTick().Bid() > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) - OrderHelper::PipsToRange(pipsThreshold))
            {
                mGT.UpdateBasePrice(CurrentTick().Bid());
                mHasSetup = true;
            }
        }
        else if (SetupType() == OP_SELL)
        {
            if (!mMBT.HasPendingBearishMB())
            {
                return;
            }

            if (CurrentTick().Bid() < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) + OrderHelper::PipsToRange(pipsThreshold) &&
                CurrentTick().Bid() > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - OrderHelper::PipsToRange(pipsThreshold))
            {
                mGT.UpdateBasePrice(CurrentTick().Bid());
                mHasSetup = true;
            }
        }
    }
}

void MBGridMultiplier::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(true);
    }
}

void MBGridMultiplier::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBGridMultiplier>(this, deletePendingOrder, mStopTrading, error);

    mFirstMBInSetupNumber = EMPTY;
    mFirstTrade = true;
    mPreviousAchievedLevel = 1000;
    mStartingEquity = 0;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
    mGT.Reset();
}

bool MBGridMultiplier::Confirmation()
{
    // going to close all tickets
    if (mGT.AtMaxLevel())
    {
        return false;
    }

    if ((SetupType() == OP_BUY && mGT.CurrentLevel() > 0) || (SetupType() == OP_SELL && mGT.CurrentLevel() < 0))
    {
        return false;
    }

    if (mGT.CurrentLevel() != mPreviousAchievedLevel && !mLevelsWithTickets.HasKey(mGT.CurrentLevel()))
    {
        mPreviousAchievedLevel = mGT.CurrentLevel();
        return true;
    }

    return false;
}

void MBGridMultiplier::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double lotSize = .1;
    int currentLevel = mGT.CurrentLevel();

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        // don't want to place a tp on the last level because they we won't call ManagePreviousSetupTickets on it to check that we are at the last level
        // takeProfit = mGT.AtMaxLevel() ? 0.0 : mGT.LevelPrice(currentLevel + 1);
        // stopLoss = mGT.LevelPrice(currentLevel - 1);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        // don't want to place a tp on the last level because they we won't call ManagePreviousSetupTickets on it to check that we are at the last level
        // takeProfit = mGT.AtMaxLevel() ? 0.0 : mGT.LevelPrice(currentLevel - 1);
        // stopLoss = mGT.LevelPrice(currentLevel + 1);
    }

    if (mFirstTrade)
    {
        mStartingEquity = AccountBalance();
        mFirstTrade = false;
    }

    int ticketsInDrawDown = 0;
    for (int i = 0; i < mLevelsWithTickets.Size(); i++)
    {
        if (SetupType() == OP_BUY)
        {
            // we are going down on the grid so tickets in drawdown would have a higher grid number
            if (mLevelsWithTickets[i] > currentLevel)
            {
                ticketsInDrawDown += 1;
            }
        }
        else if (SetupType() == OP_SELL)
        {
            // we are going up on the grid so tickets in drawdown would have a lower grid number
            if (mLevelsWithTickets[i] < currentLevel)
            {
                ticketsInDrawDown += 1;
            }
        }
    }

    lotSize *= MathPow(2, ticketsInDrawDown);
    EAHelper::PlaceMarketOrder<MBGridMultiplier>(this, entry, stopLoss, lotSize);

    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLevelsWithTickets.Add(currentLevel, mCurrentSetupTickets[0].Number());
    }
}

void MBGridMultiplier::PreManageTickets()
{
    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<MBGridMultiplier>(this, mStartingEquity);
    if (equityPercentChange >= 0.2)
    {
        mCloseAllTickets = true;
        return;
    }
}

void MBGridMultiplier::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void MBGridMultiplier::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool MBGridMultiplier::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void MBGridMultiplier::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
        return;
    }
}

void MBGridMultiplier::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void MBGridMultiplier::CheckPreviousSetupTicket(Ticket &ticket)
{
    bool isClosed = false;
    ticket.IsClosed(isClosed);
    if (isClosed)
    {
        mLevelsWithTickets.RemoveByValue(ticket.Number());
    }
}

void MBGridMultiplier::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBGridMultiplier>(this, ticket);
}

void MBGridMultiplier::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void MBGridMultiplier::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBGridMultiplier>(this, ticket, Period());
}

void MBGridMultiplier::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBGridMultiplier>(this, error, additionalInformation);
}

bool MBGridMultiplier::ShouldReset()
{
    return !EAHelper::WithinTradingSession<MBGridMultiplier>(this);
}

void MBGridMultiplier::Reset()
{
}