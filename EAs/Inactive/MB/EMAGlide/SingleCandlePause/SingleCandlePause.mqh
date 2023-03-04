//+------------------------------------------------------------------+
//|                                                    SingleCandlePause.mqh |
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

class SingleCandlePause : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mEntryMBT;

    int mFirstMBInSetupNumber;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mSetupCandleTime;
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
    SingleCandlePause(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                      CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                      CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&entryMBT);
    ~SingleCandlePause();

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

double SingleCandlePause::EMA(int index)
{
    return iMA(mSetupSymbol, mSetupTimeFrame, 9, 0, MODE_EMA, PRICE_CLOSE, index);
}

SingleCandlePause::SingleCandlePause(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<SingleCandlePause>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<SingleCandlePause, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<SingleCandlePause, MultiTimeFrameEntryTradeRecord>(this);

    mSetupBarCount = 0;
    mEntryBarCount = 0;

    mLastEntryMB = EMPTY;
    mSetupCandleTime = 0;
    mEntryCandleTime = 0;

    mFailedImpulseEntryTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

SingleCandlePause::~SingleCandlePause()
{
}

double SingleCandlePause::RiskPercent()
{
    return mRiskPercent;
}

void SingleCandlePause::Run()
{
    EAHelper::RunDrawMBT<SingleCandlePause>(this, mEntryMBT);

    mSetupBarCount = iBars(mSetupSymbol, mSetupTimeFrame);
    mEntryBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool SingleCandlePause::AllowedToTrade()
{
    return EAHelper::BelowSpread<SingleCandlePause>(this) && EAHelper::WithinTradingSession<SingleCandlePause>(this);
}

void SingleCandlePause::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return;
    }

    int firstCandleTypeIndex = EMPTY;
    double minPercentChange = 0.3;
    double percentChange = 0.0;
    double furthestBodyOfCandlePause = 0.0;
    int oppositeCandleCount = 0;

    if (mSetupType == OP_BUY)
    {
        // need to have a bearish candle as our small dip
        if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            return;
        }

        // for (int i = 1; i <= 3; i++)
        // {
        //     if (iLow(mEntrySymbol, mEntryTimeFrame, i) < EMA(i))
        //     {
        //         return;
        //     }
        // }

        furthestBodyOfCandlePause = CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1);
        for (int i = 2; i <= 10; i++)
        {
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i))
            {
                if (firstCandleTypeIndex == EMPTY)
                {
                    firstCandleTypeIndex = i - 1;
                }

                oppositeCandleCount += 1;
            }

            if (i > 2 && CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, i) > furthestBodyOfCandlePause)
            {
                return;
            }

            if (oppositeCandleCount >= 2)
            {
                return;
            }
        }

        if (firstCandleTypeIndex < 2)
        {
            return;
        }

        percentChange = (CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 2) -
                         CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, firstCandleTypeIndex)) /
                        CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 2) * 100;

        if (percentChange < minPercentChange)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // need to have a bullish candle as our small dip
        if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            return;
        }

        // for (int i = 1; i <= 3; i++)
        // {
        //     if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > EMA(i))
        //     {
        //         return;
        //     }
        // }

        furthestBodyOfCandlePause = CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1);
        for (int i = 2; i <= 10; i++)
        {
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i))
            {
                if (firstCandleTypeIndex == EMPTY)
                {
                    firstCandleTypeIndex = i - 1;
                }

                oppositeCandleCount += 1;
            }

            if (i > 2 && CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, i) < furthestBodyOfCandlePause)
            {
                return;
            }

            if (oppositeCandleCount >= 2)
            {
                return;
            }
        }

        if (firstCandleTypeIndex < 2)
        {
            return;
        }

        percentChange = (CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 2) -
                         CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, firstCandleTypeIndex)) /
                        CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 2) * 100;

        if (percentChange > (minPercentChange * -1))
        {
            return;
        }
    }

    mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    mHasSetup = true;
}

void SingleCandlePause::CheckInvalidateSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) > mEntryBarCount)
    {
        if (mSetupCandleTime > 0)
        {
            int setupBarIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mSetupCandleTime);
            if (mSetupCandleTime > 1)
            {
                bool cancelPendingTick = false;
                if (mSetupType == OP_BUY)
                {
                    cancelPendingTick = CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1);
                }
                else if (mSetupType == OP_SELL)
                {
                    cancelPendingTick = CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1);
                }

                InvalidateSetup(cancelPendingTick);
            }
        }
    }
}

void SingleCandlePause::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<SingleCandlePause>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<SingleCandlePause>(this, false);

    mSetupCandleTime = 0;
}

bool SingleCandlePause::Confirmation()
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

    return true;
}

void SingleCandlePause::PlaceOrders()
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

    EAHelper::PlaceStopOrder<SingleCandlePause>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
        mFailedImpulseEntryTime = 0;
    }
}

void SingleCandlePause::ManageCurrentPendingSetupTicket()
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

    if (entryCandleIndex > 1)
    {
        InvalidateSetup(true);
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

void SingleCandlePause::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (EAHelper::CloseIfPercentIntoStopLoss<SingleCandlePause>(this, mCurrentSetupTicket, 0.5))
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
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<SingleCandlePause>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool SingleCandlePause::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<SingleCandlePause>(this, ticket);
}

void SingleCandlePause::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<SingleCandlePause>(this, mPreviousSetupTickets[ticketIndex]);
}

void SingleCandlePause::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<SingleCandlePause>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<SingleCandlePause>(this);
}

void SingleCandlePause::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<SingleCandlePause>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<SingleCandlePause>(this, ticketIndex);
}

void SingleCandlePause::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<SingleCandlePause>(this);
}

void SingleCandlePause::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<SingleCandlePause>(this, partialedTicket, newTicketNumber);
}

void SingleCandlePause::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<SingleCandlePause>(this, ticket, Period());
}

void SingleCandlePause::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<SingleCandlePause>(this, error, additionalInformation);
}

void SingleCandlePause::Reset()
{
}