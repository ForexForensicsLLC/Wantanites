//+------------------------------------------------------------------+
//|                                                    LargeBody.mqh |
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

class LargeBody : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mMinBodyMultiplier;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    int mCloseHour;
    int mCloseMinute;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    LargeBody(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~LargeBody();

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

LargeBody::LargeBody(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMinBodyMultiplier = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mCloseHour = 0;
    mCloseMinute = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LargeBody>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LargeBody, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LargeBody, SingleTimeFrameEntryTradeRecord>(this);
}

LargeBody::~LargeBody()
{
}

void LargeBody::Run()
{
    EAHelper::Run<LargeBody>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool LargeBody::AllowedToTrade()
{
    return EAHelper::BelowSpread<LargeBody>(this) && EAHelper::WithinTradingSession<LargeBody>(this);
}

void LargeBody::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            return;
        }

        // ignore gap downs
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, 1))
        {
            return;
        }

        // ignore gap ups
        if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return;
        }
    }

    double previousBodyLength = CandleStickHelper::BodyLength(mEntrySymbol, mEntryTimeFrame, 1);
    double twoPreviousLength = CandleStickHelper::CandleLength(mEntrySymbol, mEntryTimeFrame, 2);

    if (previousBodyLength / twoPreviousLength < mMinBodyMultiplier)
    {
        return;
    }

    mHasSetup = true;
}

void LargeBody::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void LargeBody::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<LargeBody>(this, deletePendingOrder, mStopTrading, error);
}

bool LargeBody::Confirmation()
{
    return true;
}

void LargeBody::PlaceOrders()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
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
        entry = currentTick.ask;
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
    }

    EAHelper::PlaceMarketOrder<LargeBody>(this, entry, stopLoss);
    InvalidateSetup(false);
}

void LargeBody::ManageCurrentPendingSetupTicket()
{
}

void LargeBody::ManageCurrentActiveSetupTicket()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mCurrentSetupTicket.OpenTime());
    if (openIndex >= 1)
    {
        if ((mSetupType == OP_BUY && currentTick.bid >= mCurrentSetupTicket.OpenPrice()) ||
            (mSetupType == OP_SELL && currentTick.ask <= mCurrentSetupTicket.OpenPrice()))
        {
            mCurrentSetupTicket.Close();
        }
    }

    // EAHelper::MoveToBreakEvenAfterPips<LargeBody>(this, mCurrentSetupTicket, mPipsToWaitBeforeBE, mBEAdditionalPips);
}

bool LargeBody::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LargeBody>(this, ticket);
}

void LargeBody::ManagePreviousSetupTicket(int ticketIndex)
{
    // int openIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mPreviousSetupTickets[ticketIndex].OpenTime());
    // if (openIndex >= 1)
    // {
    //     mPreviousSetupTickets[ticketIndex].Close();
    // }
}

void LargeBody::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LargeBody>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<LargeBody>(this);
}

void LargeBody::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LargeBody>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<LargeBody>(this, ticketIndex);
}

void LargeBody::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LargeBody>(this);
}

void LargeBody::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LargeBody>(this, partialedTicket, newTicketNumber);
}

void LargeBody::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LargeBody>(this, ticket, Period());
}

void LargeBody::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LargeBody>(this, error, additionalInformation);
}

void LargeBody::Reset()
{
}