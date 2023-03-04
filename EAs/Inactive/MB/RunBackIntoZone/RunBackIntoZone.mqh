//+------------------------------------------------------------------+
//|                                                    RunBackIntoZone.mqh |
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

class RunBackIntoZone : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    datetime mBreakCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

    double mLastManagedBid;
    double mLastManagedAsk;

public:
    RunBackIntoZone(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~RunBackIntoZone();

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
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

RunBackIntoZone::RunBackIntoZone(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                 CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mBreakCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedBid = 0.0;
    mLastManagedAsk = 0.0;

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<RunBackIntoZone>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<RunBackIntoZone, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<RunBackIntoZone, SingleTimeFrameEntryTradeRecord>(this);
}

RunBackIntoZone::~RunBackIntoZone()
{
}

void RunBackIntoZone::Run()
{
    EAHelper::RunDrawMBT<RunBackIntoZone>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool RunBackIntoZone::AllowedToTrade()
{
    return EAHelper::BelowSpread<RunBackIntoZone>(this) && EAHelper::WithinTradingSession<RunBackIntoZone>(this);
}

void RunBackIntoZone::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<RunBackIntoZone>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void RunBackIntoZone::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }
}

void RunBackIntoZone::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<RunBackIntoZone>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
}

bool RunBackIntoZone::Confirmation()
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

    int minOppositeCandleCount = 4;
    int pendingMBStart = EMPTY;
    int furthstPoint = EMPTY;
    int oppositeCandleCount = EMPTY;
    int firstSameTypeCandleIndex = EMPTY;
    bool hasRunBackIntoZone = false;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                firstSameTypeCandleIndex = i;
                break;
            }

            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                oppositeCandleCount += 1;
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                firstSameTypeCandleIndex = i;
                break;
            }

            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                oppositeCandleCount += 1;
            }
        }
    }

    if (firstSameTypeCandleIndex > 1 || oppositeCandleCount < minOppositeCandleCount)
    {
        return false;
    }

    bool doji = EAHelper::DojiInsideMostRecentMBsHoldingZone<RunBackIntoZone>(this, mSetupMBT, mFirstMBInSetupNumber, 1);

    return doji;
}

void RunBackIntoZone::PlaceOrders()
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

    MBState *mostRecentMB;
    if (!mSetupMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return;
    }

    ZoneState *holdingZone;
    if (!mostRecentMB.GetClosestValidZone(holdingZone))
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
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<RunBackIntoZone>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void RunBackIntoZone::ManageCurrentPendingSetupTicket()
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
            // Print("Broke Below Invalidatino");
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

void RunBackIntoZone::ManageCurrentActiveSetupTicket()
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
        if (entryIndex > 5)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.bid >= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a low within our stop loss
        // if (entryIndex <= 200)
        // {
        //     // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
        //     for (int i = entryIndex - 2; i >= 0; i--)
        //     {
        //         if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
        //         {
        //             break;
        //         }

        //         for (int j = entryIndex; j > i; j--)
        //         {
        //             if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j))
        //             {
        //                 // managed to break back out, close at BE
        //                 if (currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //                 {
        //                     mCurrentSetupTicket.Close();
        //                     return;
        //                 }

        //                 // pushed too far into SL, take the -0.5
        //                 if (EAHelper::CloseIfPercentIntoStopLoss<RunBackIntoZone>(this, mCurrentSetupTicket, 0.5))
        //                 {
        //                     return;
        //                 }
        //             }
        //         }
        //     }
        // }
        // else
        // {
        //     // TOD: Create error code
        //     string additionalInformation = "Entry Index: " + entryIndex;
        //     RecordError(-1, additionalInformation);
        // }

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 5)
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
        if (entryIndex > 5)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.ask <= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // middle close
        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a high within our stop loss
        // if (entryIndex <= 200)
        // {
        //     // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
        //     for (int i = entryIndex - 2; i >= 0; i--)
        //     {
        //         if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
        //         {
        //             break;
        //         }

        //         for (int j = entryIndex; j > i; j--)
        //         {
        //             if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j))
        //             {
        //                 // managed to break back out, close at BE
        //                 if (currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //                 {
        //                     mCurrentSetupTicket.Close();
        //                     return;
        //                 }

        //                 // pushed too far into SL, take the -0.5
        //                 if (EAHelper::CloseIfPercentIntoStopLoss<RunBackIntoZone>(this, mCurrentSetupTicket, 0.5))
        //                 {
        //                     return;
        //                 }
        //             }
        //         }
        //     }
        // }
        // else
        // {
        //     // TOD: Create error code
        //     string additionalInformation = "Entry Index: " + entryIndex;
        //     RecordError(-1, additionalInformation);
        // }

        // get too close to our entry after 5 candles and coming back
        if (entryIndex >= 5)
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
        EAHelper::MoveToBreakEvenAsSoonAsPossible<RunBackIntoZone>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool RunBackIntoZone::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<RunBackIntoZone>(this, ticket);
}

void RunBackIntoZone::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<RunBackIntoZone>(this, mPreviousSetupTickets[ticketIndex]);
}

void RunBackIntoZone::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<RunBackIntoZone>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<RunBackIntoZone>(this);
}

void RunBackIntoZone::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<RunBackIntoZone>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<RunBackIntoZone>(this, ticketIndex);
}

void RunBackIntoZone::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<RunBackIntoZone>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void RunBackIntoZone::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<RunBackIntoZone>(this, partialedTicket, newTicketNumber);
}

void RunBackIntoZone::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<RunBackIntoZone>(this, ticket, Period());
}

void RunBackIntoZone::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<RunBackIntoZone>(this, error, additionalInformation);
}

void RunBackIntoZone::Reset()
{
}