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

    int DojiCandleIndex() { return 1; }
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
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool Alligator::AllowedToTrade()
{
    return EAHelper::BelowSpread<Alligator>(this) && EAHelper::WithinTradingSession<Alligator>(this);
}

void Alligator::CheckSetSetup()
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
            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
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
            mSetupCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, DojiCandleIndex());
            mHasSetup = true;
        }
    }
}

void Alligator::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) > mBarCount)
    {
        if (mSetupType == OP_BUY)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < GreenLips())
            {
                InvalidateSetup(true);
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > GreenLips())
            {
                InvalidateSetup(true);
                return;
            }
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

void Alligator::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<Alligator>(this, deletePendingOrder, false, error);

    mEntryPrice = -1.0;
    mSetupCandleTime = 0;
}

bool Alligator::Confirmation()
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

    if (hasTicket)
    {
        return hasTicket;
    }

    bool hasDojiOnLips = false;
    int lastStructurePoint = EMPTY;
    int furthestPoint = EMPTY;

    if (mSetupType == OP_BUY)
    {
        hasDojiOnLips = iOpen(mEntrySymbol, mEntryTimeFrame, 1) > GreenLips(1) &&
                        iLow(mEntrySymbol, mEntryTimeFrame, 1) < GreenLips(1) &&
                        iClose(mEntrySymbol, mEntryTimeFrame, 1) > GreenLips(1);

        // find the highest high within 7 candles and use that as a last struture point
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, 7, 1, true, lastStructurePoint))
        {
            return false;
        }

        // find the highest high within 20 candels
        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, 20, 1, true, furthestPoint))
        {
            return false;
        }

        // if our highest point isn't within 7 candles then we have probably been going sideways for a bit
        if (lastStructurePoint != furthestPoint)
        {
            return hasTicket;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        hasDojiOnLips = iOpen(mEntrySymbol, mEntryTimeFrame, 1) < GreenLips(1) &&
                        iHigh(mEntrySymbol, mEntryTimeFrame, 1) > GreenLips(1) &&
                        iClose(mEntrySymbol, mEntryTimeFrame, 1) < GreenLips(1);

        // find the lowest low within 7 candles and use that as a last struture point
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, 7, 1, true, lastStructurePoint))
        {
            return false;
        }

        // find the lowest low within 20 candels
        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, 20, 1, true, furthestPoint))
        {
            return false;
        }

        // if our lowest point isn't within 7 candles then we have probably been going sideways for a bit
        if (lastStructurePoint != furthestPoint)
        {
            return hasTicket;
        }
    }

    return hasTicket || hasDojiOnLips;
}

void Alligator::PlaceOrders()
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

    double entry = 0.0;
    double stopLoss = 0.0;
    if (mSetupType == OP_BUY)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mAdditionalEntryPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);

        if (entry - stopLoss > OrderHelper::PipsToRange(mMaxStopLossPips))
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mAdditionalEntryPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);

        if (stopLoss - entry > OrderHelper::PipsToRange(mMaxStopLossPips))
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<Alligator>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void Alligator::ManageCurrentPendingSetupTicket()
{
    if (iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) > 1)
    {
        InvalidateSetup(true);
    }

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
        // if (entryIndex > DojiCandleIndex())
        // {
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         movedPips = true;
        //     }
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // if (entryIndex > DojiCandleIndex())
        // {
        //     if (iOpen(mEntrySymbol, mEntryTimeFrame, 0) > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         mCurrentSetupTicket.Close();
        //         return;
        //     }

        //     if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
        //     {
        //         movedPips = true;
        //     }
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<Alligator>(this, mBEAdditionalPips);
    }

    EAHelper::CheckPartialTicket<Alligator>(this, mCurrentSetupTicket);
}

bool Alligator::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<Alligator>(this, ticket);
}

void Alligator::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<Alligator>(this, mPreviousSetupTickets[ticketIndex]);
}

void Alligator::CheckCurrentSetupTicket()
{
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

void Alligator::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<Alligator>(this, partialedTicket, newTicketNumber);
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
