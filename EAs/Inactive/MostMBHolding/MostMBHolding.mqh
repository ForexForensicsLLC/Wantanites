//+------------------------------------------------------------------+
//|                                                    MostMBHolding.mqh |
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

class MostMBHolding : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    int mLastEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;
    bool mClosedOutsideEntry;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MostMBHolding(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                  CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                  CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MostMBHolding();

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

MostMBHolding::MostMBHolding(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                             CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MostMBHolding>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MostMBHolding, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MostMBHolding, MultiTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
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

MostMBHolding::~MostMBHolding()
{
}

double MostMBHolding::RiskPercent()
{
    return mRiskPercent;
}

void MostMBHolding::Run()
{
    EAHelper::RunDrawMBT<MostMBHolding>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MostMBHolding::AllowedToTrade()
{
    return EAHelper::BelowSpread<MostMBHolding>(this) && EAHelper::WithinTradingSession<MostMBHolding>(this);
}

void MostMBHolding::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<MostMBHolding>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (tempMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight) || tempMBState.Height() < OrderHelper::PipsToRange(mMinMBHeight))
        {
            return;
        }

        // if (EAHelper::MBWasCreatedAfterSessionStart<MostMBHolding>(this, mSetupMBT, mFirstMBInSetupNumber))
        // {
        // }
        mHasSetup = true;
    }
}

void MostMBHolding::CheckInvalidateSetup()
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
        }
    }
}

void MostMBHolding::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MostMBHolding>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MostMBHolding>(this, false);
}

bool MostMBHolding::Confirmation()
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

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    bool percentIntoMB = EAHelper::PriceIsFurtherThanPercentIntoMB<MostMBHolding>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.ExitPrice(), 0.5);
    if (!percentIntoMB)
    {
        return false;
    }

    return true;
}

void MostMBHolding::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    if (mFirstMBInSetupNumber == mLastEntryMB)
    {
        return;
    }

    int pendingMBStart = EMPTY;
    double entry = 0.0;
    double stopLoss = 0.0;
    double furthestPoint = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
        {
            return;
        }

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - ((iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - furthestPoint) * 0.5);
        stopLoss = furthestPoint - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
        {
            return;
        }

        entry = iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) + ((furthestPoint - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart)) * 0.5);
        stopLoss = furthestPoint + OrderHelper::PipsToRange(mStopLossPaddingPips);
    }

    EAHelper::PlaceStopOrder<MostMBHolding>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
        mClosedOutsideEntry = false;
    }
}

void MostMBHolding::ManageCurrentPendingSetupTicket()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
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

    int pendingMBStart = EMPTY;
    double entry = 0.0;
    double stopLoss = 0.0;
    double furthestPoint = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
        {
            return;
        }

        entry = NormalizeDouble(iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - ((iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - furthestPoint) * 0.5), Digits);
        stopLoss = NormalizeDouble(furthestPoint - OrderHelper::PipsToRange(mStopLossPaddingPips), Digits);
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 0, false, furthestPoint))
        {
            return;
        }

        entry = NormalizeDouble(iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) + ((furthestPoint - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart)) * 0.5), Digits);
        stopLoss = NormalizeDouble(furthestPoint + OrderHelper::PipsToRange(mStopLossPaddingPips), Digits);
    }

    if (OrderOpenPrice() != entry || OrderStopLoss() != stopLoss)
    {
        mCurrentSetupTicket.Close();
        mCurrentSetupTicket.SetNewTicket(EMPTY);

        EAHelper::PlaceStopOrder<MostMBHolding>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);
        if (mCurrentSetupTicket.Number() != EMPTY)
        {
            mLastEntryMB = mFirstMBInSetupNumber;
            mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

            mFailedImpulseEntryTime = 0;
            mClosedOutsideEntry = false;
        }
    }
}

void MostMBHolding::ManageCurrentActiveSetupTicket()
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

    if (EAHelper::CloseIfPercentIntoStopLoss<MostMBHolding>(this, mCurrentSetupTicket, 0.2))
    {
        return;
    }

    bool movedPips = false;
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips || mLastEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MostMBHolding>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;

    EAHelper::CheckPartialTicket<MostMBHolding>(this, mCurrentSetupTicket);
}

bool MostMBHolding::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MostMBHolding>(this, ticket);
}

void MostMBHolding::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MostMBHolding>(this, mPreviousSetupTickets[ticketIndex]);
}

void MostMBHolding::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MostMBHolding>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MostMBHolding>(this);
}

void MostMBHolding::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MostMBHolding>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MostMBHolding>(this, ticketIndex);
}

void MostMBHolding::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<MostMBHolding>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void MostMBHolding::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MostMBHolding>(this, partialedTicket, newTicketNumber);
}

void MostMBHolding::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MostMBHolding>(this, ticket, Period());
}

void MostMBHolding::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MostMBHolding>(this, error, additionalInformation);
}

void MostMBHolding::Reset()
{
}