//+------------------------------------------------------------------+
//|                                                    TheSlinky.mqh |
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

class TheSlinky : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mFirstMBInSetupNumber;

    datetime mEntryCandleTime;

    int mLastDay;
    int mStartingMBNumber;

    bool mOnce;
    int mEntryMB;

public:
    TheSlinky(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheSlinky();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? -1 : -1; }
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
    virtual void RecordTicketPartialData(int oldTicketIndex, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();
};

TheSlinky::TheSlinky(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;
    mFirstMBInSetupNumber = EMPTY;

    mBarCount = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEntryCandleTime = 0;

    mLastDay = 0;
    mStartingMBNumber = EMPTY;
    mOnce = true;
    mEntryMB = EMPTY;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheSlinky>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheSlinky, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheSlinky, SingleTimeFrameEntryTradeRecord>(this);
}

TheSlinky::~TheSlinky()
{
}

double TheSlinky::RiskPercent()
{
    double riskPercent = 0.05; // TODO: Put back to 0.025
    double percentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;

    // for each one percent that we lost, reduce risk by 0.05 %
    while (percentLost >= 1)
    {
        riskPercent -= 0.05;
        percentLost -= 1;
    }

    return riskPercent;
}

void TheSlinky::Run()
{
    EAHelper::RunDrawMBT<TheSlinky>(this, mSetupMBT);
}

bool TheSlinky::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheSlinky>(this) && ((Hour() >= 16 && Hour() <= 18) || (Hour() >= 10 && Hour() <= 12));
}

void TheSlinky::CheckSetSetup()
{
    // new session
    if (Day() > mLastDay)
    {
        if (Hour() >= 16)
        {
            mStartingMBNumber = mSetupMBT.MBsCreated() - 1;
            mOnce = true;
            mLastDay = Day();
        }
    }

    if (EAHelper::CheckSetSingleMBSetup<TheSlinky>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        // if (mFirstMBInSetupNumber != mStartingMBNumber + 1)
        // {
        //     return;
        // }

        // MBState *tempMBState;
        // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        // {
        //     return;
        // }

        // if (tempMBState.EndIndex() == 1)
        // {
        //     mHasSetup = true;
        // }

        // if (mFirstMBInSetupNumber == mStartingMBNumber)
        // {
        //     mHasSetup = true;
        // }
        // else if (mOnce)
        // {
        //     string info = "Most Recent: " + (mSetupMBT.MBsCreated() - 1) + "Starting: " + mStartingMBNumber + " This Setup: " + mFirstMBInSetupNumber;
        //     RecordError(-1, info);

        //     mOnce = false;
        // }

        mHasSetup = true;
    }
}

void TheSlinky::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber == EMPTY)
    {
        return;
    }

    if (!mSetupMBT.MBIsMostRecent(mFirstMBInSetupNumber))
    {
        InvalidateSetup(false);
        return;
    }

    // MBState *tempMBState;
    // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    // {
    //     return;
    // }

    // if (tempMBState.EndIndex() > 1)
    // {
    //     InvalidateSetup(false);
    //     mFirstMBInSetupNumber = EMPTY;
    // }
}

void TheSlinky::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    // RecordError(-2);
    EAHelper::InvalidateSetup<TheSlinky>(this, deletePendingOrder, false, error);

    mStartingMBNumber = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
}

bool TheSlinky::Confirmation()
{
    // double minPercentChange = 0.9;
    // double percentChange = (iClose(mEntrySymbol, mEntryTimeFrame, 1) - iOpen(mEntrySymbol, mEntryTimeFrame, 1)) / iOpen(mEntrySymbol, mEntryTimeFrame, 1) * 100;
    // bool hasMinPercentChange = false;

    // if (mSetupType == OP_BUY)
    // {
    //     hasMinPercentChange = percentChange >= minPercentChange;
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     hasMinPercentChange = percentChange <= (-1 * minPercentChange);
    // }

    // return hasMinPercentChange;

    bool zoneIsHolding = false;
    int zoneIsHolingError = EAHelper::MostRecentMBZoneIsHolding<TheSlinky>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);
    if (zoneIsHolingError != ERR_NO_ERROR)
    {
        InvalidateSetup(true);
        return false;
    }

    if (!zoneIsHolding)
    {
        return false;
    }

    int candles = 4;
    if (mSetupType == OP_BUY)
    {
        for (int i = candles; i >= 1; i--)
        {
            bool abovePrevious = iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1);
            if (!abovePrevious)
            {
                return false;
            }

            bool belowprevious = iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1);
            if (i < candles && belowprevious)
            {
                return false;
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        for (int i = candles; i >= 1; i--)
        {
            bool belowPrevious = iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1);
            if (!belowPrevious)
            {
                return false;
            }

            bool abovePrevious = iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1);
            if (i < candles && abovePrevious)
            {
                return false;
            }
        }
    }

    return true;
}

void TheSlinky::PlaceOrders()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
    {
        return;
    }

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;
    double stopLossPips = 25; // Currencies

    if (mSetupType == OP_BUY)
    {
        entry = Ask;
        stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = Bid;
        stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);
    }

    EAHelper::PlaceMarketOrder<TheSlinky>(this, entry, stopLoss);

    mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    mBarCount = currentBars;
    mEntryMB = mSetupMBT.MBsCreated() - 1;
}

void TheSlinky::ManageCurrentPendingSetupTicket()
{
}

void TheSlinky::ManageCurrentActiveSetupTicket()
{
}

bool TheSlinky::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return EAHelper::TicketStopLossIsMovedToBreakEven<TheSlinky>(this, ticket);
    return true;
}

void TheSlinky::ManagePreviousSetupTicket(int ticketIndex)
{
    // if (mSetupType == OP_BUY)
    // {
    //     if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 1)
    //     {
    //         if (iClose(mEntrySymbol, mEntryTimeFrame, 1) <= iHigh(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime))
    //         {
    //             mPreviousSetupTickets[ticketIndex].Close();
    //             return;
    //         }

    //         if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
    //         {
    //             mPreviousSetupTickets[ticketIndex].Close();
    //             return;
    //         }
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 1)
    //     {
    //         if (iClose(mEntrySymbol, mEntryTimeFrame, 1) >= iLow(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime))
    //         {
    //             mPreviousSetupTickets[ticketIndex].Close();
    //             return;
    //         }

    //         if (iLow(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
    //         {
    //             mPreviousSetupTickets[ticketIndex].Close();
    //             return;
    //         }
    //     }
    // }

    MBState *subsequentMB;
    if (!mSetupMBT.GetSubsequentMB(mEntryMB, subsequentMB))
    {
        return;
    }

    if (subsequentMB.Type() != mSetupType)
    {
        mPreviousSetupTickets[ticketIndex].Close();
        return;
    }

    EAHelper::MoveToBreakEvenAfterNextSameTypeMBValidation<TheSlinky>(this, mPreviousSetupTickets[ticketIndex], mSetupMBT, mEntryMB);
    EAHelper::CheckPartialPreviousSetupTicket<TheSlinky>(this, ticketIndex);
}

void TheSlinky::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheSlinky>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheSlinky>(this);
}

void TheSlinky::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheSlinky>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TheSlinky>(this, ticketIndex);
}

void TheSlinky::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TheSlinky>(this);
}

void TheSlinky::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheSlinky>(this, oldTicketIndex, newTicketNumber);
}

void TheSlinky::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheSlinky>(this, ticket, Period());
}

void TheSlinky::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheSlinky>(this, error, additionalInformation);
}

void TheSlinky::Reset()
{
}
