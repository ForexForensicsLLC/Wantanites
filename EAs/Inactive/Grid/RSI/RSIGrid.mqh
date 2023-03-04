//+------------------------------------------------------------------+
//|                                                    RSIGrid.mqh |
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

class RSIGrid : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    GridTracker *mGT;
    Dictionary<int, int> *mLevelsWithTickets;

    double mStartingLotSize;
    double mLotsPerBalancePeriod;
    double mLotsPerBalanceLotIncrement;
    int mIncreaseLotSizePeriod;
    double mIncreaseLotSizeFactor;
    double mMaxEquityDrawDownPercent;

    bool mFirstTrade;
    double mStartingEquity;
    int mPreviousAchievedLevel;
    int mLevelProfitTargetHit;
    bool mCloseAllTickets;

    double mFurthestEquityDrawDownPercent;
    datetime mFurthestEquityDrawDownTime;

public:
    RSIGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
            CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
            CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt);
    ~RSIGrid();

    double RSI(int index) { return iRSI(mEntrySymbol, mEntryTimeFrame, 14, PRICE_CLOSE, index); }
    double EMA(int index) { return iMA(mEntrySymbol, 1440, 200, 0, MODE_EMA, PRICE_CLOSE, index); }

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

RSIGrid::RSIGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, GridTracker *&gt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mGT = gt;
    mLevelsWithTickets = new Dictionary<int, int>();

    mStartingLotSize = 0.0;
    mLotsPerBalancePeriod = 0.0;
    mLotsPerBalanceLotIncrement = 0.0;
    mIncreaseLotSizePeriod = 0;
    mIncreaseLotSizeFactor = 0.0;
    mMaxEquityDrawDownPercent = 0.0;

    mFirstTrade = true;
    mStartingEquity = 0;
    mPreviousAchievedLevel = 1000;
    mLevelProfitTargetHit = -99;
    mCloseAllTickets = false;

    mFurthestEquityDrawDownPercent = 0.0;
    mFurthestEquityDrawDownTime = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<RSIGrid>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<RSIGrid, SingleTimeFrameEntryTradeRecord>(this);
}

RSIGrid::~RSIGrid()
{
    Print("Magic Number: ", MagicNumber(), ", Furthest Equity DD Percent: ", mFurthestEquityDrawDownPercent, " at ", TimeToStr(mFurthestEquityDrawDownTime));
    delete mLevelsWithTickets;
}

void RSIGrid::PreRun()
{
    mGT.Draw();
}

bool RSIGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<RSIGrid>(this);
}

void RSIGrid::CheckSetSetup()
{
    bool setup = (SetupType() == OP_BUY && RSI(0) <= 30 && CurrentTick().Bid() < EMA(0)) || (SetupType() == OP_SELL && RSI(0) >= 70 && CurrentTick().Bid() > EMA(0));
    if (setup)
    {
        mGT.UpdateBasePrice(CurrentTick().Bid());
        mHasSetup = true;
    }
}

void RSIGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(true);
    }
}

void RSIGrid::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<RSIGrid>(this, deletePendingOrder, mStopTrading, error);

    mFirstTrade = true;
    mPreviousAchievedLevel = 1000;
    mStartingEquity = 0;
    mLevelProfitTargetHit = -99;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
}

bool RSIGrid::Confirmation()
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

void RSIGrid::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

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

    double startingLotSize = AccountBalance() / mLotsPerBalancePeriod * mLotsPerBalanceLotIncrement;
    //  double lotSize = startingLotSize;
    //  if (mPreviousSetupTickets.Size() > 0 && mPreviousSetupTickets.Size() % mIncreaseLotSizePeriod == 0)
    //  {
    //      lotSize = startingLotSize * MathPow(mIncreaseLotSizeFactor, mPreviousSetupTickets.Size() / mIncreaseLotSizePeriod);
    //  }

    int increaseLotSizeTimes = MathFloor(mPreviousSetupTickets.Size() / mIncreaseLotSizePeriod);
    double lotSize = startingLotSize * MathPow(mIncreaseLotSizeFactor, increaseLotSizeTimes);

    EAHelper::PlaceMarketOrder<RSIGrid>(this, entry, stopLoss, lotSize);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLevelsWithTickets.Add(mGT.CurrentLevel(), mCurrentSetupTickets[0].Number());
    }
}

void RSIGrid::PreManageTickets()
{
    if (mCloseAllTickets)
    {
        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<RSIGrid>(this, mStartingEquity);
    if (equityPercentChange < mFurthestEquityDrawDownPercent)
    {
        mFurthestEquityDrawDownPercent = equityPercentChange;
        mFurthestEquityDrawDownTime = TimeCurrent();
    }

    if (equityPercentChange <= mMaxEquityDrawDownPercent || equityPercentChange >= .2)
    {
        mCloseAllTickets = true;
        return;
    }

    // if (mGT.AtMaxLevel())
    // {
    //     mCloseAllTickets = true;
    //     return;
    // }

    // int currentLevel = mGT.CurrentLevel();
    // for (int i = 0; i < mLevelsWithTickets.Size(); i++)
    // {
    //     if (SetupType() == OP_BUY)
    //     {
    //         if (mLevelsWithTickets[i] < currentLevel)
    //         {
    //             mCloseAllTickets = true;
    //             break;
    //         }
    //     }
    //     else if (SetupType() == OP_SELL)
    //     {
    //         if (mLevelsWithTickets[i] > currentLevel)
    //         {
    //             mCloseAllTickets = true;
    //             break;
    //         }
    //     }
    // }
}

void RSIGrid::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void RSIGrid::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool RSIGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void RSIGrid::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        // if (SetupType() == OP_BUY && CurrentTick().Bid() > ticket.OpenPrice())
        // {
        //     double tp = CurrentTick().Ask() + MarketInfo(mEntrySymbol, MODE_SPREAD);
        //     OrderModify(ticket.Number(), ticket.OpenPrice(), ticket.OriginalStopLoss(), tp, 0, clrNONE);
        // }
        // else if (SetupType() == OP_SELL)
        // {
        //     double tp = CurrentTick().Bid() - MarketInfo(mEntrySymbol, MODE_SPREAD);
        //     OrderModify(ticket.Number(), ticket.OpenPrice(), ticket.OriginalStopLoss(), tp, 0, clrNONE);
        // }
        // else
        // {
        // }
        ticket.Close();
    }
}

void RSIGrid::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void RSIGrid::CheckPreviousSetupTicket(Ticket &ticket)
{
    bool isClosed = false;
    ticket.IsClosed(isClosed);
    if (isClosed)
    {
        mLevelsWithTickets.RemoveByValue(ticket.Number());
    }
}

void RSIGrid::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<RSIGrid>(this, ticket);
}

void RSIGrid::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void RSIGrid::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<RSIGrid>(this, ticket, Period());
}

void RSIGrid::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<RSIGrid>(this, error, additionalInformation);
}

bool RSIGrid::ShouldReset()
{
    return false;
}

void RSIGrid::Reset()
{
}