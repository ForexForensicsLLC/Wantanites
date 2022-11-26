//+------------------------------------------------------------------+
//|                                                    FiveMinMBSetup.mqh |
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

class FiveMinMBSetup : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mLastEntryMBT;

    int mFirstMBInSetupNumber;
    int mFirstMBInEntryNumber;

    datetime mZoneCandleTime;

    double mMaxMBPips;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mLastEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    FiveMinMBSetup(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT);
    ~FiveMinMBSetup();

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

FiveMinMBSetup::FiveMinMBSetup(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&entryMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mLastEntryMBT = entryMBT;

    mFirstMBInSetupNumber = EMPTY;
    mFirstMBInEntryNumber = EMPTY;

    mZoneCandleTime = 0;

    mMaxMBPips = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<FiveMinMBSetup>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<FiveMinMBSetup, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<FiveMinMBSetup, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mLastEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

FiveMinMBSetup::~FiveMinMBSetup()
{
}

double FiveMinMBSetup::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<FiveMinMBSetup>(this, 5, 0.5);
}

void FiveMinMBSetup::Run()
{
    EAHelper::RunDrawMBTs<FiveMinMBSetup>(this, mSetupMBT, mLastEntryMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool FiveMinMBSetup::AllowedToTrade()
{
    return EAHelper::BelowSpread<FiveMinMBSetup>(this) && EAHelper::WithinTradingSession<FiveMinMBSetup>(this);
}

void FiveMinMBSetup::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (EAHelper::CheckSetSingleMBSetup<FiveMinMBSetup>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        if (EAHelper::MostRecentMBZoneIsHolding<FiveMinMBSetup>(this, mSetupMBT, mFirstMBInSetupNumber))
        {
            if (EAHelper::CheckSetSingleMBSetup<FiveMinMBSetup>(this, mLastEntryMBT, mFirstMBInEntryNumber, mSetupType))
            {
                MBState *entryMB;
                if (!mLastEntryMBT.GetMB(mFirstMBInEntryNumber, entryMB))
                {
                    return;
                }

                if (entryMB.Height() > OrderHelper::PipsToRange(mMaxMBPips))
                {
                    return;
                }

                // make sure first mb isn't too small
                // if (entryMB.StartIndex() - entryMB.EndIndex() < 10)
                // {
                //     return;
                // }

                int pendingMBStart = EMPTY;
                double pendingMBHeight = 0.0;
                if (EAHelper::MostRecentMBZoneIsHolding<FiveMinMBSetup>(this, mLastEntryMBT, mFirstMBInEntryNumber))
                {
                    if (mSetupType == OP_BUY)
                    {
                        if (!mLastEntryMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
                        {
                            return;
                        }

                        int lowestIndex = EMPTY;
                        if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, entryMB.EndIndex() - 1, 1, true, lowestIndex))
                        {
                            return;
                        }

                        // pendingMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iLow(mEntrySymbol, mEntryTimeFrame, lowestIndex);
                        // if (pendingMBHeight < OrderHelper::PipsToRange(mMinMBHeight))
                        // {
                        //     return;
                        // }

                        // need to break within 3 candles of our lowest
                        // if (lowestIndex > 3)
                        // {
                        //     return;
                        // }

                        // make sure low is above ema
                        // if (iLow(mEntrySymbol, mEntryTimeFrame, lowestIndex) < EMA(lowestIndex))
                        // {
                        //     return;
                        // }

                        // make sure we broke above
                        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2))
                        {
                            return;
                        }

                        mHasSetup = true;
                        mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                        // mMostRecentMB = mLastEntryMBT.MBsCreated() - 1;
                    }
                    else if (mSetupType == OP_SELL)
                    {
                        if (!mLastEntryMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
                        {
                            return;
                        }

                        int highestIndex = EMPTY;
                        if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, entryMB.EndIndex() - 1, 1, true, highestIndex))
                        {
                            return;
                        }

                        // pendingMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, highestIndex) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart);
                        // if (pendingMBHeight < OrderHelper::PipsToRange(mMinMBHeight))
                        // {
                        //     return;
                        // }

                        // need to break within 3 candles of our highest
                        // if (highestIndex > 3)
                        // {
                        //     return;
                        // }

                        // make sure high is below ema
                        // if (iHigh(mEntrySymbol, mEntryTimeFrame, highestIndex) > EMA(highestIndex))
                        // {
                        //     return;
                        // }

                        // make sure we broke below a candle
                        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2))
                        {
                            return;
                        }

                        mHasSetup = true;
                        mZoneCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 2);
                        // mMostRecentMB = mLastEntryMBT.MBsCreated() - 1;
                    }
                }
            }
        }
    }
}

void FiveMinMBSetup::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY && mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        mFirstMBInEntryNumber = EMPTY;
        mFirstMBInSetupNumber = EMPTY;

        return;
    }

    if (mFirstMBInEntryNumber != EMPTY && mFirstMBInEntryNumber != mLastEntryMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
        mFirstMBInEntryNumber = EMPTY;

        return;
    }

    if (!mHasSetup)
    {
        return;
    }

    if (!EAHelper::MostRecentMBZoneIsHolding<FiveMinMBSetup>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        InvalidateSetup(true);
        return;
    }

    if (!EAHelper::MostRecentMBZoneIsHolding<FiveMinMBSetup>(this, mLastEntryMBT, mFirstMBInEntryNumber))
    {
        InvalidateSetup(true);
        return;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);
    if (mSetupType == OP_BUY)
    {
        // invalidate if we broke below our candle zone
        if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // invalidate if we broke above our candle zone
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex))
        {
            InvalidateSetup(true);
            return;
        }
    }
}

void FiveMinMBSetup::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<FiveMinMBSetup>(this, deletePendingOrder, false, error);

    mZoneCandleTime = 0;
}

bool FiveMinMBSetup::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    int zoneCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mZoneCandleTime);

    // make sure we actually had a decent push up after the inital break
    // if (zoneCandleIndex < 5)
    // {
    //     return false;
    // }

    if (mSetupType == OP_BUY)
    {
        bool pushedUpAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bearish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBearish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) < iLow(mEntrySymbol, mEntryTimeFrame, i + 1))
            {
                pushedUpAfterInitialBreak = true;
                break;
            }
        }

        if (!pushedUpAfterInitialBreak)
        {
            return false;
        }

        // need a body break above our previous candle while within the candle zone
        if (iLow(mEntrySymbol, mEntryTimeFrame, 2) < iHigh(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        bool pushedDownAfterInitialBreak = false;
        for (int i = zoneCandleIndex - 1; i >= 1; i--)
        {
            // need to have a bullish candle break a previuos one, heading back into the candle zone in order for it to be considered a
            // decent push back in
            if (CandleStickHelper::IsBullish(mEntrySymbol, mEntryTimeFrame, i) &&
                MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, i), iClose(mEntrySymbol, mEntryTimeFrame, i)) > iHigh(mEntrySymbol, mEntryTimeFrame, i + 1))
            {
                pushedDownAfterInitialBreak = true;
                break;
            }
        }

        if (!pushedDownAfterInitialBreak)
        {
            return false;
        }
        // need a body break below our previous candle while within the candle zone
        if (iHigh(mEntrySymbol, mEntryTimeFrame, 2) > iLow(mEntrySymbol, mEntryTimeFrame, zoneCandleIndex) &&
            iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2))
        {
            return true;
        }
    }

    return hasTicket;
}

void FiveMinMBSetup::PlaceOrders()
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
        double lowest = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 2), iLow(mEntrySymbol, mEntryTimeFrame, 1));

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(lowest - OrderHelper::PipsToRange(mMinStopLossPips), entry - OrderHelper::PipsToRange(mMinStopLossPips));
    }
    else if (mSetupType == OP_SELL)
    {
        double highest = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 2), iHigh(mEntrySymbol, mEntryTimeFrame, 1));
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);

        stopLoss = MathMax(highest + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips), entry + OrderHelper::PipsToRange(mMinStopLossPips));
    }

    EAHelper::PlaceStopOrder<FiveMinMBSetup>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void FiveMinMBSetup::ManageCurrentPendingSetupTicket()
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

void FiveMinMBSetup::ManageCurrentActiveSetupTicket()
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
        double percentIntoSL = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        double percentIntoSL = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice());
        if (percentIntoSL >= 0.2)
        {
            mCurrentSetupTicket.Close();
            return;
        }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips /*|| mLastEntryMB != mSetupMBT.MBsCreated() - 1*/)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<FiveMinMBSetup>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool FiveMinMBSetup::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<FiveMinMBSetup>(this, ticket);
}

void FiveMinMBSetup::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<FiveMinMBSetup>(this, mPreviousSetupTickets[ticketIndex]);
}

void FiveMinMBSetup::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FiveMinMBSetup>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<FiveMinMBSetup>(this);
}

void FiveMinMBSetup::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<FiveMinMBSetup>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<FiveMinMBSetup>(this, ticketIndex);
}

void FiveMinMBSetup::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<FiveMinMBSetup>(this, mFirstMBInEntryNumber, mLastEntryMBT, 0, 0);
}

void FiveMinMBSetup::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<FiveMinMBSetup>(this, partialedTicket, newTicketNumber);
}

void FiveMinMBSetup::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<FiveMinMBSetup>(this, ticket, Period());
}

void FiveMinMBSetup::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<FiveMinMBSetup>(this, error, additionalInformation);
}

void FiveMinMBSetup::Reset()
{
}