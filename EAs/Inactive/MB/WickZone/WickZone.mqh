//+------------------------------------------------------------------+
//|                                                    WickZone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Utilities\CandleStickTracker.mqh>
#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class WickZone : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;

    int mFirstMBInSetupNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;

    datetime mFailedImpulseEntryTime;
    bool mClosedOutsideEntry;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    WickZone(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~WickZone();

    double EMA(int index) { return iMA(EntrySymbol(), EntryTimeFrame(), 100, 0, MODE_EMA, PRICE_CLOSE, index); }
    virtual double RiskPercent();

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

WickZone::WickZone(int magicNumber, SignalType setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = setupMBT;
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<WickZone>(this);
    EAInitHelper::UpdatePreviousSetupTicketsRRAcquried<WickZone, PartialTradeRecord>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<WickZone, MultiTimeFrameEntryTradeRecord>(this);

    mEntryMB = ConstantValues::EmptyInt;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;
    mClosedOutsideEntry = false;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

WickZone::~WickZone()
{
}

double WickZone::RiskPercent()
{
    return mRiskPercent;
}

void WickZone::PreRun()
{
    mMBT.Draw();
}

bool WickZone::AllowedToTrade()
{
    return EARunHelper::BelowSpread<WickZone>(this) && EARunHelper::WithinTradingSession<WickZone>(this);
}

void WickZone::CheckSetSetup()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (EASetupHelper::CheckSetSingleMBSetup<WickZone>(this, mMBT, mFirstMBInSetupNumber, SetupType()))
    {
        mHasSetup = true;
    }
}

void WickZone::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        if (mFirstMBInSetupNumber != mMBT.MBsCreated() - 1)
        {
            InvalidateSetup(false);
        }
    }
}

void WickZone::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    mFirstMBInSetupNumber = ConstantValues::EmptyInt;
    EASetupHelper::InvalidateSetup<WickZone>(this, deletePendingOrder, false, error);
}

bool WickZone::Confirmation()
{
    // bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    // if (hasTicket)
    // {
    //     return hasTicket;
    // }

    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return false;
    }

    MBState *tempMBState;
    if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    int start = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    if (start < 2)
    {
        return false;
    }

    double minWickPips = 5;
    double fiftyPercentOfZone = 0.0;
    bool firstCandleWickedThroughZone = false;
    bool secondCandleDidNotGoFurther = false;

    if (SetupType() == SignalType::Bullish)
    {
        return CandleStickHelper::LowestBodyPart(EntrySymbol(), EntryTimeFrame(), 1) > tempZoneState.EntryPrice() &&
               // iLow(EntrySymbol(), EntryTimeFrame(), 0) < tempZoneState.ExitPrice() &&
               CandleStickHelper::LowestBodyPart(EntrySymbol(), EntryTimeFrame(), 1) - iLow(EntrySymbol(), EntryTimeFrame(), 1) > PipConverter::PipsToPoints(minWickPips);
    }
    else if (SetupType() == SignalType::Bearish)
    {
        return CandleStickHelper::HighestBodyPart(EntrySymbol(), EntryTimeFrame(), 1) < tempZoneState.EntryPrice() &&
               // iHigh(EntrySymbol(), EntryTimeFrame(), 0) > tempZoneState.ExitPrice() &&
               iHigh(EntrySymbol(), EntryTimeFrame(), 1) - CandleStickHelper::HighestBodyPart(EntrySymbol(), EntryTimeFrame(), 1) > PipConverter::PipsToPoints(minWickPips);
    }

    return false;
}

void WickZone::PlaceOrders()
{
    // if (mCurrentSetupTicket.Number() != EMPTY)
    // {
    //     return;
    // }

    // MqlTick currentTick;
    // if (!SymbolInfoTick(Symbol(), currentTick))
    // {
    //     RecordError(GetLastError());
    //     return;
    // }

    // MBState *tempMBState;
    // if (!mMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    // {
    //     return;
    // }

    // ZoneState *tempZoneState;
    // if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    // {
    //     return;
    // }

    double entry = 0.0;
    double stopLoss = 0.0;
    double takeProfit = 0.0;

    if (SetupType() == OP_BUY)
    {
        // entry = iHigh(EntrySymbol(), EntryTimeFrame(), 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
        entry = CurrentTick().Ask();
        stopLoss = iLow(EntrySymbol(), EntryTimeFrame(), 1) - PipConverter::PipsToPoints(mStopLossPaddingPips);
        takeProfit = entry + (MathAbs(entry - stopLoss) * 3);
    }
    else if (SetupType() == OP_SELL)
    {
        // entry = iLow(EntrySymbol(), EntryTimeFrame(), 1);
        entry = CurrentTick().Bid();
        stopLoss = iHigh(EntrySymbol(), EntryTimeFrame(), 1) + PipConverter::PipsToPoints(mStopLossPaddingPips /*+ mMaxSpreadPips*/);
        takeProfit = entry - (MathAbs(entry - stopLoss) * 3);
    }

    // EAHelper::PlaceStopOrder<WickZone>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);
    if (EASetupHelper::TradeWillWin<WickZone>(this, iTime(EntrySymbol(), EntryTimeFrame(), 0), entry, stopLoss, takeProfit))
    {
        EAOrderHelper::PlaceMarketOrder<WickZone>(this, entry, stopLoss);
    }

    // if (mCurrentSetupTicket.Number() != EMPTY)
    // {
    //     mEntryMB = mFirstMBInSetupNumber;
    //     mEntryCandleTime = iTime(EntrySymbol(), EntryTimeFrame(), 1);

    //     mFailedImpulseEntryTime = 0;
    //     mClosedOutsideEntry = false;
    // }
}

void WickZone::PreManageTickets()
{
    double profit = 0.0;
    for (int i = 0; i < mCurrentSetupTickets.Size(); i++)
    {
        profit += mCurrentSetupTickets[i].Profit();
    }

    double profitTarget = AccountInfoDouble(ACCOUNT_BALANCE) * .003;
    if (profit > profitTarget)
    {
        for (int i = 0; i < mCurrentSetupTickets.Size(); i++)
        {
            mCurrentSetupTickets[i].Close();
        }
    }
}

void WickZone::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
    // int entryCandleIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // if (entryCandleIndex > 1)
    // {
    //     InvalidateSetup(true);
    // }

    // if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    // {
    //     return;
    // }

    // if (SetupType() == OP_BUY)
    // {
    //     if (iClose(EntrySymbol(), EntryTimeFrame(), 1) < iLow(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (SetupType() == OP_SELL)
    // {
    //     if (iClose(EntrySymbol(), EntryTimeFrame(), 1) > iHigh(EntrySymbol(), EntryTimeFrame(), entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
}

void WickZone::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // int selectError = mCurrentSetupTicket.SelectIfOpen("Stuff");
    // if (TerminalErrors::IsTerminalError(selectError))
    // {
    //     RecordError(selectError);
    //     return;
    // }

    // MqlTick currentTick;
    // if (!SymbolInfoTick(Symbol(), currentTick))
    // {
    //     RecordError(GetLastError());
    //     return;
    // }

    // bool movedPips = false;
    // int orderPlaceIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mEntryCandleTime);
    // int entryIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), OrderOpenTime());

    if (SetupType() == OP_BUY)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(EntrySymbol(), EntryTimeFrame(), entryIndex) < iHigh(EntrySymbol(), EntryTimeFrame(), orderPlaceIndex) &&
        //         currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }

        //     // close if we put in a bearish candle
        //     if (CandleStickHelper::IsBearish(EntrySymbol(), EntryTimeFrame(), 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(EntrySymbol(), EntryTimeFrame(), 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(EntrySymbol(), EntryTimeFrame(), 0) < iHigh(EntrySymbol(), EntryTimeFrame(), orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(EntrySymbol(), EntryTimeFrame(), 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mFailedImpulseEntryTime);
        //     double lowest = 0.0;
        //     if (!MQLHelper::GetLowestLowBetween(EntrySymbol(), EntryTimeFrame(), failedImpulseEntryIndex, 0, true, lowest))
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
        // double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        // if (percentIntoSL >= 0.2)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // // TODO: instead of doing this, just BE
        // if (iBars(EntrySymbol(), EntryTimeFrame()) > BarCount())
        // {
        //     double highestBody = 0.0;
        //     if (!MQLHelper::GetHighestBodyBetween(EntrySymbol(), EntryTimeFrame(), entryIndex, 0, true, highestBody))
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

        // movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (SetupType() == OP_SELL)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(EntrySymbol(), EntryTimeFrame(), entryIndex) > iLow(EntrySymbol(), EntryTimeFrame(), orderPlaceIndex) &&
        //         currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     // close if we put in a bullish candle
        //     if (CandleStickHelper::IsBullish(EntrySymbol(), EntryTimeFrame(), 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(EntrySymbol(), EntryTimeFrame(), 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(EntrySymbol(), EntryTimeFrame(), 0) > iLow(EntrySymbol(), EntryTimeFrame(), orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(EntrySymbol(), EntryTimeFrame(), 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(EntrySymbol(), EntryTimeFrame(), mFailedImpulseEntryTime);
        //     double highest = 0.0;
        //     if (!MQLHelper::GetHighestHighBetween(EntrySymbol(), EntryTimeFrame(), failedImpulseEntryIndex, 0, true, highest))
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
        // double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        // if (percentIntoSL >= 0.2)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // if (iBars(EntrySymbol(), EntryTimeFrame()) > BarCount())
        // {
        //     double lowestBody = 0.0;
        //     if (!MQLHelper::GetLowestBodyBetween(EntrySymbol(), EntryTimeFrame(), entryIndex, 0, true, lowestBody))
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

        // movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // if (EAHelper::CloseIfPercentIntoStopLoss<WickZone>(this, mCurrentSetupTicket, 0.2))
    // {
    //     return;
    // }

    // BE after we validate the MB we entered in
    // if (mMBT.MBsCreated() - 1 != mEntryMB)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<WickZone>(this, mBEAdditionalPips);
    // }

    // if (movedPips || mEntryMB != mMBT.MBsCreated() - 1)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<WickZone>(this, mBEAdditionalPips);
    // }

    // mLastManagedAsk = currentTick.ask;
    // mLastManagedBid = currentTick.bid;

    // EAHelper::CheckPartialTicket<WickZone>(this, mCurrentSetupTicket);
}

bool WickZone::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
    // return EAHelper::TicketStopLossIsMovedToBreakEven<WickZone>(this, ticket);
}

void WickZone::ManagePreviousSetupTicket(Ticket &ticket)
{
    // EAHelper::CheckPartialTicket<WickZone>(this, mPreviousSetupTickets[ticketIndex]);
}

void WickZone::CheckCurrentSetupTicket(Ticket &ticket)
{
}

void WickZone::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void WickZone::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<WickZone>(this, ticket);
}

void WickZone::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    // EARecordHelper::RecordPartialTradeRecord<WickZone>(this, partialedTicket, newTicketNumber);
}

void WickZone::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<WickZone>(this, ticket);
}

void WickZone::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<WickZone>(this, methodName, error, additionalInformation);
}

bool WickZone::ShouldReset()
{
    return false;
}

void WickZone::Reset()
{
}