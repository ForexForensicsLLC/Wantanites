//+------------------------------------------------------------------+
//|                                                    CandleZone.mqh |
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

class CandleZone : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mEntryMBT;

    int mFirstMBInSetupNumber;
    int mFirstMBInEntryNumber;

    datetime mZoneCandleTime;

    double mMaxMBPips;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    CandleZone(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT);
    ~CandleZone();

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

CandleZone::CandleZone(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mEntryMBT = entryMBT;

    mFirstMBInSetupNumber = EMPTY;
    mFirstMBInEntryNumber = EMPTY;

    mZoneCandleTime = 0;
    mMaxMBPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<CandleZone>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<CandleZone, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<CandleZone, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

CandleZone::~CandleZone()
{
}

double CandleZone::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<CandleZone>(this, 5, 0.5);
}

void CandleZone::Run()
{
    EAHelper::RunDrawMBTs<CandleZone>(this, mSetupMBT, mEntryMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool CandleZone::AllowedToTrade()
{
    return EAHelper::BelowSpread<CandleZone>(this) && EAHelper::WithinTradingSession<CandleZone>(this);
}

void CandleZone::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<CandleZone>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (EAHelper::MostRecentMBZoneIsHolding<CandleZone>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            if (EAHelper::CheckSetSingleMBSetup<CandleZone>(this, mEntryMBT, mFirstMBInEntryNumber, mSetupType))
            {
                MBState *entryMB;
                if (!mEntryMBT.GetMB(mFirstMBInEntryNumber, entryMB))
                {
                    return;
                }

                if (entryMB.Height() > OrderHelper::PipsToRange(mMaxMBPips))
                {
                    return;
                }

                int pendingMBStart = EMPTY;
                double pendingMBHeight = 0.0;
                if (EAHelper::MostRecentMBZoneIsHolding<CandleZone>(this, mEntryMBT, mFirstMBInEntryNumber))
                {
                    if (mSetupType == OP_BUY)
                    {
                        if (!mEntryMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
                        {
                            return;
                        }

                        int lowestIndex = EMPTY;
                        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, entryMB.EndIndex() - 1, 1, true, lowestIndex))
                        {
                            return;
                        }

                        // make sure we broke above
                        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
                        {
                            return;
                        }

                        mHasSetup = true;
                        mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                        // mMostRecentMB = mEntryMBT.MBsCreated() - 1;
                    }
                    else if (mSetupType == OP_SELL)
                    {
                        if (!mEntryMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
                        {
                            return;
                        }

                        int highestIndex = EMPTY;
                        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, entryMB.EndIndex() - 1, 1, true, highestIndex))
                        {
                            return;
                        }

                        // make sure we broke below a candle
                        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
                        {
                            return;
                        }

                        mHasSetup = true;
                        mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                        // mMostRecentMB = mEntryMBT.MBsCreated() - 1;
                    }
                }
            }
        }
    }
}

void CandleZone::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        mFirstMBInEntryNumber = EMPTY;
        mFirstMBInSetupNumber = EMPTY;

        return;
    }

    if (mFirstMBInEntryNumber != EMPTY && mFirstMBInEntryNumber != mEntryMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        mFirstMBInEntryNumber = EMPTY;

        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (!EAHelper::MostRecentMBZoneIsHolding<CandleZone>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        InvalidateSetup(true);
        return;
    }

    if (!EAHelper::MostRecentMBZoneIsHolding<CandleZone>(this, mEntryMBT, mFirstMBInEntryNumber))
    {
        InvalidateSetup(true);
        return;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (mSetupType == OP_BUY)
    {
        // invalidate if we broke below our candle zone
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // invalidate if we broke above our candle zone
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void CandleZone::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<CandleZone>(this, deletePendingOrder, false, error);

    mZoneCandleTime = 0;
}

bool CandleZone::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (mSetupType == OP_BUY)
    {
        bool pushedUpAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bearish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1))
            {
                pushedUpAfterInitialBreak = true;
                break;
            }
        }

        if (!pushedUpAfterInitialBreak)
        {
            return false;
        }

        // need a body break above our previous candle while within the candle zone
        if (iLow(mEntrySymbol, mEntryTimeFrame, 2) < iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        bool pushedDownAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bullish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1))
            {
                pushedDownAfterInitialBreak = true;
                break;
            }
        }

        if (!pushedDownAfterInitialBreak)
        {
            return false;
        }
        // need a body break below our previous candle while within the candle zone
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 2) > iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }

    return hasTicket;
}

void CandleZone::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    if (mFirstMBInEntryNumber == mLastEntryMB)
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

    EAHelper::PlaceStopOrder<CandleZone>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void CandleZone::ManageCurrentPendingSetupTicket()
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

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void CandleZone::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mLastEntryMB != mFirstMBInEntryNumber && mFirstMBInEntryNumber != EMPTY)
    {
        mLastEntryMB = mFirstMBInEntryNumber;
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

    if (EAHelper::CloseIfPercentIntoStopLoss<CandleZone>(this, mCurrentSetupTicket, 0.2))
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

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<CandleZone>(this, mBEAdditionalPips);
    }
}

bool CandleZone::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<CandleZone>(this, ticket);
}

void CandleZone::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<CandleZone>(this, mPreviousSetupTickets[ticketIndex]);
}

void CandleZone::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleZone>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<CandleZone>(this);
}

void CandleZone::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleZone>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<CandleZone>(this, ticketIndex);
}

void CandleZone::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<CandleZone>(this, mFirstMBInEntryNumber, mEntryMBT, 0, 0);
}

void CandleZone::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<CandleZone>(this, partialedTicket, newTicketNumber);
}

void CandleZone::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<CandleZone>(this, ticket, Period());
}

void CandleZone::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<CandleZone>(this, error, additionalInformation);
}

void CandleZone::Reset()
{
}