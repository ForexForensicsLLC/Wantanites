//+------------------------------------------------------------------+
//|                                        ImpulseBreak.mqh |
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

class ImpulseBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    string mEntrySymbol;
    int mEntryTimeFrame;

    MBTracker *mSetupMBT;

    int mBarCount;
    int mFirstMBInSetupNumber;
    datetime mEntryCandleTime;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    ImpulseBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~ImpulseBreak();

    // virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishImpulseBreak : MagicNumbers::BearishImpulseBreak; }
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

ImpulseBreak::ImpulseBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupMBT = setupMBT;

    mBarCount = 0;
    mFirstMBInSetupNumber = EMPTY;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseBreak, MultiTimeFrameEntryTradeRecord>(this);
}

ImpulseBreak::~ImpulseBreak()
{
}

void ImpulseBreak::Run()
{
    EAHelper::RunDrawMBT<ImpulseBreak>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseBreak>(this) && EAHelper::WithinTradingSession<ImpulseBreak>(this);
}

void ImpulseBreak::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<ImpulseBreak>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        double minPercentChange = 0.3;

        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        // if (!EAHelper::MBWithinWidth<ImpulseBreak>(this, mSetupMBT, mFirstMBInSetupNumber, 7))
        // {
        //     return;
        // }

        // if (!EAHelper::MBWithinHeight<ImpulseBreak>(this, mSetupMBT, mFirstMBInSetupNumber, 300))
        // {
        //     return;
        // }

        double candleBeforeEndPercentChange = CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex() + 1);
        double endPercentChange = CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex());
        double candleAfterEndPercentChange = CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex() - 1);

        if (mSetupType == OP_BUY)
        {
            bool singleCandlePercentChange = endPercentChange >= minPercentChange;
            bool doubleCandlePercentChange = (candleBeforeEndPercentChange >= (minPercentChange / 2) && endPercentChange >= (minPercentChange / 2)) ||
                                             (endPercentChange >= (minPercentChange / 2) && candleAfterEndPercentChange >= (minPercentChange / 2));

            if (singleCandlePercentChange || doubleCandlePercentChange)
            {
                mHasSetup = true;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            double negativePercentChange = minPercentChange * -1;
            bool singleCandlePercentChange = endPercentChange <= negativePercentChange;
            bool doubleCandlePercentChange = (candleBeforeEndPercentChange <= (negativePercentChange / 2) && endPercentChange <= (negativePercentChange / 2)) ||
                                             (endPercentChange <= (negativePercentChange / 2) && candleAfterEndPercentChange <= (negativePercentChange / 2));

            if (singleCandlePercentChange || doubleCandlePercentChange)
            {
                mHasSetup = true;
            }
        }
    }
}

void ImpulseBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        InvalidateSetup(false);
    }
}

void ImpulseBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseBreak>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<ImpulseBreak>(this, false);
}

bool ImpulseBreak::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    bool inZone = EAHelper::CandleIsInZone(this, mSetupMBT, mFirstMBInSetupNumber, 2);
    if (!inZone)
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

    // bool exitWithinPercentOfMB = EAHelper::PriceIsFurtherThanPercentIntoMB<ImpulseBreak>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.ExitPrice(), 0.8);
    // if (!exitWithinPercentOfMB)
    // {
    //     return false;
    // }

    bool entryWithinMB = EAHelper::PriceIsFurtherThanPercentIntoMB<ImpulseBreak>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.ExitPrice(), 0);
    if (!entryWithinMB)
    {
        return false;
    }

    // only take zones that actually caused the impulse break
    if (tempZoneState.StartIndex() - tempZoneState.EntryOffset() - tempMBState.EndIndex() > 0)
    {
        return false;
    }

    bool candleBreak = false;
    if (mSetupType == OP_BUY)
    {
        // don't allow any inner breaks back into the zone
        for (int i = tempMBState.EndIndex() - 1; i >= 0; i--)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i - 1))
            {
                for (int j = i; j >= 0; j--)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, j) > iHigh(mEntrySymbol, mEntryTimeFrame, i))
                    {
                        return false;
                    }
                }
            }
        }

        candleBreak = iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2);
    }
    else if (mSetupType == OP_SELL)
    {
        // don't allow any inner breaks back into the zone
        for (int i = tempMBState.EndIndex() - 1; i >= 0; i--)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i - 1))
            {
                for (int j = i; j >= 0; j--)
                {
                    if (iLow(mEntrySymbol, mEntryTimeFrame, j) < iLow(mEntrySymbol, mEntryTimeFrame, i))
                    {
                        return false;
                    }
                }
            }
        }

        candleBreak = iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2);
    }

    return hasTicket || candleBreak;
}

void ImpulseBreak::PlaceOrders()
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

    EAHelper::PlaceStopOrder<ImpulseBreak>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ImpulseBreak::ManageCurrentPendingSetupTicket()
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

void ImpulseBreak::ManageCurrentActiveSetupTicket()
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
        if (entryIndex > 2)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) && currentTick.bid >= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // if (!mBrokeorderPlaceIndex)
        // {
        //     for (int i = orderPlaceIndex - 1; i >= 0; i--)
        //     {
        //         if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //         {
        //             mBrokeorderPlaceIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeorderPlaceIndex && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 10)
        {
            if (mLastManagedBid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips) &&
                currentTick.bid <= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        if (entryIndex > 2)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) && currentTick.ask <= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // if (!mBrokeorderPlaceIndex)
        // {
        //     for (int i = orderPlaceIndex - 1; i >= 0; i--)
        //     {
        //         // change to any break lower within our entry
        //         if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //         {
        //             mBrokeorderPlaceIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeorderPlaceIndex && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 10)
        {
            if (mLastManagedAsk < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips) &&
                currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseBreak>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool ImpulseBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseBreak>(this, ticket);
}

void ImpulseBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<ImpulseBreak>(this, ticketIndex);
}

void ImpulseBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<ImpulseBreak>(this);
}

void ImpulseBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<ImpulseBreak>(this, ticketIndex);
}

void ImpulseBreak::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseBreak>(this);
}

void ImpulseBreak::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseBreak>(this, oldTicketIndex, newTicketNumber);
}

void ImpulseBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseBreak>(this, ticket, mEntryTimeFrame);
}

void ImpulseBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseBreak>(this, error, additionalInformation);
}

void ImpulseBreak::Reset()
{
}