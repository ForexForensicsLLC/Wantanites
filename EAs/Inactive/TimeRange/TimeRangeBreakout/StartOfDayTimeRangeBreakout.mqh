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
    int mLastDay;

    int mCloseHour;
    int mCloseMinute;

public:
    StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~StartOfDayTimeRangeBreakout();

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

StartOfDayTimeRangeBreakout::StartOfDayTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mBarCount = 0;
    mLastDay = Day();

    mCloseHour = 0;
    mCloseMinute = 0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<StartOfDayTimeRangeBreakout>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<StartOfDayTimeRangeBreakout, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<StartOfDayTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

StartOfDayTimeRangeBreakout::~StartOfDayTimeRangeBreakout()
{
}

void StartOfDayTimeRangeBreakout::Run()
{
    EAHelper::RunDrawTimeRange<StartOfDayTimeRangeBreakout>(this, mTRB);

    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
    mLastDay = Day();
}

bool StartOfDayTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<StartOfDayTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<StartOfDayTimeRangeBreakout>(this);
}

void StartOfDayTimeRangeBreakout::CheckSetSetup()
{
    if (EAHelper::HasTimeRangeBreakout<StartOfDayTimeRangeBreakout>(this))
    {
        int endBarIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mTRB.RangeEndTime());
        if (endBarIndex < 0)
        {
            return;
        }

        int breakouts = 0;
        if (mSetupType == OP_BUY)
        {
            for (int i = 0; i < endBarIndex; i++)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > mTRB.RangeHigh() && iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) < mTRB.RangeHigh())
                {
                    breakouts += 1;
                }

                if (breakouts > 1)
                {
                    mStopTrading = true;
                    return;
                }
            }
        }
        else if (mSetupType == OP_SELL)
        {
            for (int i = 0; i < endBarIndex; i++)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) < mTRB.RangeLow() && iLow(mEntrySymbol, mEntryTimeFrame, i + 1) > mTRB.RangeLow())
                {
                    breakouts += 1;
                }

                if (breakouts > 1)
                {
                    mStopTrading = true;
                    return;
                }
            }
        }

        mHasSetup = true;
    }
}

void StartOfDayTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mLastDay != Day())
    {
        InvalidateSetup(true);
    }
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
        stopLoss = mTRB.RangeLow();
    }
    else if (mSetupType == OP_SELL)
    {
        entry = currentTick.bid;
        stopLoss = mTRB.RangeHigh();
    }

    EAHelper::PlaceMarketOrder<StartOfDayTimeRangeBreakout>(this, entry, stopLoss);
    mStopTrading = true;
}

void StartOfDayTimeRangeBreakout::ManageCurrentPendingSetupTicket()
{
}

void StartOfDayTimeRangeBreakout::ManageCurrentActiveSetupTicket()
{
    if (EAHelper::CloseTicketIfPastTime<StartOfDayTimeRangeBreakout>(this, mCurrentSetupTicket, mCloseHour, mCloseMinute))
    {
        return;
    }
}

bool StartOfDayTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void StartOfDayTimeRangeBreakout::ManagePreviousSetupTicket(int ticketIndex)
{
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