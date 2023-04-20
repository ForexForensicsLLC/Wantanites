//+------------------------------------------------------------------+
//|                                        MBEntryDoji.mqh |
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

class MBEntryDoji : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    string mEntrySymbol;
    int mEntryTimeFrame;

    int mBarCount;
    int mLastEntryMB;

    MBTracker *mSetupMBT;

    int mMBsBeforeSession;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

    int mMostRecentMB;
    datetime mZoneCandleTime;
    datetime mEntryCandleTime;

    double mMinInitialBreakTotalPips;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    bool mBrokeEntryIndex;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MBEntryDoji(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBEntryDoji();

    // virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishFirstMB : MagicNumbers::BearishFirstMB; }
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

MBEntryDoji::MBEntryDoji(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastEntryMB = EMPTY;

    mSetupMBT = setupMBT;

    mMBsBeforeSession = EMPTY;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

    mMostRecentMB = EMPTY;
    mZoneCandleTime = 0;
    mEntryCandleTime = 0;

    mMinInitialBreakTotalPips = 0.0;
    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mBrokeEntryIndex = false;

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBEntryDoji>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBEntryDoji, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBEntryDoji, MultiTimeFrameEntryTradeRecord>(this);
}

MBEntryDoji::~MBEntryDoji()
{
}

void MBEntryDoji::Run()
{
    EAHelper::RunDrawMBT<MBEntryDoji>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MBEntryDoji::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBEntryDoji>(this) && EAHelper::WithinTradingSession<MBEntryDoji>(this);
}

void MBEntryDoji::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mMBsBeforeSession == EMPTY)
    {
        mMBsBeforeSession = mSetupMBT.MBsCreated();
    }

    if (EAHelper::CheckSetSingleMBSetup<MBEntryDoji>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        mHasSetup = true;
    }
}

void MBEntryDoji::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mHasSetup && mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
    {
        InvalidateSetup(false);
    }
}

void MBEntryDoji::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<MBEntryDoji>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MBEntryDoji>(this, false);
}

bool MBEntryDoji::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<MBEntryDoji>(this, mSetupMBT, mFirstMBInSetupNumber);
    return hasTicket || dojiInZone;
}

void MBEntryDoji::PlaceOrders()
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
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);

        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips), entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<MBEntryDoji>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void MBEntryDoji::ManageCurrentPendingSetupTicket()
{
    mBrokeEntryIndex = false;

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

void MBEntryDoji::ManageCurrentActiveSetupTicket()
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
        // if (entryIndex > 5)
        // {
        //     // close if we are still opening within our entry and get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.bid >= OrderOpenPrice())
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        // if (!mBrokeEntryIndex)
        // {
        //     for (int i = entryIndex - 1; i >= 0; i--)
        //     {
        //         if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
        //         {
        //             mBrokeEntryIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeEntryIndex && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // get too close to our entry after 5 candles and coming back
        // if (entryIndex >= 10)
        // {
        //     if (mLastManagedBid > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips) &&
        //         currentTick.bid <= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        // if (entryIndex > 5)
        // {
        //     // close if we are still opening above our entry and we get the chance to close at BE
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex) && currentTick.ask <= OrderOpenPrice())
        //     {
        //         mCurrentSetupTicket.Close();
        //     }
        // }

        // if (!mBrokeEntryIndex)
        // {
        //     for (int i = entryIndex - 1; i >= 0; i--)
        //     {
        //         // change to any break lower within our entry
        //         if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
        //         {
        //             mBrokeEntryIndex = true;
        //         }
        //     }
        // }

        // if (mBrokeEntryIndex && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }

        // get too close to our entry after 5 candles and coming back
        // if (entryIndex >= 10)
        // {
        //     if (mLastManagedAsk < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips) &&
        //         currentTick.ask >= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }
        // }

        double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBEntryDoji>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool MBEntryDoji::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBEntryDoji>(this, ticket);
}

void MBEntryDoji::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MBEntryDoji>(this, mPreviousSetupTickets[ticketIndex]);
}

void MBEntryDoji::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<MBEntryDoji>(this);
}

void MBEntryDoji::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<MBEntryDoji>(this, ticketIndex);
}

void MBEntryDoji::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<MBEntryDoji>(this, mFirstMBInSetupNumber, mSetupMBT, mSetupMBT.MBsCreated() - mMBsBeforeSession - 1, 0);
}

void MBEntryDoji::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBEntryDoji>(this, partialedTicket, newTicketNumber);
}

void MBEntryDoji::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBEntryDoji>(this, ticket, mEntryTimeFrame);
}

void MBEntryDoji::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBEntryDoji>(this, error, additionalInformation);
}

void MBEntryDoji::Reset()
{
    mMBsBeforeSession = EMPTY;
}