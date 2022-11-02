//+------------------------------------------------------------------+
//|                                                    MBEngulfingEntry.mqh |
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

class MBEngulfingEntry : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    double mMinPercentBody;
    double mMinBodyPips;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPip;

    int mSetupMBsCreated;

    datetime mEntryCandleTime;
    datetime mStopLossCandleTime;
    datetime mBreakCandleTime;
    int mBarCount;
    int mManageCurrentSetupBarCount;
    int mConfirmationBarCount;
    int mSetupBarCount;
    int mCheckInvalidateSetupBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mSetupTimeFrame;
    string mSetupSymbol;

    int mLastEntryMB;
    int mLastEntryZone;

    int mMBCount;
    int mLastDay;
    int mEntryMBNumber;

    double mImbalanceCandlePercentChange;

public:
    MBEngulfingEntry(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBEngulfingEntry();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }
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

MBEngulfingEntry::MBEngulfingEntry(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinPercentBody = 0.0;
    mMinBodyPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPip = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBEngulfingEntry>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBEngulfingEntry, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBEngulfingEntry, MultiTimeFrameEntryTradeRecord>(this);

    mSetupMBsCreated = 0;

    mBreakCandleTime = 0;

    mConfirmationBarCount = 0;
    mBarCount = 0;
    mManageCurrentSetupBarCount = 0;
    mCheckInvalidateSetupBarCount = 0;
    mSetupBarCount = 0;
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;

    mLastEntryMB = EMPTY;
    mLastEntryZone = EMPTY;

    mMBCount = 0;
    mLastDay = 0;

    mImbalanceCandlePercentChange = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupSymbol = Symbol();
    mSetupTimeFrame = 15;

    mEntryMBNumber = EMPTY;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

MBEngulfingEntry::~MBEngulfingEntry()
{
}

double MBEngulfingEntry::RiskPercent()
{
    double riskPercent = 0.25;

    double percentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;
    // for each one percent that we lost, reduce risk by 0.05 %
    while (percentLost >= 1)
    {
        riskPercent -= 0.05;
        percentLost -= 1;
    }

    return riskPercent;
}

void MBEngulfingEntry::Run()
{
    EAHelper::RunDrawMBT<MBEngulfingEntry>(this, mSetupMBT);
}

bool MBEngulfingEntry::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBEngulfingEntry>(this) && EAHelper::WithinTradingSession<MBEngulfingEntry>(this);
}

void MBEngulfingEntry::CheckSetSetup()
{
    if (mLastDay != Day())
    {
        mMBCount = 0;
        mLastDay = Day();
    }

    if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    {
        mSetupMBsCreated = mSetupMBT.MBsCreated();
        mMBCount += 1;
    }

    if (EAHelper::CheckSetSingleMBSetup<MBEngulfingEntry>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void MBEngulfingEntry::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            // Print("New MB INvalidation");
            InvalidateSetup(true);
        }
    }
}

void MBEngulfingEntry::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBEngulfingEntry>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
    mStopLossCandleTime = 0;
}

bool MBEngulfingEntry::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    bool isTrue = true;
    int bars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (bars <= mConfirmationBarCount)
    {
        return hasTicket;
    }

    mConfirmationBarCount = bars;

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    // if (mLastEntryMB == tempMBState.Number())
    // {
    //     return false;
    // }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    bool inZone = false;
    bool zoneIsHolding = false;
    int holdingError = EAHelper::MostRecentMBZoneIsHolding<MBEngulfingEntry>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);

    bool engulfing = false;
    int engulfingStartIndex = 2;

    bool engulfingStartIsBullish = CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 2);
    double engulfingStartBodyLength = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, 2);
    double engulfingStartPercentBody = CandleStickHelper::PercentBody(mEntrySymbol, mEntryTimeFrame, 2);

    bool engulfingEndIsBullish = CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1);
    double engulfingEndBodyLength = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, 1);
    double engulfingEndPercentBody = CandleStickHelper::PercentBody(mEntrySymbol, mEntryTimeFrame, 1);

    if (mSetupType == OP_BUY)
    {
        engulfing = !engulfingStartIsBullish &&
                    engulfingStartBodyLength >= OrderHelper::PipsToRange(mMinBodyPips) &&
                    engulfingStartPercentBody >= mMinPercentBody &&
                    engulfingEndBodyLength >= OrderHelper::PipsToRange(mMinBodyPips) &&
                    engulfingEndPercentBody >= mMinPercentBody &&
                    iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2);

        inZone = iLow(mEntrySymbol, mEntryTimeFrame, engulfingStartIndex) <= tempZoneState.EntryPrice() &&
                 MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, engulfingStartIndex), iClose(mEntrySymbol, mEntryTimeFrame, engulfingStartIndex) > tempZoneState.ExitPrice());

        // make sure zone is within mb
        if (tempZoneState.EntryPrice() > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        engulfing = engulfingStartIsBullish &&
                    engulfingStartBodyLength >= OrderHelper::PipsToRange(mMinBodyPips) &&
                    engulfingStartPercentBody >= mMinPercentBody &&
                    engulfingEndBodyLength >= OrderHelper::PipsToRange(mMinBodyPips) &&
                    engulfingEndPercentBody >= mMinPercentBody &&
                    iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2);

        inZone = iHigh(mEntrySymbol, mEntryTimeFrame, engulfingStartIndex) >= tempZoneState.EntryPrice() &&
                 MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, engulfingStartIndex), iClose(mEntrySymbol, mEntryTimeFrame, engulfingStartIndex) <= tempZoneState.ExitPrice());

        // make sure zone is within mb
        if (tempZoneState.EntryPrice() < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        {
            return false;
        }
    }

    bool hasConfirmation = hasTicket || (inZone && engulfing);
    if (hasConfirmation)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }

    return hasConfirmation;
}

void MBEngulfingEntry::PlaceOrders()
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

    EAHelper::PlaceStopOrder<MBEngulfingEntry>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mLastEntryZone = holdingZone.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mBarCount = currentBars;
    }
}

void MBEngulfingEntry::ManageCurrentPendingSetupTicket()
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

void MBEngulfingEntry::ManageCurrentActiveSetupTicket()
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
        // if (entryIndex > 2)
        // {
        //     // close if we are breaking lows and we get the opportunity to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.bid >= OrderOpenPrice())
        //     {
        //         int lowestIndex = EMPTY;
        //         if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 1, true, lowestIndex))
        //         {
        //             return;
        //         }

        //         if (lowestIndex != entryIndex)
        //         {
        //             mCurrentSetupTicket.Close();
        //             return;
        //         }
        //     }
        // }

        // close if we were completely beyond our entry but wicked back in
        // if (iLow(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() &&
        //     iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderOpenPrice() &&
        //     currentTick.bid >= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // if (iLow(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() &&
        //     iClose(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPip))
        // {
        //     movedPips = true;
        // }
        // else
        // {
        // }
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);

        // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPip))
        // {
        //     movedPips = true;
        // }
    }
    else if (mSetupType == OP_SELL)
    {
        // if (entryIndex > 2)
        // {
        //     // close if we are breking highs and we get the opportunity to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.ask <= OrderOpenPrice())
        //     {
        //         int highestIndex = EMPTY;
        //         if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, entryIndex, 1, true, highestIndex))
        //         {
        //             return;
        //         }

        //         if (highestIndex != entryIndex)
        //         {
        //             mCurrentSetupTicket.Close();
        //             return;
        //         }
        //     }
        // }

        // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) &&
        //     iOpen(mEntrySymbol, mEntryTimeFrame, 0) < OrderOpenPrice() - OrderHelper::PipsToRange(beAdditionalPips) &&
        //     currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(beAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() &&
        //     iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
        //     iHigh(mEntrySymbol, mEntryTimeFrame, 0) < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPip))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // close if we were completely beyond our entry but wicked back in
        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() &&
        //     iHigh(mEntrySymbol, mEntryTimeFrame, 0) > OrderOpenPrice() &&
        //     currentTick.bid <= OrderOpenPrice())
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // // BE if candle doesn't get within BEAdditionalPips of entry
        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() &&
        //     iClose(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPip))
        // {
        //     movedPips = true;
        // }
        // // huge candle push down BE
        // else
        // {
        // }
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);

        // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPip))
        // {
        //     movedPips = true;
        // }
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBEngulfingEntry>(this, mBEAdditionalPip);
    }
}

bool MBEngulfingEntry::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBEngulfingEntry>(this, ticket);
}

void MBEngulfingEntry::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<MBEngulfingEntry>(this, ticketIndex);
}

void MBEngulfingEntry::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBEngulfingEntry>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MBEngulfingEntry>(this);
}

void MBEngulfingEntry::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBEngulfingEntry>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MBEngulfingEntry>(this, ticketIndex);
}

void MBEngulfingEntry::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<MBEngulfingEntry>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT, mMBCount, mLastEntryZone);
}

void MBEngulfingEntry::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBEngulfingEntry>(this, oldTicketIndex, newTicketNumber);
}

void MBEngulfingEntry::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBEngulfingEntry>(this, ticket, Period());
}

void MBEngulfingEntry::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBEngulfingEntry>(this, error, additionalInformation);
}

void MBEngulfingEntry::Reset()
{
    mMBCount = 0;
}