//+------------------------------------------------------------------+
//|                                                    AlwaysGrid.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Objects\DataObjects\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>

#include <WantaCapital\Framework\Objects\Indicators\Grid\GridTracker.mqh>
#include <WantaCapital\Framework\Objects\DataStructures\Dictionary.mqh>

class AlwaysGrid : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    GridTracker *mGT;
    Dictionary<int, int> *mLevelsWithTickets;

    double mStartingLotSize;
    double mMaxEquityDrawDownPercent;

    bool mFirstTrade;
    double mStartingEquity;
    int mPreviousAchievedLevel;
    int mLevelProfitTargetHit;
    bool mCloseAllTickets;

public:
    AlwaysGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt);
    ~AlwaysGrid();

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

AlwaysGrid::AlwaysGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mGT = gt;
    mLevelsWithTickets = new Dictionary<int, int>();

    mStartingLotSize = 0.0;
    mMaxEquityDrawDownPercent = 0.0;

    mFirstTrade = true;
    mStartingEquity = 0;
    mPreviousAchievedLevel = 1000;
    mLevelProfitTargetHit = -99;
    mCloseAllTickets = false;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<AlwaysGrid>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<AlwaysGrid, SingleTimeFrameEntryTradeRecord>(this);
}

AlwaysGrid::~AlwaysGrid()
{
    delete mLevelsWithTickets;
}

void AlwaysGrid::PreRun()
{
    mGT.Draw();
}

bool AlwaysGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<AlwaysGrid>(this);
}

void AlwaysGrid::CheckSetSetup()
{
    mGT.UpdateBasePrice(CurrentTick().Bid());
    mHasSetup = true;
}

void AlwaysGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(true);
    }
}

void AlwaysGrid::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    Print("Invalidate Setup");
    EAHelper::InvalidateSetup<AlwaysGrid>(this, deletePendingOrder, mStopTrading, error);

    mFirstTrade = true;
    mPreviousAchievedLevel = 1000;
    mStartingEquity = 0;
    mLevelProfitTargetHit = -99;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
}

bool AlwaysGrid::Confirmation()
{
    if (mGT.AtMaxLevel())
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

void AlwaysGrid::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;
    double lotSize = mStartingLotSize * MathPow(2, mPreviousSetupTickets.Size());

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        takeProfit = mGT.LevelPrice(mGT.CurrentLevel() + 1);
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        takeProfit = mGT.LevelPrice(mGT.CurrentLevel() - 1);
    }

    if (mFirstTrade)
    {
        mStartingEquity = AccountBalance();
        mFirstTrade = false;
    }

    EAHelper::PlaceMarketOrder<AlwaysGrid>(this, entry, stopLoss, lotSize);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLevelsWithTickets.Add(mGT.CurrentLevel(), mCurrentSetupTickets[0].Number());
    }
}

void AlwaysGrid::PreManageTickets()
{
    if (mCloseAllTickets)
    {
        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<AlwaysGrid>(this, mStartingEquity);
    if (equityPercentChange <= mMaxEquityDrawDownPercent || equityPercentChange >= 1)
    {
        mCloseAllTickets = true;
        return;
    }

    if (mGT.AtMaxLevel())
    {
        mCloseAllTickets = true;
        return;
    }

    int currentLevel = mGT.CurrentLevel();
    for (int i = 0; i < mLevelsWithTickets.Size(); i++)
    {
        if (SetupType() == OP_BUY)
        {
            if (mLevelsWithTickets[i] < currentLevel)
            {
                mCloseAllTickets = true;
                break;
            }
        }
        else if (SetupType() == OP_SELL)
        {
            if (mLevelsWithTickets[i] > currentLevel)
            {
                mCloseAllTickets = true;
                break;
            }
        }
    }
}

void AlwaysGrid::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void AlwaysGrid::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool AlwaysGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void AlwaysGrid::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
    }
}

void AlwaysGrid::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void AlwaysGrid::CheckPreviousSetupTicket(Ticket &ticket)
{
    bool isClosed = false;
    ticket.IsClosed(isClosed);
    if (isClosed)
    {
        mLevelsWithTickets.RemoveByValue(ticket.Number());
    }
}

void AlwaysGrid::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<AlwaysGrid>(this, ticket);
}

void AlwaysGrid::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void AlwaysGrid::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<AlwaysGrid>(this, ticket, Period());
}

void AlwaysGrid::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<AlwaysGrid>(this, error, additionalInformation);
}

bool AlwaysGrid::ShouldReset()
{
    return false;
}

void AlwaysGrid::Reset()
{
}