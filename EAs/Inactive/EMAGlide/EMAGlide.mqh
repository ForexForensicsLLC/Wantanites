//+------------------------------------------------------------------+
//|                                                    EMAGlide.mqh |
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

class EMAGlide : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mEntryMBT;

    int mFirstMBInSetupNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;

    int mSetupBarCount;
    int mEntryBarCount;

    int mSetupTimeFrame;
    string mSetupSymbol;

    int mEntryTimeFrame;
    string mEntrySymbol;

    datetime mFailedImpulseEntryTime;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    EMAGlide(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&entryMBT);
    ~EMAGlide();

    double EMA(int index);
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

double EMAGlide::EMA(int index)
{
    return iMA(mSetupSymbol, mSetupTimeFrame, 9, 0, MODE_EMA, PRICE_CLOSE, index);
}

EMAGlide::EMAGlide(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&entryMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntryMBT = entryMBT;
    mFirstMBInSetupNumber = EMPTY;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<EMAGlide>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<EMAGlide, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<EMAGlide, MultiTimeFrameEntryTradeRecord>(this);

    mSetupBarCount = 0;
    mEntryBarCount = 0;

    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mSetupSymbol = Symbol();
    mSetupTimeFrame = Period();

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

EMAGlide::~EMAGlide()
{
}

double EMAGlide::RiskPercent()
{
    return mRiskPercent;
}

void EMAGlide::Run()
{
    EAHelper::RunDrawMBT<EMAGlide>(this, mEntryMBT);

    mSetupBarCount = iBars(mSetupSymbol, mSetupTimeFrame);
    mEntryBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool EMAGlide::AllowedToTrade()
{
    return EAHelper::BelowSpread<EMAGlide>(this) && EAHelper::WithinTradingSession<EMAGlide>(this);
}

void EMAGlide::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        for (int i = 0; i <= 3; i++)
        {
            if (!EAHelper::CandleIsWithinSession<EMAGlide>(this, mSetupSymbol, mSetupTimeFrame, i))
            {
                return;
            }

            if (iLow(mSetupSymbol, mSetupTimeFrame, i) < EMA(i))
            {
                return;
            }
        }

        if (EAHelper::CheckSetSingleMBSetup<EMAGlide>(this, mEntryMBT, mFirstMBInSetupNumber, mSetupType))
        {
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        for (int i = 0; i <= 3; i++)
        {
            if (!EAHelper::CandleIsWithinSession<EMAGlide>(this, mSetupSymbol, mSetupTimeFrame, i))
            {
                return;
            }

            if (iHigh(mSetupSymbol, mSetupTimeFrame, i) > EMA(i))
            {
                return;
            }
        }

        if (EAHelper::CheckSetSingleMBSetup<EMAGlide>(this, mEntryMBT, mFirstMBInSetupNumber, mSetupType))
        {
            mHasSetup = true;
        }
    }
}

void EMAGlide::CheckInvalidateSetup()
{
    if (iBars(mSetupSymbol, mSetupTimeFrame) > mSetupBarCount)
    {
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mSetupSymbol, mSetupTimeFrame, 0) < EMA(0))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mSetupSymbol, mSetupTimeFrame, 0) > EMA(0))
        {
            InvalidateSetup(true);
            return;
        }
    }

    if (mHasSetup && iBars(mEntrySymbol, mEntryTimeFrame) > mEntryBarCount)
    {
        if (mFirstMBInSetupNumber != mEntryMBT.MBsCreated() - 1)
        {
            InvalidateSetup(true);
        }
    }
}

void EMAGlide::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<EMAGlide>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<EMAGlide>(this, false);
}

bool EMAGlide::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return true;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return false;
    }

    bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<EMAGlide>(this, mEntryMBT, mFirstMBInSetupNumber);
    bool furthestInZone = EAHelper::CandleIsInZone<EMAGlide>(this, mEntryMBT, mFirstMBInSetupNumber, 1, false);

    return dojiInZone && furthestInZone;
}

void EMAGlide::PlaceOrders()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return;
    }

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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<EMAGlide>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mFailedImpulseEntryTime = 0;
    }
}

void EMAGlide::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
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

void EMAGlide::ManageCurrentActiveSetupTicket()
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

    bool movedPips = false;
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    if (mSetupType == OP_BUY)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }

        //     // close if we put in a bearish candle
        //     if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double lowest = 0.0;
        //     if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, lowest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (lowest < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // if (orderPlaceIndex > 1)
        // {
        //     // close if we fail to break with a body
        //     if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex) &&
        //         currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     // close if we put in a bullish candle
        //     if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (orderPlaceIndex > 3)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, orderPlaceIndex))
        //     {
        //         mFailedImpulseEntryTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
        //     }
        // }

        // if (mFailedImpulseEntryTime != 0)
        // {
        //     int failedImpulseEntryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mFailedImpulseEntryTime);
        //     double highest = 0.0;
        //     if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, failedImpulseEntryIndex, 0, true, highest))
        //     {
        //         return;
        //     }

        //     // only close if we crossed our entry price after failing to run and then we go a bit in profit
        //     if (highest > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<EMAGlide>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool EMAGlide::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<EMAGlide>(this, ticket);
}

void EMAGlide::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<EMAGlide>(this, mPreviousSetupTickets[ticketIndex]);
}

void EMAGlide::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EMAGlide>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<EMAGlide>(this);
}

void EMAGlide::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<EMAGlide>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<EMAGlide>(this, ticketIndex);
}

void EMAGlide::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<EMAGlide>(this);
}

void EMAGlide::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<EMAGlide>(this, partialedTicket, newTicketNumber);
}

void EMAGlide::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<EMAGlide>(this, ticket, Period());
}

void EMAGlide::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<EMAGlide>(this, error, additionalInformation);
}

void EMAGlide::Reset()
{
}