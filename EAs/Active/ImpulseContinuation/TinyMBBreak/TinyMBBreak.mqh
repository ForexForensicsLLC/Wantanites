//+------------------------------------------------------------------+
//|                                                    ImpulseContinuation.mqh |
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

class ImpulseContinuation : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mConfirmationMBT;

    int mFirstMBInConfirmationNumber;

    double mMinPercentChange;
    double mMaxMBHeight;
    double mMinMBGap;

    double mMaxEntrySlippagePips;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mSetupCandleTime;
    datetime mEntryCandleTime;
    int mEntryMB;

    int mSetupBarCount;
    int mEntryBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mSetupTimeFrame;
    string mSetupSymbol;

public:
    ImpulseContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                        CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                        CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&confirmationMBT);
    ~ImpulseContinuation();

    double EMA(int index) { return iMA(mSetupSymbol, mSetupTimeFrame, 9, 0, MODE_EMA, PRICE_CLOSE, index); }
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

ImpulseContinuation::ImpulseContinuation(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&confirmationMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mConfirmationMBT = confirmationMBT;

    mFirstMBInConfirmationNumber = EMPTY;

    mMinPercentChange = 0.0;
    mMaxMBHeight = 0.0;
    mMinMBGap = 0.0;

    mMaxEntrySlippagePips = 0.0;
    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<ImpulseContinuation>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<ImpulseContinuation, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<ImpulseContinuation, MultiTimeFrameEntryTradeRecord>(this);

    mSetupBarCount = 0;
    mEntryBarCount = 0;

    mSetupCandleTime = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupSymbol = Symbol();
    mSetupTimeFrame = Period();

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

ImpulseContinuation::~ImpulseContinuation()
{
}

double ImpulseContinuation::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<ImpulseContinuation>(this, 5, 0.5);
}

void ImpulseContinuation::Run()
{
    EAHelper::RunDrawMBT<ImpulseContinuation>(this, mConfirmationMBT);

    mSetupBarCount = iBars(mSetupSymbol, mSetupTimeFrame);
    mEntryBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool ImpulseContinuation::AllowedToTrade()
{
    return EAHelper::BelowSpread<ImpulseContinuation>(this) && EAHelper::WithinTradingSession<ImpulseContinuation>(this);
}

void ImpulseContinuation::CheckSetSetup()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    bool furtherThanEMA = false;
    bool hasPercentChange = false;

    for (int i = 0; i <= 2; i++)
    {
        datetime candleTime = iTime(mSetupSymbol, mSetupTimeFrame, i);
        if (TimeHour(candleTime) <= 14)
        {
            return;
        }

        double percentChange = CandleStickHelper::PercentChange(mSetupSymbol, mSetupTimeFrame, i);
        if (mSetupType == OP_BUY)
        {
            hasPercentChange = percentChange >= mMinPercentChange;
            furtherThanEMA = currentTick.bid >= EMA(0);
        }
        else if (mSetupType == OP_SELL)
        {
            hasPercentChange = percentChange <= -mMinPercentChange;
            furtherThanEMA = currentTick.ask <= EMA(0);
        }

        if (hasPercentChange && furtherThanEMA)
        {
            Print("setup");
            mHasSetup = true;
            mSetupCandleTime = candleTime;

            return;
        }
    }
}

void ImpulseContinuation::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mSetupSymbol, mSetupTimeFrame) > mSetupBarCount)
    {
        if (mSetupCandleTime > 0)
        {
            int setupCandleIndex = iBarShift(mSetupSymbol, mSetupTimeFrame, mSetupCandleTime);
            if (setupCandleIndex > 1 && mHasSetup)
            {
                if (mSetupType == OP_BUY)
                {
                    if (CandleStickHelper::LowestBodyPart(mSetupSymbol, mSetupTimeFrame, 1) < EMA(1))
                    {
                        InvalidateSetup(true);
                        return;
                    }
                }
                else if (mSetupType == OP_SELL)
                {
                    if (CandleStickHelper::HighestBodyPart(mSetupSymbol, mSetupTimeFrame, 1) > EMA(1))
                    {
                        InvalidateSetup(true);
                        return;
                    }
                }
            }
        }
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) > mEntryBarCount)
    {
        if (mFirstMBInConfirmationNumber != EMPTY && mFirstMBInConfirmationNumber != mConfirmationMBT.MBsCreated() - 1)
        {
            InvalidateSetup(true);
        }
    }
}

void ImpulseContinuation::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<ImpulseContinuation>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBConfirmation<ImpulseContinuation>(this, false);

    mSetupCandleTime = 0;
}

bool ImpulseContinuation::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mEntryBarCount)
    {
        return hasTicket;
    }

    if (EAHelper::CheckSetSingleMBSetup<ImpulseContinuation>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mConfirmationMBT.GetMB(mFirstMBInConfirmationNumber, tempMBState))
        {
            return false;
        }

        if (tempMBState.EndIndex() > 1)
        {
            Print("not at end");
            return false;
        }

        if (tempMBState.Height() > OrderHelper::PipsToRange(mMaxMBHeight))
        {
            Print("too tall");
            return false;
        }

        MBState *prevMBState;
        if (!mConfirmationMBT.GetPreviousMB(tempMBState.Number(), prevMBState))
        {
            Print("no prev");
            return false;
        }

        MqlTick currentTick;
        if (!SymbolInfoTick(Symbol(), currentTick))
        {
            RecordError(GetLastError());
            return false;
        }

        if (mSetupType == OP_BUY)
        {
            if (currentTick.ask - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) > OrderHelper::PipsToRange(mMaxEntrySlippagePips))
            {
                Print("too much slipp");
                return false;
            }

            if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, prevMBState.HighIndex()) >= OrderHelper::PipsToRange(mMinMBGap))
            {
                Print("conf");
                return true;
            }
            else
            {
                Print("no gap");
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - currentTick.bid > OrderHelper::PipsToRange(mMaxEntrySlippagePips))
            {
                return false;
            }

            if (iLow(mEntrySymbol, mEntryTimeFrame, prevMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) >= OrderHelper::PipsToRange(mMinMBGap))
            {
                return true;
            }
        }
    }

    return false;
}

void ImpulseContinuation::PlaceOrders()
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

    MBState *tempMBState;
    if (!mConfirmationMBT.GetMB(mFirstMBInConfirmationNumber, tempMBState))
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex());
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) + OrderHelper::PipsToRange(mMaxSpreadPips);
    }

    EAHelper::PlaceMarketOrder<ImpulseContinuation>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInConfirmationNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void ImpulseContinuation::ManageCurrentPendingSetupTicket()
{
}

void ImpulseContinuation::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (EAHelper::CloseIfPercentIntoStopLoss<ImpulseContinuation>(this, mCurrentSetupTicket, 0.5))
    {
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

    if (movedPips || mEntryMB != mConfirmationMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<ImpulseContinuation>(this, mBEAdditionalPips);
    }
}

bool ImpulseContinuation::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<ImpulseContinuation>(this, ticket);
}

void ImpulseContinuation::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<ImpulseContinuation>(this, mPreviousSetupTickets[ticketIndex]);
}

void ImpulseContinuation::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseContinuation>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<ImpulseContinuation>(this);
}

void ImpulseContinuation::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<ImpulseContinuation>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<ImpulseContinuation>(this, ticketIndex);
}

void ImpulseContinuation::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<ImpulseContinuation>(this);
}

void ImpulseContinuation::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<ImpulseContinuation>(this, partialedTicket, newTicketNumber);
}

void ImpulseContinuation::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<ImpulseContinuation>(this, ticket, Period());
}

void ImpulseContinuation::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<ImpulseContinuation>(this, error, additionalInformation);
}

void ImpulseContinuation::Reset()
{
}