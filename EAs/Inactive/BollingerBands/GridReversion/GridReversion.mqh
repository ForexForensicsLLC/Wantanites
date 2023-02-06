//+------------------------------------------------------------------+
//|                                                    PriceGridReversion.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\EA\EA.mqh>
#include <WantaCapital\Framework\Helpers\EAHelper.mqh>
#include <WantaCapital\Framework\Constants\MagicNumbers.mqh>
#include <WantaCapital\Framework\Objects\PriceGridTracker.mqh>

class PriceGridReversion : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    PriceGridTracker *mPGT;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;
    int mLastDay;

    double mStartingEquity;
    int mLastAchievedLevel;
    bool mPlacedFirstTicket;

    double mLotSize;
    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    PriceGridReversion(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt);
    ~PriceGridReversion();

    double UpperBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, shift); }
    double MiddleBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, shift); }
    double LowerBand(int shift) { return iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, shift); }

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

PriceGridReversion::PriceGridReversion(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, PriceGridTracker *&pgt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mPGT = pgt;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mStartingEquity = 0;
    mLastAchievedLevel = 1000;
    mPlacedFirstTicket = false;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<PriceGridReversion>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<PriceGridReversion, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<PriceGridReversion, SingleTimeFrameEntryTradeRecord>(this);
}

PriceGridReversion::~PriceGridReversion()
{
}

void PriceGridReversion::Run()
{
    EAHelper::Run<PriceGridReversion>(this);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool PriceGridReversion::AllowedToTrade()
{
    return EAHelper::BelowSpread<PriceGridReversion>(this) && (EAHelper::WithinTradingSession<PriceGridReversion>(this) || mPreviousSetupTickets.Size() > 0);
}

void PriceGridReversion::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < LowerBand(1))
        {
            mPGT.SetStartingPrice(iClose(mEntrySymbol, mEntryTimeFrame, 1));
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > UpperBand(1))
        {
            mPGT.SetStartingPrice(iClose(mEntrySymbol, mEntryTimeFrame, 1));
            mHasSetup = true;
        }
    }
}

void PriceGridReversion::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // we placed at least one ticket and now all tickets are closed
    if (mPlacedFirstTicket && mPreviousSetupTickets.Size() == 0)
    {
        InvalidateSetup(false);
    }
}

void PriceGridReversion::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<PriceGridReversion>(this, deletePendingOrder, mStopTrading, error);

    mLastAchievedLevel = 1000;
    mStartingEquity = 0;
    mPlacedFirstTicket = false;

    mPGT.Reset();
}

bool PriceGridReversion::Confirmation()
{
    if (mSetupType == OP_BUY)
    {
        if (mPGT.CurrentLevel() <= 0 &&
            mPGT.CurrentLevel() != mLastAchievedLevel)
        {
            mLastAchievedLevel = mPGT.CurrentLevel();
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (mPGT.CurrentLevel() >= 0 &&
            mPGT.CurrentLevel() != mLastAchievedLevel)
        {
            mLastAchievedLevel = mPGT.CurrentLevel();
            return true;
        }
    }

    return false;
}

void PriceGridReversion::PlaceOrders()
{
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
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
    }

    // first ticket is being placed, track the starting equity so we know when to close
    if (mPreviousSetupTickets.Size() == 0)
    {
        mStartingEquity = AccountEquity();
        mPlacedFirstTicket = true;
    }

    EAHelper::PlaceMarketOrder<PriceGridReversion>(this, entry, stopLoss, mLotSize);
}

void PriceGridReversion::ManageCurrentPendingSetupTicket()
{
}

void PriceGridReversion::ManageCurrentActiveSetupTicket()
{
}

bool PriceGridReversion::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return true;
}

void PriceGridReversion::ManagePreviousSetupTicket(int ticketIndex)
{
    // close all tickets if we are down 10% or up 1%
    double equityPercentChange = (AccountEquity() - mStartingEquity) / AccountEquity() * 100;
    if (equityPercentChange <= -10 || equityPercentChange > .5)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        return;
    }
}

void PriceGridReversion::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PriceGridReversion>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<PriceGridReversion>(this);
}

void PriceGridReversion::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PriceGridReversion>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<PriceGridReversion>(this, ticketIndex);
}

void PriceGridReversion::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<PriceGridReversion>(this);
}

void PriceGridReversion::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<PriceGridReversion>(this, partialedTicket, newTicketNumber);
}

void PriceGridReversion::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<PriceGridReversion>(this, ticket, Period());
}

void PriceGridReversion::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<PriceGridReversion>(this, error, additionalInformation);
}

void PriceGridReversion::Reset()
{
}