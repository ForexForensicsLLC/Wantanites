//+------------------------------------------------------------------+
//|                                                    MBRun.mqh |
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

class MBRun : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    double mMaxFirstMBHeightPips;
    double mMaxSecondMBHeightPips;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MBRun(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
          CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
          CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBRun();

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

MBRun::MBRun(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;
    mMaxFirstMBHeightPips = 0.0;
    mMaxSecondMBHeightPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBRun>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBRun, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBRun, SingleTimeFrameEntryTradeRecord>(this);
}

MBRun::~MBRun()
{
}

double MBRun::RiskPercent()
{
    return mRiskPercent;
}

void MBRun::Run()
{
    EAHelper::RunDrawMBT<MBRun>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MBRun::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBRun>(this) && EAHelper::WithinTradingSession<MBRun>(this);
}

void MBRun::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (EAHelper::MBWithinHeight<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, 0, mMaxFirstMBHeightPips) &&
            EAHelper::MBWithinWidth<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, 0, 10))
        {
            int sameTypeMBCount = 0;
            int oppositeTypeMBCount = 0;
            int aboveMaxMBHeightPipsCount = 0;
            int brokenMBCount = 0;

            for (int i = 0; i < 10; i++)
            {
                MBState *tempMBState;
                if (!mSetupMBT.GetNthMostRecentMB(i, tempMBState))
                {
                    return;
                }

                if (tempMBState.Type() == mSetupType)
                {
                    if (tempMBState.GlobalStartIsBroken())
                    {
                        brokenMBCount += 1;
                    }

                    sameTypeMBCount += 1;
                }
                else
                {
                    oppositeTypeMBCount += 1;
                }

                if (brokenMBCount > 1)
                {
                    return;
                }

                if (sameTypeMBCount > 5)
                {
                    break;
                }
            }

            if (sameTypeMBCount <= 5)
            {
                return;
            }

            mHasSetup = true;
        }
    }
}

void MBRun::CheckInvalidateSetup()
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

void MBRun::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBRun>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MBRun>(this, false);
}

bool MBRun::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    bool dojiInZone = false;
    int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, dojiInZone);
    if (TerminalErrors::IsTerminalError(error))
    {
        RecordError(error);
        return false;
    }

    if (!dojiInZone)
    {
        return hasTicket;
    }

    bool dojiIsFurthest = EAHelper::CandleIsInZone<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, 1, true);
    if (!dojiIsFurthest)
    {
        return hasTicket;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    if (tempZoneState.StartIndex() < tempMBState.EndIndex())
    {
        return false;
    }

    bool entryWithinMB = EAHelper::PriceIsFurtherThanPercentIntoMB<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, tempZoneState.EntryPrice(), 0);
    if (!entryWithinMB)
    {
        return false;
    }

    bool candleBreak = false;
    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.HasPendingBullishMB())
        {
            return false;
        }

        int bullishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(bullishRetracementIndex))
        {
            return hasTicket;
        }

        if (tempMBState.EndIndex() - bullishRetracementIndex > 3)
        {
            return hasTicket;
        }

        if (bullishRetracementIndex > 6)
        {
            return hasTicket;
        }

        int lowestIndex = 0.0;
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex() - 1, 0, true, lowestIndex))
        {
            return hasTicket;
        }

        int highestIndex = 0.0;
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex(), 0, true, highestIndex))
        {
            return hasTicket;
        }

        double lowest = iLow(mEntrySymbol, mEntryTimeFrame, lowestIndex);
        double highest = iHigh(mEntrySymbol, mEntryTimeFrame, highestIndex);

        bool withinFiftyPercent = EAHelper::PriceIsFurtherThanPercentIntoMB<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, lowest, 0.5);
        if (!withinFiftyPercent)
        {
            return hasTicket;
        }

        if (highest - lowest > OrderHelper::PipsToRange(mMaxSecondMBHeightPips))
        {
            return hasTicket;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.HasPendingBearishMB())
        {
            return false;
        }

        int bearishRetracementIndex = EMPTY;
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(bearishRetracementIndex))
        {
            return hasTicket;
        }

        if (tempMBState.EndIndex() - bearishRetracementIndex > 3)
        {
            return hasTicket;
        }

        if (bearishRetracementIndex > 6)
        {
            return hasTicket;
        }

        int highestIndex = 0.0;
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex() - 1, 0, true, highestIndex))
        {
            return hasTicket;
        }

        int lowestIndex = 0.0;
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, tempMBState.EndIndex(), 0, true, lowestIndex))
        {
            return hasTicket;
        }

        double lowest = iLow(mEntrySymbol, mEntryTimeFrame, lowestIndex);
        double highest = iHigh(mEntrySymbol, mEntryTimeFrame, highestIndex);

        bool withinFiftyPercent = EAHelper::PriceIsFurtherThanPercentIntoMB<MBRun>(this, mSetupMBT, mFirstMBInSetupNumber, highest, 0.5);
        if (!withinFiftyPercent)
        {
            return hasTicket;
        }

        if (highest - lowest > OrderHelper::PipsToRange(mMaxSecondMBHeightPips))
        {
            return hasTicket;
        }
    }

    return hasTicket || dojiIsFurthest;
}

void MBRun::PlaceOrders()
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
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<MBRun>(this, currentTick.ask, stopLoss);
        }
        else if (entry > currentTick.ask)
        {
            EAHelper::PlaceStopOrder<MBRun>(this, entry, stopLoss);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));

        if (entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(mBEAdditionalPips))
        {
            EAHelper::PlaceMarketOrder<MBRun>(this, currentTick.bid, stopLoss);
        }
        else if (entry < currentTick.bid)
        {
            EAHelper::PlaceStopOrder<MBRun>(this, entry, stopLoss);
        }
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);

        mFailedImpulseEntryTime = 0;
    }
}

void MBRun::ManageCurrentPendingSetupTicket()
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

void MBRun::ManageCurrentActiveSetupTicket()
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

    if (mSetupType == OP_BUY)
    {
        if (orderPlaceIndex > 1)
        {
            // close if we fail to break with a body
            if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
                currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
            }

            // close if we put in a bearish candle
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }
        }

        if (orderPlaceIndex > 3)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }
        }

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
    }
    else if (mSetupType == OP_SELL)
    {
        if (orderPlaceIndex > 1)
        {
            // close if we fail to break with a body
            if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
                currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }

            // close if we put in a bullish candle
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }
        }

        if (orderPlaceIndex > 3)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
            {
                mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            }
        }

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
    }

    // BE after we validate the MB we entered in
    if (mSetupMBT.MBsCreated() - 1 != mEntryMB)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBRun>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool MBRun::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBRun>(this, ticket);
}

void MBRun::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MBRun>(this, mPreviousSetupTickets[ticketIndex]);
}

void MBRun::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBRun>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MBRun>(this);
}

void MBRun::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBRun>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MBRun>(this, ticketIndex);
}

void MBRun::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBRun>(this);
}

void MBRun::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBRun>(this, partialedTicket, newTicketNumber);
}

void MBRun::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBRun>(this, ticket, Period());
}

void MBRun::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBRun>(this, error, additionalInformation);
}

void MBRun::Reset()
{
}