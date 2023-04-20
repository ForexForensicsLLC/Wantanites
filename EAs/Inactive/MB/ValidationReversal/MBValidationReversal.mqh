//+------------------------------------------------------------------+
//|                                                    MBValidationReversal.mqh |
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

#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>

#include <Wantanites\Framework\Symbols\EURUSD.mqh>

class MBValidationReversal : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    ObjectList<EconomicEvent> *mEconomicEvents;
    List<string> *mEconomicEventTitles;
    List<string> *mEconomicEventSymbols;
    List<int> *mEconomicEventImpacts;

    MBTracker *mMBT;

    int mFirstMBInSetupNumber;
    int mLastSetupMBNumber;

    bool mLoadedTodaysEvents;
    bool mCloseAllTickets;

    double mFurthestEquityDrawDownPercent;
    datetime mFurthestEquityDrawDownTime;

    double mFurthestTotalEquityDrawDownPercent;
    datetime mFurthestTotalEquityDrawDownTime;

public:
    MBValidationReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~MBValidationReversal();

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

MBValidationReversal::MBValidationReversal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEconomicEvents = new ObjectList<EconomicEvent>();
    mMBT = mbt;

    mFirstMBInSetupNumber = EMPTY;
    mLastSetupMBNumber = EMPTY;

    mLoadedTodaysEvents = false;
    mCloseAllTickets = false;

    mFurthestEquityDrawDownPercent = 0.0;
    mFurthestEquityDrawDownTime = 0;

    mFurthestTotalEquityDrawDownPercent = 0.0;
    mFurthestTotalEquityDrawDownTime = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBValidationReversal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBValidationReversal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBValidationReversal, SingleTimeFrameEntryTradeRecord>(this);
}

MBValidationReversal::~MBValidationReversal()
{
    delete mEconomicEvents;

    Print("Magic Number: ", MagicNumber(), ", Furthest Equity DD Percent: ", mFurthestEquityDrawDownPercent, " at ", TimeToStr(mFurthestEquityDrawDownTime));
    Print("Magic Number: ", MagicNumber(), ", Furthest Total Equity DD Percent: ", mFurthestTotalEquityDrawDownPercent, " at ", TimeToStr(mFurthestTotalEquityDrawDownTime));
}

void MBValidationReversal::PreRun()
{
    mMBT.DrawNMostRecentMBs(-1);
    mMBT.DrawZonesForNMostRecentMBs(-1);
}

bool MBValidationReversal::AllowedToTrade()
{
    return (EAHelper::BelowSpread<MBValidationReversal>(this) && EAHelper::WithinTradingSession<MBValidationReversal>(this)) || mPreviousSetupTickets.Size() > 0;
}

void MBValidationReversal::CheckSetSetup()
{
    if (!mLoadedTodaysEvents)
    {
        EAHelper::GetEconomicEventsForDate<MBValidationReversal>(this, TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, mEconomicEventImpacts);
        mLoadedTodaysEvents = true;
    }

    if (!mEconomicEvents.IsEmpty())
    {
        mStopTrading = true;
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return;
    }

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Number() == mLastSetupMBNumber)
    {
        return;
    }

    if (SetupType() == OP_BUY && tempMBState.Type() == OP_SELL)
    {
        mHasSetup = true;
        mFirstMBInSetupNumber = tempMBState.Number();
    }
    else if (SetupType() == OP_SELL && tempMBState.Type() == OP_BUY)
    {
        mHasSetup = true;
        mFirstMBInSetupNumber = tempMBState.Number();
    }
}

void MBValidationReversal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (mCloseAllTickets && mPreviousSetupTickets.Size() == 0)
    {
        mCloseAllTickets = false;
    }
}

void MBValidationReversal::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    mFirstMBInSetupNumber = EMPTY;
    EAHelper::InvalidateSetup<MBValidationReversal>(this, deletePendingOrder, mStopTrading, error);
}

bool MBValidationReversal::Confirmation()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= BarCount())
    {
        return false;
    }

    MBState *tempMBState;
    if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    return tempMBState.EndIndex() == 1;
}

void MBValidationReversal::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double lotSize = 0.0;

    if (SetupType() == OP_BUY)
    {
        entry = CurrentTick().Ask();
    }
    else if (SetupType() == OP_SELL)
    {
        entry = CurrentTick().Bid();
    }

    double currentDrawdown = 0.0;
    for (int i = 0; i < mPreviousSetupTickets.Size(); i++)
    {
        currentDrawdown += mPreviousSetupTickets[i].Profit();
    }

    double valuePerPipPerLot = EURUSD::PipValuePerLot();
    double equityTarget = (AccountBalance() * 0.02) + MathAbs(currentDrawdown);
    // double profitPerPip = equityTarget / mSurviveTargetPips;
    lotSize = equityTarget / valuePerPipPerLot / 15;

    EAHelper::PlaceMarketOrder<MBValidationReversal>(this, entry, stopLoss, lotSize);
    if (!mCurrentSetupTickets.IsEmpty())
    {
        mLastSetupMBNumber = mFirstMBInSetupNumber;
        InvalidateSetup(false);
    }
}

void MBValidationReversal::PreManageTickets()
{
    double equityPercentChange = EAHelper::GetTotalPreviousSetupTicketsEquityPercentChange<MBValidationReversal>(this, AccountBalance());
    if (equityPercentChange < mFurthestEquityDrawDownPercent)
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

    if (equityPercentChange >= 2)
    {
        mCloseAllTickets = true;
        // mStopTrading = true;
        return;
    }
}

void MBValidationReversal::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void MBValidationReversal::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool MBValidationReversal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void MBValidationReversal::ManagePreviousSetupTicket(Ticket &ticket)
{
    if (mCloseAllTickets)
    {
        ticket.Close();
    }
}

void MBValidationReversal::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void MBValidationReversal::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void MBValidationReversal::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBValidationReversal>(this, ticket);
}

void MBValidationReversal::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBValidationReversal>(this, partialedTicket, newTicketNumber);
}

void MBValidationReversal::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBValidationReversal>(this, ticket, Period());
}

void MBValidationReversal::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBValidationReversal>(this, error, additionalInformation);
}

bool MBValidationReversal::ShouldReset()
{
    return !EAHelper::WithinTradingSession<MBValidationReversal>(this) && mPreviousSetupTickets.Size() == 0;
}

void MBValidationReversal::Reset()
{
    mStopTrading = false;
    mCloseAllTickets = false;
    mLoadedTodaysEvents = false;
    mEconomicEvents.Clear();

    InvalidateSetup(false);
}