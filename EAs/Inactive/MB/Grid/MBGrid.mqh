//+------------------------------------------------------------------+
//|                                                    MBGrid.mqh |
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

class MBGrid : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;
    GridTracker *mGT;
    Dictionary<int, int> *mLevelsWithTickets;

    int mStartingNumberOfLevels;
    double mMinLevelPips;
    double mLotSize;
    double mMaxEquityDrawDown;

    bool mFirstTrade;
    double mStartingEquity;
    int mPreviousAchievedLevel;
    bool mCloseAllTickets;
    int mLastSetupMB;

public:
    MBGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, GridTracker *&gt);
    ~MBGrid();

    void GetGridLevelsAndDistance(double totalDistance, int &levels, double &levelDistance);
    void GetGridLevelsForSetDistance(double totalDistance, int &levels);

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

MBGrid::MBGrid(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, GridTracker *&gt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mGT = gt;
    mLevelsWithTickets = new Dictionary<int, int>();

    mStartingNumberOfLevels = 0;
    mMinLevelPips = 0;
    mLotSize = 0.0;
    mMaxEquityDrawDown = 0.0;

    mFirstTrade = true;

    mStartingEquity = 0;
    mPreviousAchievedLevel = 1000;
    mCloseAllTickets = false;
    mLastSetupMB = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBGrid>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBGrid, SingleTimeFrameEntryTradeRecord>(this);
}

MBGrid::~MBGrid()
{
    delete mLevelsWithTickets;
}

void MBGrid::PreRun()
{
    mMBT.DrawNMostRecentMBs(-1);
    mGT.Draw();
}

bool MBGrid::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBGrid>(this) && EAHelper::WithinTradingSession<MBGrid>(this);
}

void MBGrid::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    // only one setup per MB
    if (mMBT.MBsCreated() - 1 == mLastSetupMB)
    {
        return;
    }

    if (mMBT.GetNthMostRecentMBsType(0) == SetupType())
    {
        MBState *tempMBState;
        if (!mMBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (SetupType() == OP_BUY)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
            {
                if (CandleStickHelper::BrokeFurther(OP_BUY, mEntrySymbol, mEntryTimeFrame, 1))
                {
                    int currentRetracementIndex = EMPTY;
                    if (!mMBT.CurrentBullishRetracementIndexIsValid(currentRetracementIndex))
                    {
                        return;
                    }

                    double totalUpperDistance = iHigh(mEntrySymbol, mEntryTimeFrame, currentRetracementIndex) - CurrentTick().Bid();
                    int totalUpperLevels = 0;
                    double upperLevelDistance = 0.0;
                    // GetGridLevelsAndDistance(totalUpperDistance, totalUpperLevels, upperLevelDistance);
                    GetGridLevelsForSetDistance(totalUpperDistance, totalUpperLevels);
                    if (totalUpperLevels == 0)
                    {
                        Print("No Upper Levels. Total Distance: ", totalUpperDistance, ", Upper Level Distance: ", upperLevelDistance,
                              ", Starting Levels: ", mStartingNumberOfLevels, ", Min Level Distance: ", mMinLevelPips);
                        return;
                    }

                    // double totalLowerDistance = CurrentTick().Bid() - iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());
                    // int totalLowerLevels = 0;
                    // double lowerLevelDistance = 0.0;
                    // // GetGridLevelsAndDistance(totalLowerDistance, totalLowerLevels, lowerLevelDistance);
                    // GetGridLevelsForSetDistance(totalLowerDistance, totalLowerLevels);

                    // if (totalLowerLevels == 0)
                    // {
                    //     Print("No Lower Levels. Total Distance: ", totalLowerDistance, ", Upper Level Distance: ", lowerLevelDistance,
                    //           ", Starting Levels: ", mStartingNumberOfLevels, ", Min Level Distance: ", mMinLevelPips);
                    //     return;
                    // }

                    mGT.ReInit(iOpen(mEntrySymbol, mEntryTimeFrame, 0),
                               totalUpperLevels,
                               1,
                               OrderHelper::PipsToRange(mMinLevelPips),
                               OrderHelper::PipsToRange(mMinLevelPips));

                    // double potentialMaxLoss = 0;
                    // double potentialMaxLossPips = 0;
                    // for (int i = totalUpperLevels; i > 0; i--)
                    // {
                    //     potentialMaxLoss += i;
                    // }

                    // potentialMaxLossPips = potentialMaxLoss * upperLevelDistance;

                    // potentialMaxLoss = 0;
                    // for (int i = totalLowerLevels; i > 0; i--)
                    // {
                    //     potentialMaxLoss += i;
                    // }

                    // potentialMaxLossPips += potentialMaxLoss * lowerLevelDistance;
                    // potentialMaxLossPips = OrderHelper::RangeToPips(totalUpperDistance + totalLowerDistance);

                    // potentialMaxLossPips = (totalUpperLevels + totalLowerLevels) * mMinLevelPips;
                    // mLotSize = OrderHelper::GetLotSize(potentialMaxLossPips, RiskPercent()) / (totalUpperLevels + totalLowerLevels);
                    // Print("Total levels: ", totalUpperLevels + totalLowerLevels, ", Potential Max Loss: ", potentialMaxLoss, ", Potential Max Loss Pips: ", potentialMaxLossPips);
                    mLastSetupMB = tempMBState.Number();
                    mHasSetup = true;
                }
            }
        }
        else if (SetupType() == OP_SELL)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
            {
                if (CandleStickHelper::BrokeFurther(OP_SELL, mEntrySymbol, mEntryTimeFrame, 1))
                {
                    int currentRetracementIndex = EMPTY;
                    if (!mMBT.CurrentBearishRetracementIndexIsValid(currentRetracementIndex))
                    {
                        return;
                    }

                    // double totalUpperDistance = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) - CurrentTick().Bid();
                    // int totalUpperLevels = 0;
                    // double upperLevelDistance = 0.0;
                    // // GetGridLevelsAndDistance(totalUpperDistance, totalUpperLevels, upperLevelDistance);
                    // GetGridLevelsForSetDistance(totalUpperDistance, totalUpperLevels);

                    // if (totalUpperLevels == 0)
                    // {
                    //     Print("No Upper Levels. Total Distance: ", totalUpperDistance, ", Upper Level Distance: ", upperLevelDistance,
                    //           ", Starting Levels: ", mStartingNumberOfLevels, ", Min Level Distance: ", mMinLevelPips);
                    //     return;
                    // }

                    double totalLowerDistance = CurrentTick().Bid() - iLow(mEntrySymbol, mEntryTimeFrame, currentRetracementIndex);
                    int totalLowerLevels = 0;
                    double lowerLevelDistance = 0.0;
                    // GetGridLevelsAndDistance(totalLowerDistance, totalLowerLevels, lowerLevelDistance);
                    GetGridLevelsForSetDistance(totalLowerDistance, totalLowerLevels);

                    if (totalLowerLevels == 0)
                    {
                        Print("No Lower Levels. Total Distance: ", totalLowerDistance, ", Upper Level Distance: ", lowerLevelDistance,
                              ", Starting Levels: ", mStartingNumberOfLevels, ", Min Level Distance: ", mMinLevelPips);
                        return;
                    }

                    mGT.ReInit(iOpen(mEntrySymbol, mEntryTimeFrame, 0),
                               1,
                               totalLowerLevels,
                               OrderHelper::PipsToRange(mMinLevelPips),
                               OrderHelper::PipsToRange(mMinLevelPips));

                    // double potentialMaxLoss = 0;
                    // double potentialMaxLossPips = 0;
                    // for (int i = totalUpperLevels; i > 0; i--)
                    // {
                    //     potentialMaxLoss += i;
                    // }

                    // potentialMaxLossPips = potentialMaxLoss * upperLevelDistance;

                    // potentialMaxLoss = 0;
                    // for (int i = totalLowerLevels; i > 0; i--)
                    // {
                    //     potentialMaxLoss += i;
                    // }

                    // potentialMaxLossPips += potentialMaxLoss * lowerLevelDistance;

                    // potentialMaxLossPips = OrderHelper::RangeToPips(totalUpperDistance + totalLowerDistance);
                    // potentialMaxLossPips = (totalUpperLevels + totalLowerLevels) * mMinLevelPips;
                    // mLotSize = OrderHelper::GetLotSize(potentialMaxLossPips, RiskPercent()) / (totalUpperLevels + totalLowerLevels);
                    mLastSetupMB = tempMBState.Number();
                    mHasSetup = true;
                }
            }
        }
    }
}

// will return the number of levels and the distance to fit them for grid perfectly in total Distanct
void MBGrid::GetGridLevelsAndDistance(double totalDistance, int &levels, double &levelDistance)
{
    levelDistance = totalDistance / mStartingNumberOfLevels;
    levels = mStartingNumberOfLevels;
    double minLevelDistance = OrderHelper::PipsToRange(mMinLevelPips);

    while (levelDistance < minLevelDistance)
    {
        levels -= 1;
        if (levels == 0)
        {
            Print("Zero Levels. Total Distance: ", totalDistance, ", Min Level Distance: ", minLevelDistance, ", Starting Levels: ", mStartingNumberOfLevels);
            break;
        }

        levelDistance = totalDistance / levels;
    }
}

// will return the number of levels that fits in total distance, but will not perfectly fit
void MBGrid::GetGridLevelsForSetDistance(double totalDistance, int &levels)
{
    if (totalDistance < OrderHelper::PipsToRange(mMinLevelPips))
    {
        levels = 0;
        return;
    }

    levels = totalDistance / OrderHelper::PipsToRange(mMinLevelPips);
}

void MBGrid::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(true);
    }

    if (mMBT.MBsCreated() - 1 != mLastSetupMB)
    {
        InvalidateSetup(true);
    }
}

void MBGrid::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBGrid>(this, deletePendingOrder, mStopTrading, error);

    mFirstTrade = true;
    mPreviousAchievedLevel = 1000;
    mStartingEquity = 0;
    mCloseAllTickets = false;
    mLevelsWithTickets.Clear();
    mGT.Reset();
}

bool MBGrid::Confirmation()
{
    // going to close all tickets
    // if (mGT.AtMaxLevel())
    // {
    //     return false;
    // }

    if ((SetupType() == OP_BUY && mGT.CurrentLevel() < 0) || (SetupType() == OP_SELL && mGT.CurrentLevel() > 0))
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

void MBGrid::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
        // don't want to place a tp on the last level because they we won't call ManagePreviousSetupTickets on it to check that we are at the last level
        // takeProfit = mGT.AtMaxLevel() ? 0.0 : mGT.LevelPrice(mGT.CurrentLevel() + 1);
        if (mGT.CurrentLevel() == 0)
        {
            stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());
        }
        else
        {
            stopLoss = mGT.LevelPrice(mGT.CurrentLevel() - 1);
        }
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
        // don't want to place a tp on the last level because they we won't call ManagePreviousSetupTickets on it to check that we are at the last level
        // takeProfit = mGT.AtMaxLevel() ? 0.0 : mGT.LevelPrice(mGT.CurrentLevel() - 1);
        // stopLoss = mGT.LevelPrice(mGT.CurrentLevel() + 1);
        if (mGT.CurrentLevel() == 0)
        {
            stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());
        }
        else
        {
            stopLoss = mGT.LevelPrice(mGT.CurrentLevel() + 1);
        }
    }

    if (mFirstTrade)
    {
        mStartingEquity = AccountEquity();
        mFirstTrade = false;
    }

    EAHelper::PlaceMarketOrder<MBGrid>(this, entry, stopLoss);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLevelsWithTickets.Add(mGT.CurrentLevel(), mCurrentSetupTickets[0].Number());
    }
}

void MBGrid::PreManageTickets()
{
    if (mCloseAllTickets)
    {
        return;
    }

    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<MBGrid>(this, mStartingEquity);
    if (equityPercentChange <= mMaxEquityDrawDown)
    {
        Print("Equity Limit Reached: ", equityPercentChange);
        mCloseAllTickets = true;
    }
}

void MBGrid::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void MBGrid::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool MBGrid::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void MBGrid::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
        return;
    }

    EAHelper::MoveToBreakEvenAfterPips<MBGrid>(this, ticket, 25);
    EAHelper::CheckTrailStopLossEveryXPips<MBGrid>(this, ticket, 50, 25);
}

void MBGrid::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void MBGrid::CheckPreviousSetupTicket(Ticket &ticket)
{
    bool isClosed = false;
    ticket.IsClosed(isClosed);
    if (isClosed)
    {
        mLevelsWithTickets.RemoveByValue(ticket.Number());
    }
}

void MBGrid::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBGrid>(this, ticket);
}

void MBGrid::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void MBGrid::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBGrid>(this, ticket, Period());
}

void MBGrid::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBGrid>(this, error, additionalInformation);
}

bool MBGrid::ShouldReset()
{
    return !EAHelper::WithinTradingSession<MBGrid>(this);
}

void MBGrid::Reset()
{
}