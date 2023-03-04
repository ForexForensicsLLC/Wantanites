//+------------------------------------------------------------------+
//|                                                    LoneDoji.mqh |
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

class LoneDoji : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    int mFirstMBInSetupNumber;

    double mMinPercentChange;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mLastEntryMB;

public:
    LoneDoji(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
             CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
             CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~LoneDoji();

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

LoneDoji::LoneDoji(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    mMinPercentChange = 0.0;

    mBarCount = 0;
    mEntryCandleTime = 0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mLastEntryMB = EMPTY;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLargestAccountBalance = 100000;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<LoneDoji>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<LoneDoji, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<LoneDoji, SingleTimeFrameEntryTradeRecord>(this);
}

LoneDoji::~LoneDoji()
{
}

void LoneDoji::Run()
{
    EAHelper::RunDrawMBT<LoneDoji>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool LoneDoji::AllowedToTrade()
{
    return EAHelper::BelowSpread<LoneDoji>(this) && EAHelper::WithinTradingSession<LoneDoji>(this);
}

void LoneDoji::CheckSetSetup()
{
    if (EAHelper::CheckSetSingleMBSetup<LoneDoji>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (mFirstMBInSetupNumber == mLastEntryMB)
        {
            return;
        }

        mHasSetup = true;
    }
}

void LoneDoji::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }
}

void LoneDoji::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<LoneDoji>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
}

bool LoneDoji::Confirmation()
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
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    if (!EAHelper::CandleIsInZone<LoneDoji>(this, mSetupMBT, mFirstMBInSetupNumber, 2, true))
    {
        return false;
    }

    if (mSetupType == OP_BUY)
    {
        if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 3) > -mMinPercentChange ||
            !CandleStickHelper::HasImbalance(OP_SELL, mEntrySymbol, mEntryTimeFrame, 3))
        {
            return false;
        }

        if (!SetupHelper::HammerCandleStickPattern(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return false;
        }

        if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 1) < mMinPercentChange)
        {
            return false;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 3) < mMinPercentChange ||
            !CandleStickHelper::HasImbalance(OP_BUY, mEntrySymbol, mEntryTimeFrame, 3))
        {
            return false;
        }

        if (!SetupHelper::ShootingStarCandleStickPattern(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return false;
        }

        if (CandleStickHelper::PercentChange(mEntrySymbol, mEntryTimeFrame, 1) > -mMinPercentChange)
        {
            return false;
        }
    }

    return true;
}

void LoneDoji::PlaceOrders()
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
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    }

    EAHelper::PlaceStopOrder<LoneDoji>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void LoneDoji::ManageCurrentPendingSetupTicket()
{
    int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);

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

    if (entryCandleIndex > 1)
    {
        InvalidateSetup(true);
    }

    if (mSetupType == OP_BUY)
    {
        if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > OrderStopLoss())
        {
            InvalidateSetup(true);
        }
    }
}

void LoneDoji::ManageCurrentActiveSetupTicket()
{
    if (mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (mLastEntryMB != mFirstMBInSetupNumber && mFirstMBInSetupNumber != EMPTY)
    {
        mLastEntryMB = mFirstMBInSetupNumber;
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

    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool movedPips = false;

    if (mSetupType == OP_BUY)
    {
        if (entryIndex > 5)
        {
            // close if we are still opening within our entry and get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() && currentTick.bid >= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a low within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iLow(mEntrySymbol, mEntryTimeFrame, i) > OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iLow(mEntrySymbol, mEntryTimeFrame, i) < iLow(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.bid >= OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // early close
        if (entryIndex > 5)
        {
            // close if we are still opening above our entry and we get the chance to close at BE
            if (iOpen(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() && currentTick.ask <= OrderOpenPrice())
            {
                mCurrentSetupTicket.Close();
            }
        }

        // middle close
        // This is here as a safety net so we aren't running a very expenseive nested for loop. If this returns false something went wrong or I need to change things.
        // close if we break a high within our stop loss
        if (entryIndex <= 200)
        {
            // do minus 2 so that we don't include the candle that we actually entered on in case it wicked below before entering
            for (int i = entryIndex - 2; i >= 0; i--)
            {
                if (iHigh(mEntrySymbol, mEntryTimeFrame, i) < OrderOpenPrice())
                {
                    break;
                }

                for (int j = entryIndex; j > i; j--)
                {
                    if (iHigh(mEntrySymbol, mEntryTimeFrame, i) > iHigh(mEntrySymbol, mEntryTimeFrame, j))
                    {
                        // managed to break back out, close at BE
                        if (currentTick.ask <= OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips))
                        {
                            mCurrentSetupTicket.Close();
                            return;
                        }
                    }
                }
            }
        }
        else
        {
            // TOD: Create error code
            string additionalInformation = "Entry Index: " + entryIndex;
            RecordError(-1, additionalInformation);
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<LoneDoji>(this, mBEAdditionalPips);
    }
}

bool LoneDoji::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<LoneDoji>(this, ticket);
}

void LoneDoji::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<LoneDoji>(this, mPreviousSetupTickets[ticketIndex]);
}

void LoneDoji::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LoneDoji>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<LoneDoji>(this);
}

void LoneDoji::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<LoneDoji>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<LoneDoji>(this, ticketIndex);
}

void LoneDoji::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<LoneDoji>(this);
}

void LoneDoji::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<LoneDoji>(this, partialedTicket, newTicketNumber);
}

void LoneDoji::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<LoneDoji>(this, ticket, Period());
}

void LoneDoji::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<LoneDoji>(this, error, additionalInformation);
}

void LoneDoji::Reset()
{
}