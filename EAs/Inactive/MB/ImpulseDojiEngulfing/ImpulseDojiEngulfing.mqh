//+------------------------------------------------------------------+
//|                                                    ImpulseDojiEngulfing.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class ImpulseDojiEngulfing : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;
    int mFirstMBInSetup;

    double mMinImpulseBodyPips;
    double mMinEngulfingBodyPips;

public:
    ImpulseDojiEngulfing(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~ImpulseDojiEngulfing();

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

ImpulseDojiEngulfing::ImpulseDojiEngulfing(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;
    mFirstMBInSetup = ConstantValues::EmptyInt;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseDojiEngulfing>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<ImpulseDojiEngulfing, SingleTimeFrameEntryTradeRecord>(this);
}

ImpulseDojiEngulfing::~ImpulseDojiEngulfing()
{
}

void ImpulseDojiEngulfing::PreRun()
{
    mMBT.Draw();
    EARunHelper::ShowOpenTicketProfit<ImpulseDojiEngulfing>(this);
}

bool ImpulseDojiEngulfing::AllowedToTrade()
{
    return EARunHelper::BelowSpread<ImpulseDojiEngulfing>(this) && EARunHelper::WithinTradingSession<ImpulseDojiEngulfing>(this);
}

void ImpulseDojiEngulfing::CheckSetSetup()
{
    if (EASetupHelper::CheckSetSingleMBSetup<ImpulseDojiEngulfing>(this, mMBT, mFirstMBInSetup, SetupType()))
    {
        mHasSetup = true;
    }
}

void ImpulseDojiEngulfing::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetup != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
    }
}

void ImpulseDojiEngulfing::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<ImpulseDojiEngulfing>(this, deletePendingOrder, mStopTrading, error);
    mFirstMBInSetup = ConstantValues::EmptyInt;
}

/// @brief We are looking for an impulse into the zone, a doji right after, and then an engulfing
/// @return
bool ImpulseDojiEngulfing::Confirmation()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return false;
    }

    // middle candle was a doji
    if (!EASetupHelper::DojiInsideMostRecentMBsHoldingZone<ImpulseDojiEngulfing>(this, mMBT, mFirstMBInSetup, 2))
    {
        return false;
    }

    // doji was furthest in zone
    if (!EASetupHelper::CandleIsInZone<ImpulseDojiEngulfing>(this, mMBT, mFirstMBInSetup, 2, true))
    {
        return false;
    }

    // imbalance push into zone
    if (!CandleStickHelper::HasImbalance(SignalType(), EntrySymbol(), EntryTimeFrame(), 3))
    {
        return false;
    }

    // imbalance was big enough
    if (!CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), 3) >= PipConverter::PipsToPoints(mMinImpulseBodyPips))
    {
        return false;
    }

    bool engulfing = true;
    if (SetupType() == SignalType::Bullish)
    {
        // engulfing = CandleStickHelper::IsBullish(EntrySymbol(), EntryTimeFrame(), 1) &&
        //             iClose(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), 2) &&
        //             CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), 1) >= PipConverter::PipsToPoints(mMinEngulfingBodyPips);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        // engulfing = CandleStickHelper::IsBearish(EntrySymbol(), EntryTimeFrame(), 1) &&
        //             iClose(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), 2) &&
        //             CandleStickHelper::BodyLength(EntrySymbol(), EntryTimeFrame(), 1) >= PipConverter::PipsToPoints(mMinEngulfingBodyPips);
    }

    return engulfing;
}

void ImpulseDojiEngulfing::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        stopLoss = MathMin(iLow(EntrySymbol(), EntryTimeFrame(), 1), entry - PipConverter::PipsToPoints(1));
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        stopLoss = MathMax(iHigh(EntrySymbol(), EntryTimeFrame(), 1), entry + PipConverter::PipsToPoints(1));
    }

    EAOrderHelper::PlaceMarketOrder<ImpulseDojiEngulfing>(this, entry, stopLoss);
}

void ImpulseDojiEngulfing::PreManageTickets()
{
}

void ImpulseDojiEngulfing::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void ImpulseDojiEngulfing::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    EAOrderHelper::CheckPartialTicket<ImpulseDojiEngulfing>(this, ticket);
}

bool ImpulseDojiEngulfing::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void ImpulseDojiEngulfing::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void ImpulseDojiEngulfing::CheckCurrentSetupTicket(Ticket &ticket)
{
    // Make sure we are only ever losing how much we intend to risk, even if we entered at a worse price due to slippage
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if ((AccountInfoDouble(ACCOUNT_EQUITY) - accountBalance) / accountBalance * 100 <= -RiskPercent())
    {
        ticket.Close();
    }
}

void ImpulseDojiEngulfing::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void ImpulseDojiEngulfing::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseDojiEngulfing>(this, ticket);
}

void ImpulseDojiEngulfing::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void ImpulseDojiEngulfing::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseDojiEngulfing>(this, ticket);
}

void ImpulseDojiEngulfing::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<ImpulseDojiEngulfing>(this, methodName, error, additionalInformation);
}

bool ImpulseDojiEngulfing::ShouldReset()
{
    return false;
}

void ImpulseDojiEngulfing::Reset()
{
}