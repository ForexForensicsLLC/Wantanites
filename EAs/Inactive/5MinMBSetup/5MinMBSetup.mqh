//+------------------------------------------------------------------+
//|                                                    FiveMinMBSetup.mqh |
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

class FiveMinMBSetup : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mEntryMBT;

    int mFirstMBInSetupNumber;
    int mFirstMBInEntryNumber;

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
    FiveMinMBSetup(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT);
    ~FiveMinMBSetup();

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

FiveMinMBSetup::FiveMinMBSetup(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mEntryMBT = entryMBT;

    mFirstMBInSetupNumber = EMPTY;
    mFirstMBInEntryNumber = EMPTY;

    mMaxMBPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<FiveMinMBSetup>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<FiveMinMBSetup, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<FiveMinMBSetup, SingleTimeFrameEntryTradeRecord>(this);

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

FiveMinMBSetup::~FiveMinMBSetup()
{
}

double FiveMinMBSetup::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<FiveMinMBSetup>(this, 5, 0.5);
}

void FiveMinMBSetup::Run()
{
    EAHelper::RunDrawMBT<FiveMinMBSetup>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool FiveMinMBSetup::AllowedToTrade()
{
    return EAHelper::BelowSpread<FiveMinMBSetup>(this) && EAHelper::WithinTradingSession<FiveMinMBSetup>(this);
}

void FiveMinMBSetup::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<FiveMinMBSetup>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (EAHelper::MostRecentMBZoneIsHolding<FiveMinMBSetup>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            if (EAHelper::CheckSetSingleMBSetup<FiveMinMBSetup>(this, mEntryMBT, mFirstMBInEntryNumber, mSetupType))
            {
                mHasSetup = true;
            }
        }
    }
}

void FiveMinMBSetup::CheckInvalidateSetup()
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
}

void FiveMinMBSetup::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<FiveMinMBSetup>(this, deletePendingOrder, false, error);
}

bool FiveMinMBSetup::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    bool hasDoji = EAHelper::DojiInsideMostRecentMBsHoldingZone<FiveMinMBSetup>(this, mEntryMBT, mFirstMBInEntryNumber);
    return hasTicket || hasDoji;
}

void FiveMinMBSetup::PlaceOrders()
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
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<FiveMinMBSetup>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void FiveMinMBSetup::ManageCurrentPendingSetupTicket()
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

void FiveMinMBSetup::ManageCurrentActiveSetupTicket()
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
        double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips /*|| mEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<FiveMinMBSetup>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool FiveMinMBSetup::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<FiveMinMBSetup>(this, ticket);
}

void FiveMinMBSetup::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<FiveMinMBSetup>(this, mPreviousSetupTickets[ticketIndex]);
}

void FiveMinMBSetup::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FiveMinMBSetup>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<FiveMinMBSetup>(this);
}

void FiveMinMBSetup::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FiveMinMBSetup>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<FiveMinMBSetup>(this, ticketIndex);
}

void FiveMinMBSetup::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<FiveMinMBSetup>(this, mFirstMBInSetupNumber, mSetupMBT, 0, 0);
}

void FiveMinMBSetup::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<FiveMinMBSetup>(this, partialedTicket, newTicketNumber);
}

void FiveMinMBSetup::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<FiveMinMBSetup>(this, ticket, Period());
}

void FiveMinMBSetup::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<FiveMinMBSetup>(this, error, additionalInformation);
}

void FiveMinMBSetup::Reset()
{
}