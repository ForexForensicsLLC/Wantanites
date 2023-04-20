//+------------------------------------------------------------------+
//|                                                    WickFractal.mqh |
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

class WickFractal : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mEntryMBT;

    int mFirstMBInSetupNumber;
    int mFirstMBInEntryNumber;

    double mMaxMBPips;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;
    int mBarCount;

    string mSetupSymbol;
    int mSetupTimeFrame;

    string mEntrySymbol;
    int mEntryTimeFrame;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    WickFractal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT);
    ~WickFractal();

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

WickFractal::WickFractal(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                         CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                         CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mEntryMBT = entryMBT;

    mFirstMBInSetupNumber = EMPTY;
    mFirstMBInEntryNumber = EMPTY;

    mMaxMBPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<WickFractal>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<WickFractal, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<WickFractal, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mSetupSymbol = Symbol();
    mSetupTimeFrame = Period();

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

WickFractal::~WickFractal()
{
}

double WickFractal::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<WickFractal>(this, 5, 0.5);
}

void WickFractal::Run()
{
    EAHelper::RunDrawMBTs<WickFractal>(this, mSetupMBT, mEntryMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool WickFractal::AllowedToTrade()
{
    return EAHelper::BelowSpread<WickFractal>(this) && EAHelper::WithinTradingSession<WickFractal>(this);
}

void WickFractal::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<WickFractal>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        MBState *tempMBState;
        if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        {
            return;
        }

        if (EAHelper::CandleIsWithinSession<WickFractal>(this, mSetupSymbol, mSetupTimeFrame, tempMBState.StartIndex()))
        {
            if (EAHelper::MostRecentMBZoneIsHolding<WickFractal>(this, mSetupMBT, mFirstMBInSetupNumber))
            {
                if (EAHelper::CheckSetSingleMBSetup<WickFractal>(this, mEntryMBT, mFirstMBInEntryNumber))
                {
                    mHasSetup = true;
                }
            }
        }
    }
}

void WickFractal::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (mFirstMBInEntryNumber != EMPTY && mFirstMBInEntryNumber != mEntryMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (!EAHelper::MostRecentMBZoneIsHolding<WickFractal>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        InvalidateSetup(true);
        return;
    }
}

void WickFractal::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<WickFractal>(this, deletePendingOrder, false, error);

    mFirstMBInEntryNumber = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
}

bool WickFractal::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (hasTicket)
    {
        return hasTicket;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mEntryMBT.GetMB(mFirstMBInEntryNumber, tempMBState))
    {
        return false;
    }

    int startIndex = EMPTY;
    double currentFractalPoint = 0.0;
    double furthestFractalPoint = -1.0;
    bool wickedFractal = false;

    if (mSetupType == OP_BUY)
    {
        if (tempMBState.Type() == OP_BUY)
        {
            if (!mEntryMBT.CurrentBullishRetracementIndexIsValid(startIndex))
            {
                return false;
            }
        }
        else if (tempMBState.Type() == OP_SELL)
        {
            startIndex = tempMBState.HighIndex();
        }

        for (int i = 3; i <= startIndex; i++)
        {
            currentFractalPoint = iFractals(mEntrySymbol, mEntryTimeFrame, MODE_LOWER, i);
            if (currentFractalPoint == 0.0)
            {
                continue;
            }

            if (furthestFractalPoint == -1.0 || currentFractalPoint < furthestFractalPoint)
            {
                furthestFractalPoint = currentFractalPoint;
            }
        }

        wickedFractal = iLow(mEntrySymbol, mEntryTimeFrame, 1) < furthestFractalPoint &&
                        CandleStickHelper::LowestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) > furthestFractalPoint;
    }
    else if (mSetupType == OP_SELL)
    {
        if (tempMBState.Type() == OP_BUY)
        {
            startIndex = tempMBState.LowIndex();
        }
        else if (tempMBState.Type() == OP_SELL)
        {
            if (!mEntryMBT.CurrentBearishRetracementIndexIsValid(startIndex))
            {
                return false;
            }
        }

        for (int i = 3; i <= startIndex; i++)
        {
            currentFractalPoint = iFractals(mEntrySymbol, mEntryTimeFrame, MODE_UPPER, i);
            if (currentFractalPoint == 0.0)
            {
                continue;
            }

            if (furthestFractalPoint == -1.0 || currentFractalPoint > furthestFractalPoint)
            {
                furthestFractalPoint = currentFractalPoint;
            }
        }

        wickedFractal = iHigh(mEntrySymbol, mEntryTimeFrame, 1) > furthestFractalPoint &&
                        CandleStickHelper::HighestBodyPart(mEntrySymbol, mEntryTimeFrame, 1) < furthestFractalPoint;
    }

    return hasTicket || wickedFractal;
}

void WickFractal::PlaceOrders()
{
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    if (mFirstMBInEntryNumber == mLastEntryMB)
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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips),
                           entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<WickFractal>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void WickFractal::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void WickFractal::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mLastEntryMB != mFirstMBInEntryNumber && mFirstMBInEntryNumber != EMPTY)
    {
        mLastEntryMB = mFirstMBInEntryNumber;
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
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (/*movedPips || */ mLastEntryMB != mEntryMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<WickFractal>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool WickFractal::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<WickFractal>(this, ticket);
}

void WickFractal::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<WickFractal>(this, mPreviousSetupTickets[ticketIndex]);
}

void WickFractal::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickFractal>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<WickFractal>(this);
}

void WickFractal::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<WickFractal>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<WickFractal>(this, ticketIndex);
}

void WickFractal::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<WickFractal>(this, mFirstMBInEntryNumber, mEntryMBT, 0, 0);
}

void WickFractal::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<WickFractal>(this, partialedTicket, newTicketNumber);
}

void WickFractal::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<WickFractal>(this, ticket, Period());
}

void WickFractal::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<WickFractal>(this, error, additionalInformation);
}

void WickFractal::Reset()
{
}