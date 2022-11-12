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
    double mMaxStopLossPips;
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

    double mMinBreakPips;
    double mMaxPipsFromGreenLips;
    double mMinBlueRedAlligatorGap;
    double mMinRedGreenAlligatorGap;

    double mMinWickLength;

    bool mTradedToday; // TODO: Switch this logic to follow mMaxTradesPerDay instead

public:
    Alligator(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~Alligator();

    int DojiCandleIndex() { return 2; }
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

    double BlueJaw(int index);
    double RedTeeth(int index);
    double GreenLips(int index);
};

double Alligator::BlueJaw(int index = EMPTY)
{
    int indexToUse = index == EMPTY ? DojiCandleIndex() : index;
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, indexToUse);
}
double Alligator::RedTeeth(int index = EMPTY)
{
    int indexToUse = index == EMPTY ? DojiCandleIndex() : index;
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, indexToUse);
}
double Alligator::GreenLips(int index = EMPTY)
{
    int indexToUse = index == EMPTY ? DojiCandleIndex() : index;
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, indexToUse);
}

Alligator::Alligator(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter,
         exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mFixedStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mMaxStopLossPips = 0.0;
    mBEAdditionalPips = 0.0;

    mMinBreakPips = 0.0;
    mMaxPipsFromGreenLips = 0.0;
    mMinBlueRedAlligatorGap = 0.0;
    mMinRedGreenAlligatorGap = 0.0;
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
    double redGreenGap = MathAbs(GreenLips() - RedTeeth());
    if (redGreenGap < mMinRedGreenAlligatorGap)
    {
        return;
    }

    double redBlueGap = MathAbs(RedTeeth() - BlueJaw());
    if (redBlueGap < mMinBlueRedAlligatorGap)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (GreenLips() > RedTeeth() && RedTeeth() > BlueJaw())
        {
            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (GreenLips() < RedTeeth() && RedTeeth() < BlueJaw())
        {
            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
            mHasSetup = true;
        }
    }
}

void Alligator::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    bool potentialDoji = false;
    double redGreenGap = MathAbs(GreenLips() - RedTeeth());
    if (redGreenGap < mMinRedGreenAlligatorGap)
    {
        InvalidateSetup(true);
    }

    double redBlueGap = MathAbs(RedTeeth() - BlueJaw());
    if (redBlueGap < mMinBlueRedAlligatorGap)
    {
        InvalidateSetup(true);
    }

    // if (mSetupCandleTime != 0 && iBarShift(mEntrySymbol, mEntryTimeFrame, mSetupCandleTime) > DojiCandleIndex())
    // {
    //     InvalidateSetup(false);
    // }
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

    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (mSetupType == OP_BUY)
    {
        double openPrice = iOpen(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
        double lowPrice = iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
        double closePrice = iClose(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());

        // if (currentTick.bid - lowPrice < mMinWickLength)
        // {
        //     return mCurrentSetupTicket.Number() != EMPTY;
        // }

        if (MathMin(openPrice, closePrice) - lowPrice < OrderHelper::PipsToRange(mMinWickLength))
        {
            return hasTicket;
        }

        if (openPrice > GreenLips() && lowPrice < GreenLips() && closePrice > GreenLips())
        {
            mEntryPrice = GreenLips();
            if (iClose(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) > iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()) &&
                iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) >= iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()))
            {
                if (iClose(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) - iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()) < OrderHelper::PipsToRange(mMinBreakPips) ||
                    iHigh(mEntrySymbol, mEntryTimeFrame, 1) - GreenLips(1) >= OrderHelper::PipsToRange(mMaxPipsFromGreenLips))
                {
                    return false;
                }

                return true;
            }
            // return true;
        }
        // else if (openPrice > RedTeeth() && lowPrice < RedTeeth() && closePrice > RedTeeth())
        // {
        //     mEntryPrice = RedTeeth();
        //     return true;
        // }
        // else if (openPrice > BlueJaw() && lowPrice < BlueJaw() && closePrice > BlueJaw())
        // {
        //     mEntryPrice = BlueJaw();
        //     return true;
        // }
    }
    else if (mSetupType == OP_SELL)
    {
        double openPrice = iOpen(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
        double highPrice = iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
        double closePrice = iClose(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());

        // if (highPrice - currentTick.bid < mMinWickLength)
        // {
        //     return mCurrentSetupTicket.Number() != EMPTY;
        // }

        if (highPrice - MathMax(openPrice, closePrice) < OrderHelper::PipsToRange(mMinWickLength))
        {
            return hasTicket;
        }

        if (openPrice < GreenLips() && highPrice > GreenLips() && closePrice < GreenLips())
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) < iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()) &&
                iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) <= iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()))
            {
                // mEntryPrice = GreenLips();
                if (iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - iClose(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1)) < OrderHelper::PipsToRange(mMinBreakPips) ||
                    GreenLips(1) - iLow(mEntrySymbol, mEntryTimeFrame, 1) >= OrderHelper::PipsToRange(mMaxPipsFromGreenLips))
                {
                    return false;
                }

                return true;
            }
            // return true;
        }
        // else if (openPrice < RedTeeth() && highPrice > RedTeeth() && closePrice < RedTeeth())
        // {
        //     mEntryPrice = RedTeeth();
        //     return true;
        // }
        // else if (openPrice < BlueJaw() && highPrice > BlueJaw() && closePrice < BlueJaw())
        // {
        //     mEntryPrice = BlueJaw();
        //     return true;
        // }
    }

    return hasTicket;
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

    double entry = 0.0;
    double stopLoss = 0.0;
    if (mSetupType == OP_BUY)
    {
        // mEntryPrice = NormalizeDouble(mEntryPrice, Digits) + OrderHelper::PipsToRange(mAdditionalEntryPips);
        // stopLoss = mEntryPrice - OrderHelper::PipsToRange(mFixedStopLossPips);

        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
        // entry = currentTick.ask;
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
        // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()) - OrderHelper::PipsToRange(mStopLossPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);

        if (entry - stopLoss > OrderHelper::PipsToRange(mMaxStopLossPips))
        {
            return;
        }

        // don't place the order if it is going to activate right away
        if (currentTick.ask > entry)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // mEntryPrice = NormalizeDouble(mEntryPrice, Digits) - OrderHelper::PipsToRange(mAdditionalEntryPips);
        // stopLoss = mEntryPrice + OrderHelper::PipsToRange(mFixedStopLossPips);

        // entry = iLow(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
        // entry = currentTick.bid;
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex()) + OrderHelper::PipsToRange(mStopLossPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex() - 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);

        if (stopLoss - entry > OrderHelper::PipsToRange(mMaxStopLossPips))
        {
            return;
        }

        if (currentTick.bid < entry)
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<Alligator>(this, entry, stopLoss);
    // EAHelper::PlaceMarketOrder<Alligator>(this, entry, stopLoss);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
    }
}

void Alligator::ManageCurrentPendingSetupTicket()
{
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // if (mEntryCandleTime == 0)
    // {
    //     return;
    // }

    // if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 1)
    // {
    //     InvalidateSetup(true);
    // }

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mSetupType == OP_BUY)
    {
        // went lower than the break index
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex - 1))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // went higher than the break index
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex - 1))
        {
            InvalidateSetup(true);
        }
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

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);

    bool movedPips = false;
    if (mSetupType == OP_BUY)
    {
        if (entryIndex > DojiCandleIndex())
        {
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }

            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                movedPips = true;
            }
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        if (entryIndex > DojiCandleIndex())
        {
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                mCurrentSetupTicket.Close();
                return;
            }

            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
            {
                movedPips = true;
            }
        }

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
    // bool isActive = false;
    // int isActiveError = mCurrentSetupTicket.IsActive(isActive);
    // if (TerminalErrors::IsTerminalError(isActiveError))
    // {
    //     RecordError(isActiveError);
    // }

    // if (isActive)
    // {
    //     mTradedToday = true;
    // }

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
    mHasSetup = false;
}
