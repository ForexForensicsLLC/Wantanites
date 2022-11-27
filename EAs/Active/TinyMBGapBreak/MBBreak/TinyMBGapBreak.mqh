//+------------------------------------------------------------------+
//|                                                    TinyMBGapBreak.mqh |
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

class TinyMBGapBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    int mMBsBeforeSession;

    double mMaxMBHeight;
    double mMinMBGap;
    double mMaxEntrySlippage;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

public:
    TinyMBGapBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TinyMBGapBreak();

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

TinyMBGapBreak::TinyMBGapBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;

    mFirstMBInSetupNumber = EMPTY;
    mMBsBeforeSession = EMPTY;

    mMaxMBHeight = 0.0;
    mMinMBGap = 0.0;
    mMaxEntrySlippage = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TinyMBGapBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TinyMBGapBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TinyMBGapBreak, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

TinyMBGapBreak::~TinyMBGapBreak()
{
}

double TinyMBGapBreak::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<TinyMBGapBreak>(this, 5, 0.5);
}

void TinyMBGapBreak::Run()
{
    EAHelper::RunDrawMBT<TinyMBGapBreak>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool TinyMBGapBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<TinyMBGapBreak>(this) && EAHelper::WithinTradingSession<TinyMBGapBreak>(this);
}

void TinyMBGapBreak::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mMBsBeforeSession == EMPTY)
    {
        mMBsBeforeSession = mSetupMBT.MBsCreated();
    }

    if (mSetupMBT.MBsCreated() - mMBsBeforeSession > 5)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<TinyMBGapBreak>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (!mSetupMBT.NthMostRecentMBIsOpposite(0) ||
            mSetupMBT.NumberOfConsecutiveMBsBeforeNthMostRecent(0) < 2)
        {
            return;
        }

        MBState *firstPreviousMBState;
        if (!mSetupMBT.GetPreviousMB(mFirstMBInSetupNumber, firstPreviousMBState))
        {
            return;
        }

        if (firstPreviousMBState.Height() >= OrderHelper::PipsToRange(mMaxMBHeight))
        {
            return;
        }

        MBState *secondPreviousMBState;
        if (!mSetupMBT.GetPreviousMB(firstPreviousMBState.Number(), secondPreviousMBState))
        {
            return;
        }

        if (mSetupType == OP_BUY)
        {
            // the 2 previous mbs should be bearish
            if (iLow(mEntrySymbol, mEntryTimeFrame, secondPreviousMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, firstPreviousMBState.HighIndex()) <
                OrderHelper::PipsToRange(mMinMBGap))
            {
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            // the 2 previous mbs should be bullish
            if (iLow(mEntrySymbol, mEntryTimeFrame, firstPreviousMBState.LowIndex()) - iHigh(mEntrySymbol, mEntryTimeFrame, secondPreviousMBState.HighIndex()) <
                OrderHelper::PipsToRange(mMinMBGap))
            {
                return;
            }
        }

        mHasSetup = true;
    }
}

void TinyMBGapBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        if (mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
        {
            InvalidateSetup(true);
        }
    }
}

void TinyMBGapBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TinyMBGapBreak>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<TinyMBGapBreak>(this, false);
}

bool TinyMBGapBreak::Confirmation()
{
    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    if (tempMBState.EndIndex() > 1)
    {
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
        if (currentTick.ask - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) > OrderHelper::PipsToRange(mMaxEntrySlippage))
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()) - currentTick.bid > OrderHelper::PipsToRange(mMaxEntrySlippage))
        {
            return false;
        }
    }

    return true;
}

void TinyMBGapBreak::PlaceOrders()
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
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = currentTick.ask;
        stopLoss = MathMin(entry - OrderHelper::PipsToRange(mMinStopLossPips), iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()));
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = MathMax(entry + OrderHelper::PipsToRange(mMinStopLossPips), iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()));
    }

    EAHelper::PlaceMarketOrder<TinyMBGapBreak>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void TinyMBGapBreak::ManageCurrentPendingSetupTicket()
{
}

void TinyMBGapBreak::ManageCurrentActiveSetupTicket()
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

    if (EAHelper::CloseIfPercentIntoStopLoss<TinyMBGapBreak>(this, mCurrentSetupTicket, 0.2))
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

    if (movedPips || mEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TinyMBGapBreak>(this, mBEAdditionalPips);
    }
}

bool TinyMBGapBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TinyMBGapBreak>(this, ticket);
}

void TinyMBGapBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<TinyMBGapBreak>(this, mPreviousSetupTickets[ticketIndex]);
}

void TinyMBGapBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TinyMBGapBreak>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TinyMBGapBreak>(this);
}

void TinyMBGapBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TinyMBGapBreak>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TinyMBGapBreak>(this, ticketIndex);
}

void TinyMBGapBreak::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TinyMBGapBreak>(this);
}

void TinyMBGapBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TinyMBGapBreak>(this, partialedTicket, newTicketNumber);
}

void TinyMBGapBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TinyMBGapBreak>(this, ticket, Period());
}

void TinyMBGapBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TinyMBGapBreak>(this, error, additionalInformation);
}

void TinyMBGapBreak::Reset()
{
    mMBsBeforeSession = EMPTY;
}