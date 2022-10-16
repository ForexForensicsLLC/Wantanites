//+------------------------------------------------------------------+
//|                                                    PrimeMembership.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\EA\EA.mqh>
#include <SummitCapital\Framework\Helpers\EAHelper.mqh>
#include <SummitCapital\Framework\Constants\MagicNumbers.mqh>

class PrimeMembership : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mAdditionalEntryPips;
    double mFixedStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;
    datetime mEntryCandleTime;

public:
    PrimeMembership(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~PrimeMembership();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::NasPrimeBuys : MagicNumbers::NasPrimeSells; }
    virtual double RiskPercent();

    virtual void Run();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void ManageCurrentPendingSetupTicket();
    virtual void ManageCurrentActiveSetupTicket();
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(int ticketIndex);
    virtual void CheckCurrentSetupTicket();
    virtual void CheckPreviousSetupTicket(int ticketIndex);
    virtual void RecordTicketOpenData();
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

PrimeMembership::PrimeMembership(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                                 double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter,
         exitCSVRecordWriter, errorCSVRecordWriter)
{
    mAdditionalEntryPips = 0.0;
    mFixedStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mBarCount = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEntryCandleTime = 0;

    mLargestAccountBalance = 100000;

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<PrimeMembership>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<PrimeMembership, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<PrimeMembership, SingleTimeFrameEntryTradeRecord>(this);
}

PrimeMembership::~PrimeMembership()
{
}

double PrimeMembership::RiskPercent()
{
    double totalPercentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;

    // we lost 4 %, risk only 0.1% / Trade
    if (totalPercentLost >= 4)
    {
        return 0.1;
    }
    // we lost 3%, risk only 0.25% / trade
    else if (totalPercentLost >= 3)
    {
        return 0.25;
    }

    // else, just risk normal amount
    return mRiskPercent;
}

void PrimeMembership::Run()
{
    EAHelper::Run<PrimeMembership>(this);
}

bool PrimeMembership::AllowedToTrade()
{
    return EAHelper::BelowSpread<PrimeMembership>(this) && EAHelper::WithinTradingSession<PrimeMembership>(this);
}

void PrimeMembership::CheckSetSetup()
{
    mHasSetup = true;
}

void PrimeMembership::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void PrimeMembership::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<PrimeMembership>(this, deletePendingOrder, false, error);
}

bool PrimeMembership::Confirmation()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    bool potentialDoji = false;

    if (mSetupType == OP_BUY)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
                        currentTick.bid < iLow(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
                        currentTick.bid > iHigh(mEntrySymbol, mEntryTimeFrame, 1);
    }

    return mCurrentSetupTicket.Number() != EMPTY || potentialDoji;
}

void PrimeMembership::PlaceOrders()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
    {
        return;
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mAdditionalEntryPips);
        stopLoss = entry - OrderHelper::PipsToRange(mFixedStopLossPips);

        // don't place the order if it is going to activate right away
        if (currentTick.ask > entry)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mAdditionalEntryPips);
        stopLoss = entry + OrderHelper::PipsToRange(mFixedStopLossPips);

        if (currentTick.bid < entry)
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<PrimeMembership>(this, entry, stopLoss);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void PrimeMembership::ManageCurrentPendingSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mEntryCandleTime == 0)
    {
        return;
    }

    if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 1)
    {
        InvalidateSetup(true);
    }
}

void PrimeMembership::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        RecordError(selectError);
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    bool movedPips = false;
    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<PrimeMembership>(this, mBEAdditionalPips);
    }
}

bool PrimeMembership::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<PrimeMembership>(this, ticket);
}

void PrimeMembership::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<PrimeMembership>(this, ticketIndex);
}

void PrimeMembership::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PrimeMembership>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<PrimeMembership>(this);
}

void PrimeMembership::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PrimeMembership>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<PrimeMembership>(this, ticketIndex);
}

void PrimeMembership::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<PrimeMembership>(this);
}

void PrimeMembership::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<PrimeMembership>(this, oldTicketIndex, newTicketNumber);
}

void PrimeMembership::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<PrimeMembership>(this, ticket, Period());
}

void PrimeMembership::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<PrimeMembership>(this, error, additionalInformation);
}

void PrimeMembership::Reset()
{
}
