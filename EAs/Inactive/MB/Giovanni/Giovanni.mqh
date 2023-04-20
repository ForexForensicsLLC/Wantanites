//+------------------------------------------------------------------+
//|                                                    Giovanni.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\EA\EA.mqh>
#include <Wantanites\Framework\Helpers\EAHelper.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class Giovanni : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    Giovanni(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~Giovanni();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::GiovanniBuys : MagicNumbers::GiovanniSells; }
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

Giovanni::Giovanni(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupType = setupType;

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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<Giovanni>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<Giovanni, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<Giovanni, SingleTimeFrameEntryTradeRecord>(this);
}

Giovanni::~Giovanni()
{
}

double Giovanni::RiskPercent()
{
    return EAHelper::GetReducedRiskPerPercentLost<Giovanni>(this, 1, 0.05);
}

void Giovanni::Run()
{
    EAHelper::Run<Giovanni>(this);
}

bool Giovanni::AllowedToTrade()
{
    return EAHelper::BelowSpread<Giovanni>(this) && EAHelper::WithinTradingSession<Giovanni>(this);
}

void Giovanni::CheckSetSetup()
{
    mHasSetup = true;
}

void Giovanni::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void Giovanni::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<Giovanni>(this, deletePendingOrder, false, error);
}

bool Giovanni::Confirmation()
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

void Giovanni::PlaceOrders()
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

    EAHelper::PlaceStopOrder<Giovanni>(this, entry, stopLoss, 0.8);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void Giovanni::ManageCurrentPendingSetupTicket()
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

void Giovanni::ManageCurrentActiveSetupTicket()
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<Giovanni>(this, mBEAdditionalPips);
    }
}

bool Giovanni::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<Giovanni>(this, ticket);
}

void Giovanni::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<Giovanni>(this, ticketIndex);
}

void Giovanni::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<Giovanni>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<Giovanni>(this);
}

void Giovanni::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<Giovanni>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<Giovanni>(this, ticketIndex);
}

void Giovanni::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<Giovanni>(this);
}

void Giovanni::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Giovanni>(this, oldTicketIndex, newTicketNumber);
}

void Giovanni::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<Giovanni>(this, ticket, Period());
}

void Giovanni::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<Giovanni>(this, error, additionalInformation);
}

void Giovanni::Reset()
{
}
