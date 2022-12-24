//+------------------------------------------------------------------+
//|                                                    StartOfDayTimeRangeBreakout.mqh |
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

class StartOfDayTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mBarCount;

    int mCloseHour;
    int mCloseMinute;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;

public:
    StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~StartOfDayTimeRangeBreakout();

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

StartOfDayTimeRangeBreakout::StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;

    mCloseHour;
    mCloseMinute;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mEntryCandleTime = 0;

    mLargestAccountBalance = 200000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayTimeRangeBreakout>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<StartOfDayTimeRangeBreakout, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

double StartOfDayTimeRangeBreakout::RiskPercent()
{
    // reduce risk by half if we lose 5%
    // return EAHelper::GetReducedRiskPerPercentLost<StartOfDayTimeRangeBreakout>(this, 10, 0.25);
    return mRiskPercent;
}

StartOfDayTimeRangeBreakout::~StartOfDayTimeRangeBreakout()
{
}

void StartOfDayTimeRangeBreakout::Run()
{
    EAHelper::RunDrawTimeRange<StartOfDayTimeRangeBreakout>(this, mTRB);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool StartOfDayTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::CheckSetSetup()
{
    if (EAHelper::HasTimeRangeBreakout<StartOfDayTimeRangeBreakout>(this, mTRB))
    {
        mHasSetup = true;
    }
}

void StartOfDayTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void StartOfDayTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<StartOfDayTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);
}

bool StartOfDayTimeRangeBreakout::Confirmation()
{
    return true;
}

void StartOfDayTimeRangeBreakout::PlaceOrders()
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
        stopLoss = mTRB.RangeLow(); /* - (mTRB.RangeWidth() * 0.5);*/ // 150% of the range
        Print("Range Low: ", mTRB.RangeLow(), ", SL: ", stopLoss);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = mTRB.RangeHigh(); /* + (mTRB.RangeWidth() * 0.5); */ // 150% of the range
        Print("Range High: ", mTRB.RangeHigh(), ", SL: ", stopLoss);
    }

    EAHelper::PlaceMarketOrder<StartOfDayTimeRangeBreakout>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mStopTrading = true;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void StartOfDayTimeRangeBreakout::ManageCurrentPendingSetupTicket()
{
}

void StartOfDayTimeRangeBreakout::ManageCurrentActiveSetupTicket()
{
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

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

    // int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips / OrderStopLoss() >= 1)
    {
        EAHelper::MoveTicketToBreakEven<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket, mBEAdditionalPips);
    }

    EAHelper::CloseTicketIfAtTime<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute);
}

bool StartOfDayTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return EAHelper::TicketStopLossIsMovedToBreakEven<StartOfDayTimeRangeBreakout>(this, ticket);
    return false;
}

void StartOfDayTimeRangeBreakout::ManagePreviousSetupTicket(int ticketIndex)
{
    // EAHelper::CheckPartialTicket<StartOfDayTimeRangeBreakout>(this, mPreviousSetupTickets[ticketIndex]);
}

void StartOfDayTimeRangeBreakout::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<StartOfDayTimeRangeBreakout>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<StartOfDayTimeRangeBreakout>(this, ticketIndex);
}

void StartOfDayTimeRangeBreakout::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<StartOfDayTimeRangeBreakout>(this, partialedTicket, newTicketNumber);
}

void StartOfDayTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<StartOfDayTimeRangeBreakout>(this, ticket, Period());
}

void StartOfDayTimeRangeBreakout::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<StartOfDayTimeRangeBreakout>(this, error, additionalInformation);
}

void StartOfDayTimeRangeBreakout::Reset()
{
    mStopTrading = false;
}