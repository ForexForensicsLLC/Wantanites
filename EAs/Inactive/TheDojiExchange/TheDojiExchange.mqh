//+------------------------------------------------------------------+
//|                                                        TheDojiExchange.mqh |
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

class TheDojiExchange : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    double mFixedStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mFirstMBInSetupNumber;
    datetime mEntryCandleTime;

public:
    TheDojiExchange(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheDojiExchange();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? -1 : -1; }
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

TheDojiExchange::TheDojiExchange(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;
    mFirstMBInSetupNumber = EMPTY;

    mFixedStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mBarCount = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEntryCandleTime = 0;

    // TODO: Change Back
    mLargestAccountBalance = 100000;

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheDojiExchange>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheDojiExchange, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheDojiExchange, SingleTimeFrameEntryTradeRecord>(this);
}

TheDojiExchange::~TheDojiExchange()
{
}

double TheDojiExchange::RiskPercent()
{
    return EAHelper::GetReducedRiskPerPercentLost<TheDojiExchange>(this, 1, 0.05);
}

void TheDojiExchange::Run()
{
    EAHelper::RunDrawMBT<TheDojiExchange>(this, mSetupMBT);
}

bool TheDojiExchange::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheDojiExchange>(this) && EAHelper::WithinTradingSession<TheDojiExchange>(this);
}

void TheDojiExchange::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<TheDojiExchange>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void TheDojiExchange::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        mHasSetup = false;
        mFirstMBInSetupNumber = EMPTY;
    }
}

void TheDojiExchange::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheDojiExchange>(this, deletePendingOrder, false, error);
}

bool TheDojiExchange::Confirmation()
{
    bool zoneIsHolding = false;
    int zoneIsHoldingError = EAHelper::MostRecentMBZoneIsHolding<TheDojiExchange>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);
    if (zoneIsHoldingError != ERR_NO_ERROR)
    {
        InvalidateSetup(true);
        return false;
    }

    if (!zoneIsHolding)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    bool potentialDoji = false;
    bool withinZone = false;

    if (mSetupType == OP_BUY)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
                        currentTick.bid < iLow(mEntrySymbol, mEntryTimeFrame, 1);

        withinZone = iLow(mEntrySymbol, mEntryTimeFrame, 0) <= tempZoneState.EntryPrice() && currentTick.bid >= tempZoneState.ExitPrice();
    }
    else if (mSetupType == OP_SELL)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
                        currentTick.bid > iHigh(mEntrySymbol, mEntryTimeFrame, 1);

        withinZone = iHigh(mEntrySymbol, mEntryTimeFrame, 0) >= tempZoneState.EntryPrice() && currentTick.bid <= tempZoneState.ExitPrice();
    }

    return mCurrentSetupTicket.Number() != EMPTY || (potentialDoji && withinZone);
}

void TheDojiExchange::PlaceOrders()
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
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = entry - OrderHelper::PipsToRange(mFixedStopLossPips);

        // don't place the order if it is going to activate right away
        if (currentTick.ask > entry)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = entry + OrderHelper::PipsToRange(mFixedStopLossPips);

        if (currentTick.bid < entry)
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<TheDojiExchange>(this, entry, stopLoss);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }
}

void TheDojiExchange::ManageCurrentPendingSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mEntryCandleTime == 0)
    {
        return;
    }

    if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 0)
    {
        mCurrentSetupTicket.Close();
    }
}

void TheDojiExchange::ManageCurrentActiveSetupTicket()
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TheDojiExchange>(this, mBEAdditionalPips);
    }
}

bool TheDojiExchange::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheDojiExchange>(this, ticket);
}

void TheDojiExchange::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TheDojiExchange>(this, ticketIndex);
}

void TheDojiExchange::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheDojiExchange>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheDojiExchange>(this);
}

void TheDojiExchange::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheDojiExchange>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TheDojiExchange>(this, ticketIndex);
}

void TheDojiExchange::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheDojiExchange>(this);
}

void TheDojiExchange::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheDojiExchange>(this, oldTicketIndex, newTicketNumber);
}

void TheDojiExchange::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheDojiExchange>(this, ticket, Period());
}

void TheDojiExchange::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheDojiExchange>(this, error, additionalInformation);
}

void TheDojiExchange::Reset()
{
}
