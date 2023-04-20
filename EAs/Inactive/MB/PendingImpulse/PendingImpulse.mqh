//+------------------------------------------------------------------+
//|                                                    PendingImpulse.mqh |
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

class PendingImpulse : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mThirdMBInSetupNumber;

    double mMinMBRatio;
    double mMaxMBRatio;

    double mMinMBHeight;
    double mMaxMBHeight;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;
    bool mClosedOutsideEntry;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    PendingImpulse(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~PendingImpulse();

    double EMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 100, 0, MODE_EMA, PRICE_CLOSE, index); }
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
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

PendingImpulse::PendingImpulse(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mThirdMBInSetupNumber = EMPTY;

    mMinMBRatio = 0.0;
    mMaxMBRatio = 0.0;

    mMinMBHeight = 0.0;
    mMaxMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<PendingImpulse>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<PendingImpulse, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<PendingImpulse, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;
    mClosedOutsideEntry = false;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

PendingImpulse::~PendingImpulse()
{
}

double PendingImpulse::RiskPercent()
{
    return mRiskPercent;
}

void PendingImpulse::Run()
{
    EAHelper::RunDrawMBT<PendingImpulse>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool PendingImpulse::AllowedToTrade()
{
    return EAHelper::BelowSpread<PendingImpulse>(this) && EAHelper::WithinTradingSession<PendingImpulse>(this);
}

void PendingImpulse::CheckSetSetup()
{
    if (mSetupType == OP_BUY)
    {
        if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 0) >= 0.2)
        {
            mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 0) <= -0.2)
        {
            mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            mHasSetup = true;
        }
    }
}

void PendingImpulse::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mEntryCandleTime > 0 && iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 0)
    {
        InvalidateSetup(true);
    }
}

void PendingImpulse::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<PendingImpulse>(this, deletePendingOrder, false, error);
}

bool PendingImpulse::Confirmation()
{
    return true;
}

void PendingImpulse::PlaceOrders()
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
        entry = currentTick.ask;
        stopLoss = entry - OrderHelper::PipsToRange(750);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = entry + OrderHelper::PipsToRange(750);
    }

    EAHelper::PlaceMarketOrder<PendingImpulse>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
    }
}

void PendingImpulse::ManageCurrentPendingSetupTicket()
{
}

void PendingImpulse::ManageCurrentActiveSetupTicket()
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
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

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

        // close if we pushed 20% into our SL
        double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // // TODO: instead of doing this, just BE
        // if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
        // {
        //     double highestBody = 0.0;
        //     if (!MQLHelper::GetHighestBodyBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 0, true, highestBody))
        //     {
        //         return;
        //     }

        //     if (highestBody > OrderOpenPrice())
        //     {
        //         mClosedOutsideEntry = true;
        //     }
        // }

        // // close if we closed out of our SL but came back
        // if (mClosedOutsideEntry && currentTick.bid <= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
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

        // close if we push 20% into our SL
        double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
        // {
        //     double lowestBody = 0.0;
        //     if (!MQLHelper::GetLowestBodyBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 0, true, lowestBody))
        //     {
        //         return;
        //     }

        //     if (lowestBody < OrderOpenPrice())
        //     {
        //         mClosedOutsideEntry = true;
        //     }
        // }

        // // close if we closed out of our SL but came back
        // if (mClosedOutsideEntry && currentTick.ask >= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // BE after we validate the MB we entered in
    // if (mSetupMBT.MBsCreated() - 1 != mEntryMB)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<PendingImpulse>(this, mBEAdditionalPips);
    // }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<PendingImpulse>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<PendingImpulse>(this, mCurrentSetupTicket);
}

bool PendingImpulse::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<PendingImpulse>(this, ticket);
}

void PendingImpulse::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<PendingImpulse>(this, mPreviousSetupTickets[ticketIndex]);
}

void PendingImpulse::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PendingImpulse>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<PendingImpulse>(this);
}

void PendingImpulse::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PendingImpulse>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<PendingImpulse>(this, ticketIndex);
}

void PendingImpulse::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<PendingImpulse>(this);
}

void PendingImpulse::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<PendingImpulse>(this, partialedTicket, newTicketNumber);
}

void PendingImpulse::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<PendingImpulse>(this, ticket, Period());
}

void PendingImpulse::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<PendingImpulse>(this, error, additionalInformation);
}

void PendingImpulse::Reset()
{
}