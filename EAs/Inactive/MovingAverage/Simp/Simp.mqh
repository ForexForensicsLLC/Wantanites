//+------------------------------------------------------------------+
//|                                                         Simp.mqh |
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

class Simp : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

    bool mCrossedAboveSMA;
    bool mCrossedBelowSMA;

    datetime mCrossedSMATime;

    int mTimeFrame;

public:
    Simp(int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
         CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~Simp();

    virtual int MagicNumber() { return 7; }

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
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

Simp::Simp(int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
           CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupType = OP_SELL;

    mEntryCandleTime = 0;
    mBarCount = 0;

    mCrossedAboveSMA = false;
    mCrossedBelowSMA = false;

    mTimeFrame = 60;

    mCrossedSMATime = EMPTY;

    // EAHelper::FindSetPreviousAndCurrentSetupTickets<Simp>(this);
    // EAHelper::UpdatePreviousSetupTicketsRRAcquried<Simp, PartialTradeRecord>(this);
    // EAHelper::SetPreviousSetupTicketsOpenData<Simp, MultiTimeFrameEntryTradeRecord>(this);
}

Simp::~Simp()
{
}

void Simp::Run()
{
    EAHelper::Run<Simp>(this);
    mBarCount = iBars(Symbol(), Period());
}

bool Simp::AllowedToTrade()
{
    return EAHelper::BelowSpread<Simp>(this);
}

void Simp::CheckSetSetup()
{
    mLastState = 3;
    int currentBars = iBars(Symbol(), Period());
    if (currentBars > mBarCount)
    {
        double entrySma = iMA(Symbol(), Period(), 14, 0, MODE_SMA, PRICE_CLOSE, 1);
        // double biasSma = iMA(Symbol(), Period(), 200, 0, MODE_SMA, PRICE_CLOSE, 1);

        if (mSetupType == OP_BUY)
        {
            if (!mCrossedAboveSMA && /*Close[1] > biasSma  && */ Close[2] < entrySma && Close[1] > entrySma)
            {
                mCrossedSMATime = iTime(Symbol(), Period(), 1);
                mHasSetup = true;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (!mCrossedBelowSMA && /*Close[1] < biasSma && */ Close[2] > entrySma && Close[1] < entrySma)
            {
                mCrossedSMATime = iTime(Symbol(), Period(), 1);
                mHasSetup = true;
            }
        }
    }
}

void Simp::CheckInvalidateSetup()
{
    mLastState = 4;

    int currentBars = iBars(Symbol(), Period());
    if (currentBars > mBarCount)
    {
        double sma = iMA(Symbol(), Period(), 14, 0, MODE_SMA, PRICE_CLOSE, 1);
        if (mSetupType == OP_BUY)
        {
            if (Open[1] < sma || Close[1] < sma)
            {
                InvalidateSetup(true);
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (Open[1] > sma || Close[1] > sma)
            {
                InvalidateSetup(true);
            }
        }
    }
}

void Simp::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    mHasSetup = false;

    mCrossedBelowSMA = false;
    mCrossedAboveSMA = false;

    mCrossedSMATime = 0;

    EAHelper::InvalidateSetup<Simp>(this, deletePendingOrder, false, error);
    mEntryCandleTime = 0;
}

bool Simp::Confirmation()
{
    mLastState = 5;

    int currentBars = iBars(Symbol(), 1);
    if (currentBars > mBarCount)
    {
        double sma = iMA(Symbol(), Period(), 14, 0, MODE_SMA, PRICE_CLOSE, 1);

        bool foundCandleCompletlyPastSMA = false;
        if (mSetupType == OP_BUY)
        {
            // int startIndex = iBarShift(Symbol(), Period(), mCrossedSMATime);
            // for (int i = startIndex; i > 0; i--)
            // {
            //     if (iLow(Symbol(), Period(), i) > sma)
            //     {
            //         foundCandleCompletlyPastSMA = true;
            //     }
            // }

            // if (!foundCandleCompletlyPastSMA)
            // {
            //     return false;
            // }

            return Open[1] > sma && Close[1] > sma && Low[1] < sma;
        }
        else if (mSetupType == OP_SELL)
        {
            // int startIndex = iBarShift(Symbol(), Period(), mCrossedSMATime);
            // for (int i = startIndex; i > 0; i--)
            // {
            //     if (iHigh(Symbol(), Period(), i) < sma)
            //     {
            //         foundCandleCompletlyPastSMA = true;
            //     }
            // }

            // if (!foundCandleCompletlyPastSMA)
            // {
            //     return false;
            // }

            return Open[1] < sma && Close[1] < sma && High[1] > sma;
        }
    }

    return mCurrentSetupTicket.Number() != EMPTY;
}

void Simp::PlaceOrders()
{
    if (mPreviousSetupTickets.Size() > 0)
    {
        mHasSetup = false;

        mCrossedBelowSMA = false;
        mCrossedAboveSMA = false;

        mCrossedSMATime = 0;

        return;
    }

    if (EAHelper::PrePlaceOrderChecks<Simp>(this))
    {
        EAHelper::PlaceStopOrderForCandelBreak<Simp>(this, Symbol(), Period(), 1);

        // does this prevent orders from being ?
        // if so, need to find another way to not place orders if price hasn't re crossed the sma and we already placed an order on it
        mHasSetup = false;

        mCrossedBelowSMA = false;
        mCrossedAboveSMA = false;

        mCrossedSMATime = 0;
    }
}

void Simp::ManageCurrentPendingSetupTicket()
{
    mLastState = 6;
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int error = mCurrentSetupTicket.SelectIfOpen("Managing Order");
    if (error != ERR_NO_ERROR)
    {
        RecordError(-55);
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(Symbol(), Period(), 0) < OrderStopLoss())
        {
            mHasSetup = false;

            mCrossedBelowSMA = false;
            mCrossedAboveSMA = false;

            mCrossedSMATime = 0;

            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(Symbol(), Period(), 0) > OrderStopLoss())
        {
            mHasSetup = false;

            mCrossedBelowSMA = false;
            mCrossedAboveSMA = false;

            mCrossedSMATime = 0;

            mCurrentSetupTicket.Close();
            mCurrentSetupTicket.SetNewTicket(EMPTY);
        }
    }
}

void Simp::ManageCurrentActiveSetupTicket()
{
    // EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry<Simp>(this);
}

bool Simp::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // mLastState = 7;

    if (ticket.Number() == EMPTY)
    {
        return false;
    }

    bool isActive = false;
    int error = ticket.IsActive(isActive);
    if (error == TerminalErrors::ORDER_IS_CLOSED)
    {
        mCurrentSetupTicket.SetNewTicket(EMPTY);

        mHasSetup = false;

        mCrossedSMATime = 0;

        mCrossedBelowSMA = false;
        mCrossedAboveSMA = false;
    }

    return isActive;

    // return EAHelper::TicketStopLossIsMovedToBreakEven<Simp>(this, ticket);
}

void Simp::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<Simp>(this, ticketIndex);
}

void Simp::CheckCurrentSetupTicket()
{
    EAHelper::CheckCurrentSetupTicket<Simp>(this);
}

void Simp::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPreviousSetupTicket<Simp>(this, ticketIndex);
}

void Simp::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<Simp>(this);
}

void Simp::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Simp>(this, oldTicketIndex, newTicketNumber);
}

void Simp::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<Simp>(this, ticket, 60);
}

void Simp::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<Simp>(this, error, additionalInformation);
}

void Simp::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}