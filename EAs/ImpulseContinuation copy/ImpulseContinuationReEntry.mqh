//+------------------------------------------------------------------+
//|                                                    ImpulseContinuationReEntry.mqh |
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

#include <SummitCapital\EAs\ImpulseContinuation\ImpulseContinuation.mqh>

class ImpulseContinuationReEntry : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    datetime mReEntryCandleTime;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    ImpulseContinuationReEntry(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~ImpulseContinuationReEntry();

    virtual double RiskPercent() { return mRiskPercent; }

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

ImpulseContinuationReEntry::ImpulseContinuationReEntry(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mImpulseContinuation = ic;

    mReEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseContinuationReEntry>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseContinuationReEntry, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseContinuationReEntry, MultiTimeFrameEntryTradeRecord>(this);

    mEntryBarCount = 0;

    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

ImpulseContinuationReEntry::~ImpulseContinuationReEntry()
{
}

void ImpulseContinuationReEntry::Run()
{
    EAHelper::Run<ImpulseContinuationReEntry>(this);
    mEntryBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseContinuationReEntry::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseContinuationReEntry>(this) && EAHelper::WithinTradingSession<ImpulseContinuationReEntry>(this);
}

void ImpulseContinuationReEntry::CheckSetSetup()
{
    // set by ImpulseContinuation
}

void ImpulseContinuationReEntry::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return;
    }

    if (mReEntryCandleTime > 0 && iBarShift(mEntrySymbol, mEntryTimeFrame, mReEntryCandleTime) > 10)
    {
        InvalidateSetup(true);
    }
}

void ImpulseContinuationReEntry::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseContinuationReEntry>(this, deletePendingOrder, false, error);
    mPlacedOrder = false;
}

bool ImpulseContinuationReEntry::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return hasTicket;
    }

    int reEntryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mReEntryCandleTime);
    bool brokeReEntryCandleIndex = false;
    if (mSetupType == OP_BUY)
    {
        brokeReEntryCandleIndex = iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, reEntryCandleIndex);
    }
    else if (mSetupType == OP_SELL)
    {
        brokeReEntryCandleIndex = iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, reEntryCandleIndex);
    }

    return hasTicket || brokeReEntryCandleIndex;
}

void ImpulseContinuationReEntry::PlaceOrders()
{
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
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<ImpulseContinuationReEntry>(this, currentTick.ask, stopLoss);
        }
        else if (entry > currentTick.ask)
        {
            EAHelper::PlaceStopOrder<ImpulseContinuationReEntry>(this, entry, stopLoss);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<ImpulseContinuationReEntry>(this, currentTick.bid, stopLoss);
        }
        else if (entry < currentTick.bid)
        {
            EAHelper::PlaceStopOrder<ImpulseContinuationReEntry>(this, entry, stopLoss);
        }
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mPlacedOrder = true;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mFailedImpulseEntryTime = 0;
    }
}

void ImpulseContinuationReEntry::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mSetupType == OP_BUY && entryCandleIndex > 1)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL && entryCandleIndex > 1)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }

    if (entryCandleIndex > 3)
    {
        InvalidateSetup(true);
    }
}

void ImpulseContinuationReEntry::ManageCurrentActiveSetupTicket()
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

    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }

        //     // close if we put in a bearish candle
        //     if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double lowest = 0.0;
        //     if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(1000);
    }
    else if (mSetupType == OP_SELL)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     // close if we put in a bullish candle
        //     if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double highest = 0.0;
        //     if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(1000);
    }

    // BE after we validate the MB we entered in
    if (movedPips /*|| mConfirmationMBT.MBsCreated() - 1 != mEntryMB*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseContinuationReEntry>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool ImpulseContinuationReEntry::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseContinuationReEntry>(this, ticket);
}

void ImpulseContinuationReEntry::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<ImpulseContinuationReEntry>(this, ticketIndex);
}

void ImpulseContinuationReEntry::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseContinuationReEntry>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseContinuationReEntry>(this);
}

void ImpulseContinuationReEntry::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseContinuationReEntry>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseContinuationReEntry>(this, ticketIndex);
}

void ImpulseContinuationReEntry::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseContinuationReEntry>(this);
}

void ImpulseContinuationReEntry::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseContinuationReEntry>(this, oldTicketIndex, newTicketNumber);
}

void ImpulseContinuationReEntry::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseContinuationReEntry>(this, ticket, Period());
}

void ImpulseContinuationReEntry::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseContinuationReEntry>(this, error, additionalInformation);
}

void ImpulseContinuationReEntry::Reset()
{
}