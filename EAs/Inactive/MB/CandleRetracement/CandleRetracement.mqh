//+------------------------------------------------------------------+
//|                                                    CandleRetracement.mqh |
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

class CandleRetracement : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    datetime mLocalStructureTime;
    datetime mOppositeStructureTime;
    datetime mLastLocalStructeEnteredOnTime;

    double mMaxMBPips;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    CandleRetracement(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                      CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                      CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~CandleRetracement();

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

CandleRetracement::CandleRetracement(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mLocalStructureTime = 0;
    mOppositeStructureTime = 0;
    mLastLocalStructeEnteredOnTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<CandleRetracement>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<CandleRetracement, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<CandleRetracement, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

CandleRetracement::~CandleRetracement()
{
}

double CandleRetracement::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<CandleRetracement>(this, 5, 0.5);
}

void CandleRetracement::Run()
{
    EAHelper::Run<CandleRetracement>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool CandleRetracement::AllowedToTrade()
{
    return EAHelper::BelowSpread<CandleRetracement>(this) && EAHelper::WithinTradingSession<CandleRetracement>(this);
}

void CandleRetracement::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    double minPercentChange = 0.0;

    int localStructureThreshold = 3;
    int globalStructureThreshold = 10;

    int localStructureIndex = EMPTY;
    int globalStructureIndex = EMPTY;
    int opposteStructureIndex = EMPTY;

    double furthestPriceInRetracement = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, localStructureThreshold, 0, true, localStructureIndex))
        {
            return;
        }

        int lastLocalStructeEnteredOnIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLastLocalStructeEnteredOnTime);
        if (localStructureIndex == lastLocalStructeEnteredOnIndex)
        {
            return;
        }

        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, globalStructureThreshold, 0, true, globalStructureIndex))
        {
            return;
        }

        if (localStructureIndex == globalStructureIndex)
        {
            for (int i = localStructureIndex + 1; i <= localStructureIndex + 10; i++)
            {
                if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i) ||
                    CandleStickHelper::IsDownFractal(mEntrySymbol, mEntryTimeFrame, i))
                {
                    opposteStructureIndex = i;
                    break;
                }
            }

            if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, localStructureIndex, 0, true, furthestPriceInRetracement))
            {
                return;
            }

            if (furthestPriceInRetracement < iLow(mEntrySymbol, mEntryTimeFrame, opposteStructureIndex))
            {
                return;
            }

            for (int i = 2; i <= localStructureIndex; i++)
            {
                // look for an impulse in the retracement
                if (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                    CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) <= (minPercentChange * -1) &&
                    CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, i))
                {
                    mHasSetup = true;
                    mLocalStructureTime = iTime(mEntrySymbol, mEntryTimeFrame, localStructureIndex);
                    mOppositeStructureTime = iTime(mEntrySymbol, mEntryTimeFrame, opposteStructureIndex);

                    return;
                }
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, localStructureThreshold, 0, true, localStructureIndex))
        {
            return;
        }

        int lastLocalStructeEnteredOnIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLastLocalStructeEnteredOnTime);
        if (localStructureIndex == lastLocalStructeEnteredOnIndex)
        {
            return;
        }

        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, globalStructureThreshold, 0, true, globalStructureIndex))
        {
            return;
        }

        if (localStructureIndex == globalStructureIndex)
        {
            for (int i = localStructureIndex + 1; i <= localStructureIndex + 10; i++)
            {
                if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i) ||
                    CandleStickHelper::IsUpFractal(mEntrySymbol, mEntryTimeFrame, i))
                {
                    opposteStructureIndex = i;
                    break;
                }
            }

            if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, localStructureIndex, 0, true, furthestPriceInRetracement))
            {
                return;
            }

            if (furthestPriceInRetracement > iHigh(mEntrySymbol, mEntryTimeFrame, opposteStructureIndex))
            {
                return;
            }

            for (int i = 2; i <= localStructureIndex; i++)
            {
                // look for an impulse in the retracement
                if (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) &&
                    CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i) >= minPercentChange &&
                    CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, i))
                {
                    mHasSetup = true;
                    mLocalStructureTime = iTime(mEntrySymbol, mEntryTimeFrame, localStructureIndex);
                    mOppositeStructureTime = iTime(mEntrySymbol, mEntryTimeFrame, opposteStructureIndex);

                    return;
                }
            }
        }
    }
}

void CandleRetracement::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    // {
    //     return;
    // }

    if (mLocalStructureTime > 0)
    {
        int localStructureIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mLocalStructureTime);
        if (localStructureIndex > 3)
        {
            InvalidateSetup(true);
            return;
        }

        if (mSetupType == OP_BUY)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, localStructureIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, localStructureIndex))
            {
                InvalidateSetup(true);
                return;
            }
        }
    }

    if (mOppositeStructureTime > 0)
    {
        int oppositeStructeIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mOppositeStructureTime);
        if (mSetupType == OP_BUY)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, oppositeStructeIndex))
            {
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, oppositeStructeIndex))
            {
                InvalidateSetup(true);
            }
        }
    }
}

void CandleRetracement::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<CandleRetracement>(this, deletePendingOrder, false, error);
    mLocalStructureTime = 0;
    mOppositeStructureTime = 0;
}

bool CandleRetracement::Confirmation()
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

    bool candleInOurFavor = false;
    if (mSetupType == OP_BUY)
    {
        candleInOurFavor = CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        candleInOurFavor = CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1);
    }

    return candleInOurFavor;
}

void CandleRetracement::PlaceOrders()
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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mEntryPaddingPips + mMaxSpreadPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<CandleRetracement>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void CandleRetracement::ManageCurrentPendingSetupTicket()
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

void CandleRetracement::ManageCurrentActiveSetupTicket()
{
    if (mLocalStructureTime > 0 && mLocalStructureTime != mLastLocalStructeEnteredOnTime)
    {
        mLastLocalStructeEnteredOnTime = mLocalStructureTime;
    }

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
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() && iClose(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice())
        {
            movedPips = true;
        }
        else
        {
            movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() && iClose(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice())
        {
            movedPips = true;
        }
        else
        {
            movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
        }
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<CandleRetracement>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool CandleRetracement::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<CandleRetracement>(this, ticket);
}

void CandleRetracement::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<CandleRetracement>(this, mPreviousSetupTickets[ticketIndex]);
}

void CandleRetracement::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleRetracement>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<CandleRetracement>(this);
}

void CandleRetracement::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<CandleRetracement>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<CandleRetracement>(this, ticketIndex);
}

void CandleRetracement::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<CandleRetracement>(this);
}

void CandleRetracement::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<CandleRetracement>(this, partialedTicket, newTicketNumber);
}

void CandleRetracement::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<CandleRetracement>(this, ticket, Period());
}

void CandleRetracement::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<CandleRetracement>(this, error, additionalInformation);
}

void CandleRetracement::Reset()
{
}