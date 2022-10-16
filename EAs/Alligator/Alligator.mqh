//+------------------------------------------------------------------+
//|                                                    Alligator.mqh |
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

class Alligator : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    double mAdditionalEntryPips;
    double mFixedStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    int mBarCount;
    int mLastDay;
    int mLastYear;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mFirstMBInSetupNumber;

    double mEntryPrice;
    datetime mSetupCandleTime;
    datetime mEntryCandleTime;

    double mMinAlligatorGap;
    double mMinWickLength;

    bool mTradedToday; // TODO: Switch this logic to follow mMaxTradesPerDay instead

public:
    Alligator(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~Alligator();

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

    double BlueJaw() { return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, 0); }
    double RedTeeth() { return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, 0); }
    double GreenLips() { return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, 0); }
};

Alligator::Alligator(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mSetupType = setupType;
    mFirstMBInSetupNumber = EMPTY;

    mFixedStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mMinAlligatorGap = 0.0;
    mMinWickLength = 0.0;

    mTradedToday = false;

    mBarCount = 0;
    mLastDay = 0;
    mLastYear = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEntryPrice = 0.0;
    mSetupCandleTime = 0;
    mEntryCandleTime = 0;

    // TODO: Change Back
    mLargestAccountBalance = 100000;

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<Alligator>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<Alligator, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<Alligator, SingleTimeFrameEntryTradeRecord>(this);
}

Alligator::~Alligator()
{
}

double Alligator::RiskPercent()
{
    return EAHelper::GetReducedRiskPerPercentLost<Alligator>(this, 1, 0.05);
}

void Alligator::Run()
{
    EAHelper::RunDrawMBT<Alligator>(this, mSetupMBT);
}

bool Alligator::AllowedToTrade()
{
    return EAHelper::BelowSpread<Alligator>(this) && EAHelper::WithinTradingSession<Alligator>(this);
}

void Alligator::CheckSetSetup()
{
    // TODO: Find a way to put this in Reset()
    if (Year() > mLastYear || DayOfYear() > mLastDay)
    {
        mTradedToday = false;
        mLastDay = DayOfYear();
        mLastYear = Year();
    }

    bool potentialDoji = false;
    if (MathAbs(GreenLips() - RedTeeth()) < mMinAlligatorGap || MathAbs(RedTeeth() - BlueJaw()) < mMinAlligatorGap)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (GreenLips() > RedTeeth() && RedTeeth() > BlueJaw())
        {
            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (GreenLips() < RedTeeth() && RedTeeth() < BlueJaw())
        {
            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
            mHasSetup = true;
        }
    }
}

void Alligator::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mSetupCandleTime != 0 && iBarShift(mEntrySymbol, mEntryTimeFrame, mSetupCandleTime) > 0)
    {
        InvalidateSetup(false);
    }
}

void Alligator::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<Alligator>(this, deletePendingOrder, false, error);

    mEntryPrice = -1.0;
    mSetupCandleTime = 0;
}

bool Alligator::Confirmation()
{
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        double openPrice = iOpen(mEntrySymbol, mEntryTimeFrame, 0);
        double lowPrice = iLow(mEntrySymbol, mEntryTimeFrame, 0);

        if (currentTick.bid - lowPrice < mMinWickLength)
        {
            return mCurrentSetupTicket.Number() != EMPTY;
        }

        if (openPrice > GreenLips() && lowPrice < GreenLips())
        {
            mEntryPrice = GreenLips();
            return true;
        }
        else if (openPrice > RedTeeth() && lowPrice < RedTeeth())
        {
            mEntryPrice = RedTeeth();
            return true;
        }
        else if (openPrice > BlueJaw() && lowPrice < BlueJaw())
        {
            mEntryPrice = BlueJaw();
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        double openPrice = iOpen(mEntrySymbol, mEntryTimeFrame, 0);
        double highPrice = iHigh(mEntrySymbol, mEntryTimeFrame, 0);

        if (highPrice - currentTick.bid < mMinWickLength)
        {
            return mCurrentSetupTicket.Number() != EMPTY;
        }

        if (openPrice < GreenLips() && highPrice > GreenLips())
        {
            mEntryPrice = GreenLips();
            return true;
        }
        else if (openPrice < RedTeeth() && highPrice > RedTeeth())
        {
            mEntryPrice = RedTeeth();
            return true;
        }
        else if (openPrice < BlueJaw() && highPrice > BlueJaw())
        {
            mEntryPrice = BlueJaw();
            return true;
        }
    }

    return mCurrentSetupTicket.Number() != EMPTY;
}

void Alligator::PlaceOrders()
{
    // if (mTradedToday)
    // {
    //     return;
    // }

    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mBarCount)
    {
        return;
    }

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

    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        mEntryPrice = NormalizeDouble(mEntryPrice, Digits) + OrderHelper::PipsToRange(mAdditionalEntryPips);
        stopLoss = mEntryPrice - OrderHelper::PipsToRange(mFixedStopLossPips);

        // don't place the order if it is going to activate right away
        if (currentTick.ask > mEntryPrice)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        mEntryPrice = NormalizeDouble(mEntryPrice, Digits) - OrderHelper::PipsToRange(mAdditionalEntryPips);
        stopLoss = mEntryPrice + OrderHelper::PipsToRange(mFixedStopLossPips);
        if (currentTick.bid < mEntryPrice)
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<Alligator>(this, mEntryPrice, stopLoss);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }
}

void Alligator::ManageCurrentPendingSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mEntryCandleTime == 0)
    {
        return;
    }

    if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 0)
    {
        InvalidateSetup(true);
    }
}

void Alligator::ManageCurrentActiveSetupTicket()
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
    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<Alligator>(this, mBEAdditionalPips);
    }
}

bool Alligator::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<Alligator>(this, ticket);
}

void Alligator::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<Alligator>(this, ticketIndex);
}

void Alligator::CheckCurrentSetupTicket()
{
    bool isActive = false;
    int isActiveError = mCurrentSetupTicket.IsActive(isActive);
    if (TerminalErrors::IsTerminalError(isActiveError))
    {
        RecordError(isActiveError);
    }

    if (isActive)
    {
        mTradedToday = true;
    }

    EAHelper::CheckUpdateHowFarPriceRanFromOpen<Alligator>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<Alligator>(this);
}

void Alligator::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<Alligator>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<Alligator>(this, ticketIndex);
}

void Alligator::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<Alligator>(this);
}

void Alligator::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Alligator>(this, oldTicketIndex, newTicketNumber);
}

void Alligator::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<Alligator>(this, ticket, Period());
}

void Alligator::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<Alligator>(this, error, additionalInformation);
}

void Alligator::Reset()
{
}
