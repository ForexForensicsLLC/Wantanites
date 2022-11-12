//+------------------------------------------------------------------+
//|                                        MorningMB.mqh |
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

class MorningMB : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    string mEntrySymbol;
    int mEntryTimeFrame;

    MBTracker *mSetupMBT;

    int mBarCount;
    int mFirstMBInSetupNumber;
    datetime mEntryCandleTime;
    int mEntryMB;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    bool mFailToContinue;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MorningMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MorningMB();

    // virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishMorningMB : MagicNumbers::BearishMorningMB; }
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

MorningMB::MorningMB(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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
    mEntryMB = EMPTY;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mFailToContinue = false;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MorningMB>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MorningMB, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MorningMB, MultiTimeFrameEntryTradeRecord>(this);
}

MorningMB::~MorningMB()
{
}

void MorningMB::Run()
{
    EAHelper::RunDrawMBT<MorningMB>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MorningMB::AllowedToTrade()
{
    return EAHelper::BelowSpread<MorningMB>(this) && EAHelper::WithinTradingSession<MorningMB>(this);
}

void MorningMB::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<MorningMB>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void MorningMB::CheckInvalidateSetup()
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

void MorningMB::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MorningMB>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MorningMB>(this, false);
}

bool MorningMB::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    bool inZone = EAHelper::CandleIsInZone<MorningMB>(this, mSetupMBT, mFirstMBInSetupNumber, 2) ||
                  EAHelper::CandleIsInZone<MorningMB>(this, mSetupMBT, mFirstMBInSetupNumber, 3);
    if (!inZone)
    {
        return hasTicket;
    }

    // bool dojiInZone = false;
    // int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<MorningMB>(this, mSetupMBT, mFirstMBInSetupNumber, dojiInZone);
    // if (TerminalErrors::IsTerminalError(error))
    // {
    //     RecordError(error);
    //     return false;
    // }

    // if (!dojiInZone)
    // {
    //     return false;
    // }

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

    if (tempZoneState.Height() >= tempMBState.Height() * 0.95)
    {
        return false;
    }

    // subtract 1 since we already know that there is an imbalance on the first candel
    int startIndex = tempZoneState.StartIndex() - tempZoneState.EntryOffset() - 1;
    for (int i = startIndex; i >= tempMBState.EndIndex() + 1; i--)
    {
        if (!CandleStickHelper::HasImbalance(mSetupType, mEntrySymbol, mEntryTimeFrame, i))
        {
            return false;
        }
    }

    // bool exitWithinPercentOfMB = EAHelper::PriceIsFurtherThanPercentIntoMB<MorningMB>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.ExitPrice(), 0.8);
    // if (!exitWithinPercentOfMB)
    // {
    //     return false;
    // }

    bool entryWithinMB = EAHelper::PriceIsFurtherThanPercentIntoMB<MorningMB>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.EntryPrice(), 0);
    if (!entryWithinMB)
    {
        return false;
    }

    // only take zones that actually caused the impulse break
    // if (tempZoneState.StartIndex() - tempZoneState.EntryOffset() - tempMBState.EndIndex() > 0)
    // {
    //     return false;
    // }

    bool candleBreak = false;
    if (mSetupType == OP_BUY)
    {
        candleBreak = iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2);
    }
    else if (mSetupType == OP_SELL)
    {
        candleBreak = iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2);
    }

    return hasTicket || candleBreak;
}

void MorningMB::PlaceOrders()
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
    // double stopLossRange = OrderHelper::PipsToRange(250);

    if (mSetupType == OP_BUY)
    {
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2), iLow(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
        // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = entry - stopLossRange;
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips), entry + OrderHelper::PipsToRange(mMinStopLossPips));
        // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = entry + stopLossRange;
    }

    EAHelper::PlaceStopOrder<MorningMB>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void MorningMB::ManageCurrentPendingSetupTicket()
{
    mFailToContinue = false;

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

void MorningMB::ManageCurrentActiveSetupTicket()
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

    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        // if (entryIndex > 2)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     // if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.bid >= OrderOpenPrice())
        //     // {
        //     //     mCurrentSetupTicket.Close();
        //     // }

        //     if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex) &&
        //         currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        if (currentBars > mBarCount)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
            {
                mFailToContinue = true;
            }
        }

        if (mFailToContinue && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            mCurrentSetupTicket.Close();
            return;
        }

        // if (!mBrokeEntryIndex)
        // {
        //     for (int i = entryIndex - 1; i >= 0; i--)
        //     {
        //         if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
        //         {
        //             mBrokeEntryIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeEntryIndex && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // get too close to our entry after 5 candles and coming back
        // if (entryIndex >= 10)
        // {
        //     if (mLastManagedBid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips) &&
        //         currentTick.bid <= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        // if (entryIndex > 2)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     // if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.ask <= OrderOpenPrice())
        //     // {
        //     //     mCurrentSetupTicket.Close();
        //     // }

        //     if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) &&
        //         currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        if (currentBars > mBarCount)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
            {
                mFailToContinue = true;
            }
        }

        if (mFailToContinue && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            mCurrentSetupTicket.Close();
            return;
        }
        // if (!mBrokeEntryIndex)
        // {
        //     for (int i = entryIndex - 1; i >= 0; i--)
        //     {
        //         // change to any break lower within our entry
        //         if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
        //         {
        //             mBrokeEntryIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeEntryIndex && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // get too close to our entry after 5 candles and coming back
        // if (entryIndex >= 10)
        // {
        //     if (mLastManagedAsk < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips) &&
        //         currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MorningMB>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool MorningMB::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return mSetupMBT.MBsCreated() - 1 != mEntryMB;
    return EAHelper::TicketStopLossIsMovedToBreakEven<MorningMB>(this, ticket);
}

void MorningMB::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<MorningMB>(this, ticketIndex);
}

void MorningMB::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<MorningMB>(this);
}

void MorningMB::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<MorningMB>(this, ticketIndex);
}

void MorningMB::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MorningMB>(this);
}

void MorningMB::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MorningMB>(this, oldTicketIndex, newTicketNumber);
}

void MorningMB::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MorningMB>(this, ticket, mEntryTimeFrame);
}

void MorningMB::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MorningMB>(this, error, additionalInformation);
}

void MorningMB::Reset()
{
}