//+------------------------------------------------------------------+
//|                                                    NeighborMBs.mqh |
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

class NeighborMBs : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    int mEntryZone;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    NeighborMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~NeighborMBs();

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

NeighborMBs::NeighborMBs(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<NeighborMBs>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<NeighborMBs, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<NeighborMBs, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryZone = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

NeighborMBs::~NeighborMBs()
{
}

double NeighborMBs::RiskPercent()
{
    return mRiskPercent;
}

void NeighborMBs::Run()
{
    EAHelper::RunDrawMBT<NeighborMBs>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool NeighborMBs::AllowedToTrade()
{
    return EAHelper::BelowSpread<NeighborMBs>(this) && EAHelper::WithinTradingSession<NeighborMBs>(this);
}

void NeighborMBs::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<NeighborMBs>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.Height() < OrderHelper::PipsToRange(mMinMBHeight))
        {
            return;
        }

        if (tempMBState.Width() > 80)
        {
            return;
        }

        mHasSetup = true;
    }
}

void NeighborMBs::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        if (mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void NeighborMBs::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<NeighborMBs>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<NeighborMBs>(this, false);
}

bool NeighborMBs::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    int pendingMBStart = EMPTY;
    double furthest = 0.0;
    double pendingMBHeight = 0.0;
    double height = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthest))
        {
            return false;
        }

        height = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - furthest;
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthest))
        {
            return false;
        }

        height = furthest - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
    }

    if (pendingMBStart > 80)
    {
        return false;
    }

    if (height < OrderHelper::PipsToRange(mMinMBHeight))
    {
        return false;
    }

    if (height / tempMBState.Height() > 2 || height / tempMBState.Height() < 0.5)
    {
        return false;
    }

    bool doji = EAHelper::DojiInsideMostRecentMBsHoldingZone<NeighborMBs>(this, mSetupMBT, mFirstMBInSetupNumber);
    return doji;
}

void NeighborMBs::PlaceOrders()
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

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2), iLow(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<NeighborMBs>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryZone = tempZoneState.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
    }
}

void NeighborMBs::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (entryCandleIndex > 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void NeighborMBs::ManageCurrentActiveSetupTicket()
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
        if (orderPlaceIndex > 1)
        {
            // close if we fail to break with a body
            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
            //     currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            // {
            //     mCurrentSetupTicket.Close();
            // }

            if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }

            // close if we put in a bearish candle
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }
        }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        if (mFailedImpulseEntryTime != 0)
        {
            int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
            double lowest = 0.0;
            if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
            {
                return;
            }

            // only close if we crossed our entry price after failing to run and then we go a bit in profit
            if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
            }
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        if (orderPlaceIndex > 1)
        {
            // close if we fail to break with a body
            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
            //     currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            // {
            //     mCurrentSetupTicket.Close();
            //     return;
            // }

            if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }

            // close if we put in a bullish candle
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }
        }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        if (mFailedImpulseEntryTime != 0)
        {
            int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
            double highest = 0.0;
            if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
            {
                return;
            }

            // only close if we crossed our entry price after failing to run and then we go a bit in profit
            if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
            }
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    // BE after we validate the MB we entered in
    // if (mSetupMBT.MBsCreated() - 1 != mEntryMB)
    // {
    //     EAHelper::MoveToBreakEvenAsSoonAsPossible<NeighborMBs>(this, mBEAdditionalPips);
    // }

    if (movedPips || mEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<NeighborMBs>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<NeighborMBs>(this, mCurrentSetupTicket);
}

bool NeighborMBs::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<NeighborMBs>(this, ticket);
}

void NeighborMBs::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<NeighborMBs>(this, mPreviousSetupTickets[ticketIndex]);
}

void NeighborMBs::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<NeighborMBs>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<NeighborMBs>(this);
}

void NeighborMBs::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<NeighborMBs>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<NeighborMBs>(this, ticketIndex);
}

void NeighborMBs::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<NeighborMBs>(this);
}

void NeighborMBs::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<NeighborMBs>(this, partialedTicket, newTicketNumber);
}

void NeighborMBs::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<NeighborMBs>(this, ticket, Period());
}

void NeighborMBs::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<NeighborMBs>(this, error, additionalInformation);
}

void NeighborMBs::Reset()
{
}