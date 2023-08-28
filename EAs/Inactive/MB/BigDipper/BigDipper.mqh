//+------------------------------------------------------------------+
//|                                                    BigDipper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>
#include <Wantanites\Framework\Objects\Indicators\Candle\CandleStickTracker.mqh>

class BigDipper : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;
    CandleStickTracker *mCST;

    int mFirstMBInSetup;
    int mBigDipperDipStartIndex;

public:
    BigDipper(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, CandleStickTracker *&cst);
    ~BigDipper();

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
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

BigDipper::BigDipper(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt, CandleStickTracker *&cst)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mCST = cst;

    mFirstMBInSetup = ConstantValues::EmptyInt;
    mBigDipperDipStartIndex = ConstantValues::EmptyInt;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<BigDipper>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<BigDipper, SingleTimeFrameEntryTradeRecord>(this);
}

BigDipper::~BigDipper()
{
}

void BigDipper::PreRun()
{
    mMBT.Draw();
    EARunHelper::ShowOpenTicketProfit<BigDipper>(this);
}

bool BigDipper::AllowedToTrade()
{
    return EARunHelper::BelowSpread<BigDipper>(this) && EARunHelper::WithinTradingSession<BigDipper>(this);
}

void BigDipper::CheckSetSetup()
{
    if (EASetupHelper::CheckSetSingleMBSetup<BigDipper>(this, mMBT, mFirstMBInSetup, SetupType()))
    {
        if (mFirstMBInSetup != 26)
        {
            return;
        }

        mHasSetup = true;
    }
}

void BigDipper::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetup != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
    }
}

void BigDipper::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<BigDipper>(this, deletePendingOrder, mStopTrading, error);
    mFirstMBInSetup = ConstantValues::EmptyInt;
    mBigDipperDipStartIndex = ConstantValues::EmptyInt;
}

/// @brief We are looking for a big dipper setup and then a candle that breaks further
/// @return
bool BigDipper::Confirmation()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return !mCurrentSetupTickets.IsEmpty();
    }

    if (!EASetupHelper::MostRecentMBZoneIsHolding<BigDipper>(this, mMBT, mFirstMBInSetup))
    {
        return false;
    }

    int startIndex;
    int retracementIndex;

    if (SetupType() == SignalType::Bullish)
    {
        if (!mMBT.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return false;
        }

        if (!MQLHelper::GetLowestIndexBetween(EntrySymbol(), EntryTimeFrame(), retracementIndex, 0, false, startIndex))
        {
            return false;
        }
    }
    else if (SetupType() == SignalType::Bearish)
    {
        if (!mMBT.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return false;
        }

        if (!MQLHelper::GetHighestIndexBetween(EntrySymbol(), EntryTimeFrame(), retracementIndex, 0, false, startIndex))
        {
            return false;
        }
    }

    if (EASetupHelper::RunningBigDipperSetup<BigDipper>(this, startIndex, mBigDipperDipStartIndex))
    {
        int furthestCandleInBigDipper;
        if (SetupType() == SignalType::Bullish)
        {
            if (!MQLHelper::GetLowestIndexBetween(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex, 0, false, furthestCandleInBigDipper))
            {
                return false;
            }
        }
        else if (SetupType() == SignalType::Bearish)
        {
            if (!MQLHelper::GetHighestIndexBetween(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex, 0, false, furthestCandleInBigDipper))
            {
                return false;
            }
        }

        return EASetupHelper::CandleIsInPendingZone<BigDipper>(this, mMBT, SetupType(), furthestCandleInBigDipper);
    }

    return false;
}

void BigDipper::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        entry = iHigh(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex);

        double low;
        if (!MQLHelper::GetLowestLowBetween(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex, 0, true, low))
        {
            return;
        }

        stopLoss = MathMin(low, entry - PipConverter::PipsToPoints(1));
        takeProfit = entry + (MathAbs(entry - stopLoss) * 3);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = iLow(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex);

        double high;
        if (!MQLHelper::GetHighestHighBetween(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex, 0, true, high))
        {
            return;
        }

        stopLoss = MathMax(high, entry + PipConverter::PipsToPoints(1));
        takeProfit = entry - (MathAbs(entry - stopLoss) * 3);
    }

    // bool canLose = MathRand() % 11 == 0;
    // if (canLose)
    // {
    //     EAOrderHelper::PlaceMarketOrder<BigDipper>(this, entry, stopLoss);
    // }
    // else if (EASetupHelper::TradeWillWin<BigDipper>(this, iTime(EntrySymbol(), EntryTimeFrame(), 0), stopLoss, takeProfit))
    // {
    // }
    EAOrderHelper::PlaceStopOrder<BigDipper>(this, entry, stopLoss);
}

void BigDipper::PreManageTickets()
{
}

void BigDipper::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    double newStopLoss;
    if (SetupType() == SignalType::Bullish)
    {
        if (!MQLHelper::GetLowestLowBetween(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex, 0, true, newStopLoss))
        {
            return;
        }
    }
    else if (SetupType() == SignalType::Bearish)
    {
        if (!MQLHelper::GetHighestHighBetween(EntrySymbol(), EntryTimeFrame(), mBigDipperDipStartIndex, 0, true, newStopLoss))
        {
            return;
        }
    }

    EAOrderHelper::ModifyTicketStopLoss<BigDipper>(this, ticket, __FUNCTION__, newStopLoss, true);
}

void BigDipper::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<BigDipper>(this, ticket);
}

bool BigDipper::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void BigDipper::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void BigDipper::CheckCurrentSetupTicket(Ticket &ticket)
{
    // Make sure we are only ever losing how much we intend to risk, even if we entered at a worse price due to slippage
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if ((AccountInfoDouble(ACCOUNT_EQUITY) - accountBalance) / accountBalance * 100 <= -RiskPercent())
    {
        ticket.Close();
    }
}

void BigDipper::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void BigDipper::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<BigDipper>(this, ticket);
}

void BigDipper::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void BigDipper::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<BigDipper>(this, ticket);
}

void BigDipper::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<BigDipper>(this, methodName, error, additionalInformation);
}

bool BigDipper::ShouldReset()
{
    return false;
}

void BigDipper::Reset()
{
}