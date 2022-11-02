//+------------------------------------------------------------------+
//|                                        LiquidationMB.mqh |
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

class LiquidationMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    string mEntrySymbol;
    int mEntryTimeFrame;

    int mBarCount;

    MBTracker *mSetupMBT;
    LiquidationSetupTracker *mLST;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    datetime mZoneCandleTime;
    datetime mEntryCandleTime;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

public:
    LiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                  CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                  CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, LiquidationSetupTracker *&lst);
    ~LiquidationMB();

    // virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishLiquidationMB : MagicNumbers::BearishLiquidationMB; }
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

LiquidationMB::LiquidationMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, LiquidationSetupTracker *&lst)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mSetupMBT = setupMBT;
    mLST = lst;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mZoneCandleTime = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LiquidationMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LiquidationMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LiquidationMB, MultiTimeFrameEntryTradeRecord>(this);
}

LiquidationMB::~LiquidationMB()
{
}

void LiquidationMB::Run()
{
    EAHelper::RunDrawMBT<LiquidationMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool LiquidationMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<LiquidationMB>(this) && EAHelper::WithinTradingSession<LiquidationMB>(this);
}

void LiquidationMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetLiquidationMBSetup<LiquidationMB>(this, mLST, mFirstMBInSetupNumber, mSecondMBInSetupNumber, mLiquidationMBInSetupNumber))
    {
        bool zoneIsHolding = false;
        int error = EAHelper::LiquidationMBZoneIsHolding<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, zoneIsHolding);
        if (error != ERR_NO_ERROR)
        {
            EAHelper::InvalidateSetup<LiquidationMB>(this, true, false);
            return;
        }

        if (zoneIsHolding)
        {
            MBState *firstMBInSetup;
            if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, firstMBInSetup))
            {
                return;
            }

            if (mSetupType == OP_BUY)
            {
                int lowestIndex = EMPTY;
                if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.EndIndex() - 1, 1, true, lowestIndex))
                {
                    return;
                }

                if (lowestIndex > 3)
                {
                    return;
                }

                if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
                {
                    return;
                }

                mHasSetup = true;
                mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
            }
            else if (mSetupType == OP_SELL)
            {
                int highestIndex = EMPTY;
                if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, firstMBInSetup.EndIndex() - 1, 1, true, highestIndex))
                {
                    return;
                }

                if (highestIndex > 3)
                {
                    return;
                }

                if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
                {
                    return;
                }

                mHasSetup = true;
                mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                Print("Setup: ", mZoneCandleTime);
            }
        }
    }
}

void LiquidationMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        InvalidateSetup(true);
        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<LiquidationMB>(this, mSetupMBT, mLiquidationMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        InvalidateSetup(false);
        return;
    }

    bool zoneIsHolding = false;
    int error = EAHelper::LiquidationMBZoneIsHolding<LiquidationMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSecondMBInSetupNumber, zoneIsHolding);
    if (error != ERR_NO_ERROR || !zoneIsHolding)
    {
        InvalidateSetup(true, error);
        return;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (mSetupType == OP_BUY)
    {
        if (MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, 1), iClose(mEntrySymbol, mEntryTimeFrame, 1)) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, 1), iClose(mEntrySymbol, mEntryTimeFrame, 1)) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void LiquidationMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::ResetLiquidationMBSetup<LiquidationMB>(this, false);
    EAHelper::InvalidateSetup<LiquidationMB>(this, deletePendingOrder, false, error);
}

bool LiquidationMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (zoneCandleIndex < 5)
    {
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        // need a body break above our previous candle while within the candle zone
        if (iLow(mEntrySymbol, mEntryTimeFrame, 2) < iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            Print("Conf: ", mZoneCandleTime);
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // need a body break below our previous candle while within the candle zone
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 2) > iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }

    return hasTicket;
}

void LiquidationMB::PlaceOrders()
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
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2), iLow(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);

        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips), entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<LiquidationMB>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void LiquidationMB::ManageCurrentPendingSetupTicket()
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
}

void LiquidationMB::ManageCurrentActiveSetupTicket()
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

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<LiquidationMB>(this, mBEAdditionalPips);
    }
}

bool LiquidationMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LiquidationMB>(this, ticket);
}

void LiquidationMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<LiquidationMB>(this, ticketIndex);
}

void LiquidationMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<LiquidationMB>(this);
}

void LiquidationMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<LiquidationMB>(this, ticketIndex);
}

void LiquidationMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LiquidationMB>(this);
}

void LiquidationMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LiquidationMB>(this, oldTicketIndex, newTicketNumber);
}

void LiquidationMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LiquidationMB>(this, ticket, mEntryTimeFrame);
}

void LiquidationMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LiquidationMB>(this, error, additionalInformation);
}

void LiquidationMB::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}