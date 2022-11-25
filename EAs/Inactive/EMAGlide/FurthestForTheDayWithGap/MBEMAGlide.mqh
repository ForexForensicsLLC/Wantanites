//+------------------------------------------------------------------+
//|                                                    MBEMAGlide.mqh |
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

class MBEMAGlide : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;
    double mMaxMBHeight;
    double mMinMBGap;

    double mEntryPaddingPips;
    double mMinStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    datetime mEntryCandleTime;
    int mEntryMB;
    int mBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    double mLastManagedAsk;
    double mLastManagedBid;

public:
    MBEMAGlide(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~MBEMAGlide();

    double EMA(int index) { return iMA(mEntrySymbol, mEntryTimeFrame, 50, 0, MODE_EMA, PRICE_CLOSE, index); }
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

MBEMAGlide::MBEMAGlide(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;

    mFirstMBInSetupNumber = EMPTY;
    mMaxMBHeight = 0.0;
    mMinMBGap = 0.0;

    mEntryPaddingPips = 0.0;
    mMinStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<MBEMAGlide>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<MBEMAGlide, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<MBEMAGlide, SingleTimeFrameEntryTradeRecord>(this);

    mBarCount = 0;
    mEntryMB = EMPTY;
    mEntryCandleTime = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mLastManagedAsk = 0.0;
    mLastManagedBid = 0.0;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

MBEMAGlide::~MBEMAGlide()
{
}

double MBEMAGlide::RiskPercent()
{
    // reduce risk by half if we lose 5%
    return EAHelper::GetReducedRiskPerPercentLost<MBEMAGlide>(this, 5, 0.5);
}

void MBEMAGlide::Run()
{
    EAHelper::RunDrawMBT<MBEMAGlide>(this, mSetupMBT);
    mBarCount = iBars(mEntrySymbol, mEntryTimeFrame);
}

bool MBEMAGlide::AllowedToTrade()
{
    return EAHelper::BelowSpread<MBEMAGlide>(this) && EAHelper::WithinTradingSession<MBEMAGlide>(this);
}

void MBEMAGlide::CheckSetSetup()
{
    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    MBState *tempMBStates[];
    if (!mSetupMBT.GetNMostRecentMBs(3, tempMBStates))
    {
        return;
    }

    int startTime = mTradingSessions[0].StartIndex(mEntrySymbol, mEntryTimeFrame);

    int pendingMBStart = EMPTY;
    double furthestPriceOfTheDay = 0.0;

    if (mSetupType == OP_BUY)
    {
        if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, startTime, 0, true, furthestPriceOfTheDay))
        {
            return;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) < furthestPriceOfTheDay)
        {
            return;
        }

        if (tempMBStates[0].Type() != OP_BUY || tempMBStates[1].Type() != OP_BUY)
        {
            return;
        }

        bool greaterPushUpThanFirstMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, pendingMBStart) - iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[0].HighIndex()) >
                                              tempMBStates[0].Height();

        if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[0].LowIndex()) > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[1].HighIndex()))
        {
            if (greaterPushUpThanFirstMBHeight)
            {
                mHasSetup = true;
                mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;

                return;
            }
        }

        if (tempMBStates[2].Type() != OP_BUY)
        {
            return;
        }

        if (iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[1].LowIndex()) > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[2].HighIndex()))
        {
            bool greaterPushUpThanSecondMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[0].HighIndex()) -
                                                       iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[1].HighIndex()) >
                                                   tempMBStates[1].Height();

            if (greaterPushUpThanFirstMBHeight || greaterPushUpThanSecondMBHeight)
            {
                mHasSetup = true;
                mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;

                return;
            }
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(pendingMBStart))
        {
            return;
        }

        if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, startTime, 0, true, furthestPriceOfTheDay))
        {
            return;
        }

        if (iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) > furthestPriceOfTheDay)
        {
            return;
        }

        if (tempMBStates[0].Type() != OP_SELL || tempMBStates[1].Type() != OP_SELL)
        {
            return;
        }

        bool greaterPushDownThanFirstMBHeight = iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[0].LowIndex()) - iLow(mEntrySymbol, mEntryTimeFrame, pendingMBStart) >
                                                tempMBStates[0].Height();

        if (iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[0].HighIndex()) < iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[1].LowIndex()))
        {
            if (greaterPushDownThanFirstMBHeight)
            {
                mHasSetup = true;
                mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;

                return;
            }
        }

        if (tempMBStates[2].Type() != OP_SELL)
        {
            return;
        }

        if (iHigh(mEntrySymbol, mEntryTimeFrame, tempMBStates[1].HighIndex()) < iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[2].LowIndex()))
        {
            bool greaterPushDownThanSecondMBHeight = iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[1].LowIndex()) -
                                                         iLow(mEntrySymbol, mEntryTimeFrame, tempMBStates[0].LowIndex()) >
                                                     tempMBStates[1].Height();

            if (greaterPushDownThanFirstMBHeight || greaterPushDownThanSecondMBHeight)
            {
                mHasSetup = true;
                mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;

                return;
            }
        }
    }
}

void MBEMAGlide::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return;
    }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        if (mFirstMBInSetupNumber != mSetupMBT.MBsCreated() - 1)
        {
            // keep the setup going as long as we keep puttin in same type mbs
            if (mSetupMBT.GetNthMostRecentMBsType(0) == mSetupType)
            {
                mFirstMBInSetupNumber = mSetupMBT.MBsCreated() - 1;
            }
            else
            {
                InvalidateSetup(true);
            }
        }
    }
}

void MBEMAGlide::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<MBEMAGlide>(this, deletePendingOrder, false, error);
    EAHelper::ResetSingleMBSetup<MBEMAGlide>(this, false);
}

bool MBEMAGlide::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    if (iBars(mEntrySymbol, mEntryTimeFrame) <= mBarCount)
    {
        return hasTicket;
    }

    bool dojiInZone = EAHelper::DojiInsideMostRecentMBsHoldingZone<MBEMAGlide>(this, mSetupMBT, mFirstMBInSetupNumber);
    // bool furthestInZone = EAHelper::CandleIsInZone<MBEMAGlide>(this, mSetupMBT, mFirstMBInSetupNumber, 1, true);

    return hasTicket || (dojiInZone);
}

void MBEMAGlide::PlaceOrders()
{
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

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return;
    }

    double entry = 0.0;
    double stopLoss = 0.0;

    if (mSetupType == OP_BUY)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mEntryPaddingPips);
        stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mStopLossPaddingPips),
                           iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()));
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mEntryPaddingPips);
        stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips + mStopLossPaddingPips),
                           iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()));
    }

    EAHelper::PlaceStopOrder<MBEMAGlide>(this, entry, stopLoss, 0.0, true, mBEAdditionalPips);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mEntryMB = mFirstMBInSetupNumber;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void MBEMAGlide::ManageCurrentPendingSetupTicket()
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
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
    else if (mSetupType == OP_SELL)
    {
        if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
        {
            InvalidateSetup(true);
        }
    }
}

void MBEMAGlide::ManageCurrentActiveSetupTicket()
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
    int orderPlaceIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, OrderOpenTime());
    bool furtherThanEntry = false;

    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (entryIndex > 20)
    {
        movedPips = true;
    }

    if (mEntryMB != mSetupMBT.MBsCreated() - 1 && !movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBEMAGlide>(this, 0.0);
    }
    else if (movedPips || mEntryMB != mSetupMBT.MBsCreated() - 1)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<MBEMAGlide>(this, mBEAdditionalPips);
    }

    mLastManagedAsk = currentTick.ask;
    mLastManagedBid = currentTick.bid;
}

bool MBEMAGlide::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<MBEMAGlide>(this, ticket);
}

void MBEMAGlide::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialTicket<MBEMAGlide>(this, mPreviousSetupTickets[ticketIndex]);
}

void MBEMAGlide::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBEMAGlide>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<MBEMAGlide>(this);
}

void MBEMAGlide::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<MBEMAGlide>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<MBEMAGlide>(this, ticketIndex);
}

void MBEMAGlide::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<MBEMAGlide>(this);
}

void MBEMAGlide::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<MBEMAGlide>(this, partialedTicket, newTicketNumber);
}

void MBEMAGlide::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<MBEMAGlide>(this, ticket, Period());
}

void MBEMAGlide::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<MBEMAGlide>(this, error, additionalInformation);
}

void MBEMAGlide::Reset()
{
}