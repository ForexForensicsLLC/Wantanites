//+------------------------------------------------------------------+
//|                                                    FractalBreak.mqh |
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

class FractalBreak : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
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
    FractalBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~FractalBreak();

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
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(int error, string additionalInformation);
    virtual void Reset();

    double BlueJaw(int index);
    double RedTeeth(int index);
    double GreenLips(int index);
};

double FractalBreak::BlueJaw(int index = EMPTY)
{
    int indexToUse = index == EMPTY ? 1 : index;
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, indexToUse);
}
double FractalBreak::RedTeeth(int index = EMPTY)
{
    int indexToUse = index == EMPTY ? 1 : index;
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, indexToUse);
}
double FractalBreak::GreenLips(int index = EMPTY)
{
    int indexToUse = index == EMPTY ? 1 : index;
    return iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, indexToUse);
}

FractalBreak::FractalBreak(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
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

    EAHelper::FindSetPreviousAndCurrentSetupTickets<FractalBreak>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<FractalBreak, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<FractalBreak, SingleTimeFrameEntryTradeRecord>(this);
}

FractalBreak::~FractalBreak()
{
}

double FractalBreak::RiskPercent()
{
    return EAHelper::GetReducedRiskPerPercentLost<FractalBreak>(this, 1, 0.05);
}

void FractalBreak::Run()
{
    EAHelper::Run<FractalBreak>(this);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool FractalBreak::AllowedToTrade()
{
    return EAHelper::BelowSpread<FractalBreak>(this) && EAHelper::WithinTradingSession<FractalBreak>(this);
}

void FractalBreak::CheckSetSetup()
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
        if (currentTick.bid < GreenLips())
        {
            return;
        }

        if (GreenLips() > RedTeeth() && RedTeeth() > BlueJaw())
        {
            for (int i = 1; i <= 4; i++)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) < GreenLips(i) ||
                    MathAbs(CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i)) >= 0.06)
                {
                    return;
                }
            }

            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 4);
            mHasSetup = true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (currentTick.ask > GreenLips())
        {
            return;
        }

        if (GreenLips() < RedTeeth() && RedTeeth() < BlueJaw())
        {
            for (int i = 1; i <= 4; i++)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > GreenLips(i) ||
                    MathAbs(CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, i)) >= 0.06)
                {
                    return;
                }
            }

            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 4);
            mHasSetup = true;
        }
    }
}

void FractalBreak::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
    {
        if (mSetupCandleTime > 0)
        {
            int setupCandelIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mSetupCandleTime);
            if (setupCandelIndex > 4)
            {
                InvalidateSetup(true);
            }
        }
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < GreenLips())
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > GreenLips())
        {
            InvalidateSetup(true);
            return;
        }
    }

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
}

void FractalBreak::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<FractalBreak>(this, deletePendingOrder, false, error);

    mEntryPrice = -1.0;
    mSetupCandleTime = 0;
}

bool FractalBreak::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    int lastStructurePoint = EMPTY;
    int furthestPoint = EMPTY;

    if (mSetupType == OP_BUY)
    {
        // find the highest high within 7 candles and use that as a last struture point
        if (!MQLHelper::GetHighestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, 4, 1, true, lastStructurePoint))
        {
            return false;
        }

        // find the highest high within 20 candels
        if (!MQLHelper::GetHighestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, 20, 1, true, furthestPoint))
        {
            return false;
        }

        // if our highest point isn't within 7 candles then we have probably been going sideways for a bit
        if (lastStructurePoint != furthestPoint)
        {
            return hasTicket;
        }

        for (int i = 3; i <= 4; i++)
        {
            double fractal = iFractals(mEntrySymbol, mEntryTimeFrame, MODE_UPPER, i);
            if (fractal > 0.0)
            {
                mEntryPrice = fractal;
                return true;
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // find the lowest low within 7 candles and use that as a last struture point
        if (!MQLHelper::GetLowestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, 4, 1, true, lastStructurePoint))
        {
            return false;
        }

        // find the lowest low within 20 candels
        if (!MQLHelper::GetLowestBodyIndexBetween(mEntrySymbol, mEntryTimeFrame, 20, 1, true, furthestPoint))
        {
            return false;
        }

        // if our lowest point isn't within 7 candles then we have probably been going sideways for a bit
        if (lastStructurePoint != furthestPoint)
        {
            return false;
        }

        for (int i = 3; i <= 4; i++)
        {
            double fractal = iFractals(mEntrySymbol, mEntryTimeFrame, MODE_LOWER, 4);
            if (fractal > 0.0)
            {
                mEntryPrice = fractal;
                return true;
            }
        }
    }

    return false;
}

void FractalBreak::PlaceOrders()
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

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return;
    }

    double stopLoss = 0.0;
    double entry = 0.0;
    if (mSetupType == OP_BUY)
    {
        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, 4, 0, false, stopLoss))
        {
            return;
        }

        entry = mEntryPrice + OrderHelper::PipsToRange(mMaxSpreadPips);

        // if (entry - stopLoss > OrderHelper::PipsToRange(mMaxStopLossPips))
        // {
        //     return;
        // }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, 4, 0, false, stopLoss))
        {
            return;
        }

        stopLoss += OrderHelper::PipsToRange(mMaxSpreadPips);
        // if (stopLoss - entry > OrderHelper::PipsToRange(mMaxStopLossPips))
        // {
        //     return;
        // }
    }

    EAHelper::PlaceStopOrder<FractalBreak>(this, mEntryPrice, stopLoss, 0.0, true, mBEAdditionalPips);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void FractalBreak::ManageCurrentPendingSetupTicket()
{
    if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 1)
    {
        InvalidateSetup(true);
    }

    // int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    // if (mSetupType == OP_BUY)
    // {
    //     // went lower than the break index
    //     if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex - 1))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     // went higher than the break index
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex - 1))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
}

void FractalBreak::ManageCurrentActiveSetupTicket()
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
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips || entryIndex > 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<FractalBreak>(this, mBEAdditionalPips);
    }

    EAHelper::CheckPartialTicket<FractalBreak>(this, mCurrentSetupTicket);
}

bool FractalBreak::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<FractalBreak>(this, ticket);
}

void FractalBreak::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<FractalBreak>(this, mPreviousSetupTickets[ticketIndex]);
}

void FractalBreak::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FractalBreak>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<FractalBreak>(this);
}

void FractalBreak::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FractalBreak>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<FractalBreak>(this, ticketIndex);
}

void FractalBreak::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<FractalBreak>(this);
}

void FractalBreak::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<FractalBreak>(this, partialedTicket, newTicketNumber);
}

void FractalBreak::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<FractalBreak>(this, ticket, Period());
}

void FractalBreak::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<FractalBreak>(this, error, additionalInformation);
}

void FractalBreak::Reset()
{
    mHasSetup = false;
}
