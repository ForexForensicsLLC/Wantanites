//+------------------------------------------------------------------+
//|                                                    CandleStallBreak.mqh |
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

class CandleStallBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    int mFirstMBInSetupNumber;

    double mMinPendingMBPips;
    double mMaxPipsPastStartOfSetup;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

public:
    CandleStallBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~CandleStallBreak();

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

CandleStallBreak::CandleStallBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinPendingMBPips = 0.0;
    mMaxPipsPastStartOfSetup = 0.0;

    mBarCount = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<CandleStallBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<CandleStallBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<CandleStallBreak, SingleTimeFrameEntryTradeRecord>(this);
}

double CandleStallBreak::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<CandleStallBreak>(this, 5, 0.5);
}

CandleStallBreak::~CandleStallBreak()
{
}

void CandleStallBreak::Run()
{
    EAHelper::RunDrawMBT<CandleStallBreak>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool CandleStallBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<CandleStallBreak>(this) && EAHelper::WithinTradingSession<CandleStallBreak>(this);
}

void CandleStallBreak::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<CandleStallBreak>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (mFirstMBInSetupNumber == mLastEntryMB)
        {
            return;
        }

        mHasSetup = true;
    }
}

void CandleStallBreak::CheckInvalidateSetup()
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

void CandleStallBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<CandleStallBreak>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
}

bool CandleStallBreak::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return hasTicket;
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

    // need to be able to calculate imbalances throughout the mb which I can only do if we've put in a candle after
    if (tempMBState.EndIndex() < 2)
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    int zoneStart = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    // need to have an imbalance form the zone to the end of the mb
    for (int i = zoneStart; i >= tempMBState.EndIndex(); i--)
    {
        if (!CandleStickHelper::HasImbalance(mSetupType, mEntrySymbol, mEntryTimeFrame, i))
        {
            return false;
        }
    }

    double percentBody = 0.5;
    int firstCandleInZone = EMPTY;
    int setupStart = EMPTY;
    int pendingMBStart = EMPTY;
    int furthestIndex = EMPTY;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 1, false, furthestIndex))
        {
            return false;
        }

        // furhtest index needs to be in our setup
        if (furthestIndex > 4)
        {
            return false;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iLow(mEntrySymbol, mEntryTimeFrame, furthestIndex) < OrderHelper::PipsToRange(mMinPendingMBPips))
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, i) < tempZoneState.EntryPrice() &&
                iLow(mEntrySymbol, mEntryTimeFrame, i + 1) > tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }

        if (firstCandleInZone == EMPTY)
        {
            return false;
        }

        if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, firstCandleInZone))
        {
            setupStart = firstCandleInZone;
        }
        else if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, firstCandleInZone + 1))
        {
            setupStart = firstCandleInZone + 1;
        }
        else
        {
            return false;
        }

        if (setupStart != 4 || CandleStickHelper::PercentBody(mEntrySymbol, mEntryTimeFrame, setupStart) < percentBody)
        {
            return false;
        }

        if (iLow(mEntrySymbol, mEntryTimeFrame, setupStart) - iLow(mEntrySymbol, mEntryTimeFrame, furthestIndex) > OrderHelper::PipsToRange(mMaxPipsPastStartOfSetup))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return false;
        }

        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, pendingMBStart, 1, false, furthestIndex))
        {
            return false;
        }

        // furhtest index needs to be in our setup
        if (furthestIndex > 4)
        {
            return false;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, furthestIndex) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) < OrderHelper::PipsToRange(mMinPendingMBPips))
        {
            return false;
        }

        for (int i = pendingMBStart - 1; i >= 1; i--)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > tempZoneState.EntryPrice() &&
                iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) < tempZoneState.EntryPrice())
            {
                firstCandleInZone = i;
                break;
            }
        }

        if (firstCandleInZone == EMPTY)
        {
            return false;
        }

        if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, firstCandleInZone))
        {
            setupStart = firstCandleInZone;
        }
        else if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, firstCandleInZone + 1))
        {
            setupStart = firstCandleInZone + 1;
        }
        else
        {
            return false;
        }

        if (setupStart != 4 || CandleStickHelper::PercentBody(mEntrySymbol, mEntryTimeFrame, setupStart) < percentBody)
        {
            return false;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, furthestIndex) - iHigh(mEntrySymbol, mEntryTimeFrame, setupStart) > OrderHelper::PipsToRange(mMaxPipsPastStartOfSetup))
        {
            return false;
        }
    }

    return CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, setupStart - 1) < iHigh(mEntrySymbol, mEntryTimeFrame, setupStart) &&
           CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, setupStart - 1) > iLow(mEntrySymbol, mEntryTimeFrame, setupStart) &&
           CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, setupStart - 2) < iHigh(mEntrySymbol, mEntryTimeFrame, setupStart - 1) &&
           CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, setupStart - 2) > iLow(mEntrySymbol, mEntryTimeFrame, setupStart - 1) &&
           CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, setupStart - 3) < iHigh(mEntrySymbol, mEntryTimeFrame, setupStart - 1) &&
           CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, setupStart - 3) > iLow(mEntrySymbol, mEntryTimeFrame, setupStart - 1);
}

void CandleStallBreak::PlaceOrders()
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
        double highest = 0.0;
        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, 3, 0, true, highest))
        {
            return;
        }

        double lowest = -1.0;
        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, 4, 0, true, lowest))
        {
            return;
        }

        entry = highest + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = 0.0;
        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, 4, 0, true, highest))
        {
            return;
        }

        double lowest = -1.0;
        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, 3, 0, true, lowest))
        {
            return;
        }

        entry = lowest - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips) + OrderHelper::PipsToRange(mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<CandleStallBreak>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void CandleStallBreak::ManageCurrentPendingSetupTicket()
{
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

    if (entryCandleIndex > 1)
    {
        InvalidateSetup(true);
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
}

void CandleStallBreak::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mLastEntryMB != mFirstMBInSetupNumber && mFirstMBInSetupNumber != EMPTY)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
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

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        if (entryIndex > 5)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a low within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        if (entryIndex > 5)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // middle close
        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a high within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<CandleStallBreak>(this, mBEAdditionalPips);
    }
}

bool CandleStallBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<CandleStallBreak>(this, ticket);
}

void CandleStallBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<CandleStallBreak>(this, mPreviousSetupTickets[ticketIndex]);
}

void CandleStallBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleStallBreak>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<CandleStallBreak>(this);
}

void CandleStallBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleStallBreak>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<CandleStallBreak>(this, ticketIndex);
}

void CandleStallBreak::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<CandleStallBreak>(this);
}

void CandleStallBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<CandleStallBreak>(this, partialedTicket, newTicketNumber);
}

void CandleStallBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<CandleStallBreak>(this, ticket, Period());
}

void CandleStallBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<CandleStallBreak>(this, error, additionalInformation);
}

void CandleStallBreak::Reset()
{
}