//+------------------------------------------------------------------+
//|                                                    LargeMB.mqh |
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

class LargeMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    datetime mFirstOppositeCandleTime;

    double mMinMBHeight;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    LargeMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
            CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
            CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~LargeMB();

    double EMA(int index);
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

double LargeMB::EMA(int index)
{
    return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index);
}

LargeMB::LargeMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mFirstOppositeCandleTime = 0;

    mMinMBHeight = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LargeMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LargeMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LargeMB, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

LargeMB::~LargeMB()
{
}

double LargeMB::RiskPercent()
{
    return mRiskPercent;
}

void LargeMB::Run()
{
    EAHelper::RunDrawMBT<LargeMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool LargeMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<LargeMB>(this) && EAHelper::WithinTradingSession<LargeMB>(this) &&
           mLastEntryMB < mSetupMBT.MBsCreated() - 1;
}

void LargeMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<LargeMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.Height() < OrderHelper::PipsToRange(1250))
        {
            return;
        }

        mHasSetup = true;
    }
}

void LargeMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (mFirstOppositeCandleTime > 0)
    {
        int oppositeCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFirstOppositeCandleTime);
        if (mSetupType == OP_BUY)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, oppositeCandleIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, oppositeCandleIndex))
            {
                mLastEntryMB = mFirstMBInSetupNumber;
                InvalidateSetup(true);
            }
        }
    }
}

void LargeMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<LargeMB>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<LargeMB>(this, false);

    mFirstOppositeCandleTime = 0;
}

bool LargeMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
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

    if (!EAHelper::PriceIsFurtherThanPercentIntoMB<LargeMB>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.EntryPrice(), 0.7))
    {
        return false;
    }

    int startIndex = EMPTY;
    if (mSetupType == OP_BUY)
    {
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex(), 0, false, startIndex))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex(), 0, false, startIndex))
        {
            return false;
        }
    }

    return hasTicket || EAHelper::RunningBigDipperSetup<LargeMB>(this, iTime(mEntrySymbol, mEntryTimeFrame, startIndex));
}

void LargeMB::PlaceOrders()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<LargeMB>(this, currentTick.ask, stopLoss);
        }
        else if (entry > currentTick.ask)
        {
            EAHelper::PlaceStopOrder<LargeMB>(this, entry, stopLoss);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
        if (entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<LargeMB>(this, currentTick.bid, stopLoss);
        }
        else if (entry < currentTick.bid)
        {
            EAHelper::PlaceStopOrder<LargeMB>(this, entry, stopLoss);
        }
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mFailedImpulseEntryTime = 0;
    }
}

void LargeMB::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void LargeMB::ManageCurrentActiveSetupTicket()
{
    if (mFirstMBInSetupNumber != EMPTY && mLastEntryMB != mFirstMBInSetupNumber)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
    }

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

    // if (mSetupType == OP_BUY)
    // {
    //     if (orderPlaceIndex > 1)
    //     {
    //         // close if we fail to break with a body
    //         if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
    //             currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //         }

    //         // close if we put in a bearish candle
    //         if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (orderPlaceIndex > 3)
    //     {
    //         // close if we are still opening within our entry and get the chance to close at BE
    //         if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (mFailedImpulseEntryTime != 0)
    //     {
    //         int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
    //         double lowest = 0.0;
    //         if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
    //         {
    //             return;
    //         }

    //         // only close if we crossed our entry price after failing to run and then we go a bit in profit
    //         if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //         }
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (orderPlaceIndex > 1)
    //     {
    //         // close if we fail to break with a body
    //         if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
    //             currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //             return;
    //         }

    //         // close if we put in a bullish candle
    //         if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (orderPlaceIndex > 3)
    //     {
    //         // close if we are still opening above our entry and we get the chance to close at BE
    //         if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
    //         {
    //             mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    //         }
    //     }

    //     if (mFailedImpulseEntryTime != 0)
    //     {
    //         int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
    //         double highest = 0.0;
    //         if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
    //         {
    //             return;
    //         }

    //         // only close if we crossed our entry price after failing to run and then we go a bit in profit
    //         if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
    //         {
    //             mCurrentSetupTicket.Close();
    //         }
    //     }
    // }

    // BE after we validate the MB we entered in
    if (mSetupMBT.MBsCreated() - 1 != mLastEntryMB /*|| entryIndex > 3*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<LargeMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool LargeMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LargeMB>(this, ticket);
}

void LargeMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<LargeMB>(this, ticketIndex);
}

void LargeMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LargeMB>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<LargeMB>(this);
}

void LargeMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LargeMB>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<LargeMB>(this, ticketIndex);
}

void LargeMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LargeMB>(this);
}

void LargeMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LargeMB>(this, oldTicketIndex, newTicketNumber);
}

void LargeMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LargeMB>(this, ticket, Period());
}

void LargeMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LargeMB>(this, error, additionalInformation);
}

void LargeMB::Reset()
{
}