//+------------------------------------------------------------------+
//|                                                       TestEA.mqh |
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

class TestEA : public EA<MultiTimeFrameEntryTradeRecord, PartialTradeRecord, MultiTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;
    MBTracker *mConfirmationMBT;

    LiquidationSetupTracker *mLST;

    int mLastCheckedSetupMB;
    int mLastCheckedConfirmationMB;

    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;
    int mLiquidationMBInSetupNumber;

    int mFirstMBInConfirmationNumber;
    int mSecondMBInConfirmationNumber;

    int mSetupMBsCreated;
    int mCheckInvalidateSetupMBsCreated;
    int mInvalidateSetupMBsCreated;
    int mConfirmationMBsCreated;

    datetime mEntryCandleTime;
    int mBarCount;

    int mTimeFrame;
    string mEntrySymbol;
    int mEntryTimeFrame;

    bool mHasMBValChange;
    bool mHasZoneImbalanceChange;

    int mMBCount;
    int mLastDay;

public:
    TestEA(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
           CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
           CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst);
    ~TestEA();

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

TestEA::TestEA(int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<MultiTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT, MBTracker *&confirmationMBT, LiquidationSetupTracker *&lst)
    : EA(maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mConfirmationMBT = confirmationMBT;

    mLST = lst;

    mSetupType = setupType;

    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
    mLiquidationMBInSetupNumber = EMPTY;

    mFirstMBInConfirmationNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TestEA>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TestEA, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TestEA, MultiTimeFrameEntryTradeRecord>(this);

    if (setupType == OP_BUY)
    {
        EAHelper::FillBullishKataraMagicNumbers<TestEA>(this);
    }
    else
    {
        EAHelper::FillBearishKataraMagicNumbers<TestEA>(this);
    }

    mSetupMBsCreated = 0;
    mMBCount = 0;
    mLastDay = 0;
    mCheckInvalidateSetupMBsCreated = 0;
    mInvalidateSetupMBsCreated = 0;
    mConfirmationMBsCreated = 0;

    mBarCount = 0;
    mEntryCandleTime = 0;
    mTimeFrame = 1;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = 1;

    mHasMBValChange = false;
    mHasZoneImbalanceChange = false;

    mLargestAccountBalance = 100000;
}

TestEA::~TestEA()
{
}

double TestEA::RiskPercent()
{
    return EAHelper::GetReducedRiskPerPercentLost<TestEA>(this, 1, 0.005); // TODO: Put back
}

void TestEA::Run()
{
    EAHelper::RunDrawMBTs<TestEA>(this, mSetupMBT, mConfirmationMBT);
}

bool TestEA::AllowedToTrade()
{
    return EAHelper::BelowSpread<TestEA>(this) /*&& (Hour() >= 16 && Hour() < 23)*/;
}

void TestEA::CheckSetSetup()
{
    if (mLastDay != Day())
    {
        mMBCount = 0;
        mLastDay = Day();
    }

    if (mSetupMBT.MBsCreated() > mSetupMBsCreated)
    {
        mSetupMBsCreated = mSetupMBT.MBsCreated();
        mMBCount += 1;
    }

    if (EAHelper::CheckSetSingleMBSetup<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        string additionalInformation = "";
        if (EAHelper::SetupZoneIsValidForConfirmation<TestEA>(this, mFirstMBInSetupNumber, 0, additionalInformation))
        {
            if (EAHelper::CheckSetSingleMBSetup<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, mSetupType))
            {
                mHasSetup = true;
            }
        }
    }
}

void TestEA::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Start of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeStart<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // Cancel any pending orders since the setup didn't hold
        EAHelper::InvalidateSetup<TestEA>(this, true, false);
        EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
        EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

        mHasSetup = false;

        return;
    }

    // End of Setup TF Liquidation
    if (EAHelper::CheckBrokeMBRangeEnd<TestEA>(this, mSetupMBT, mFirstMBInSetupNumber))
    {
        // don't cancel any pending orders since the setup held and continued
        EAHelper::InvalidateSetup<TestEA>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
        EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);

        mHasSetup = false;

        return;
    }

    if (mConfirmationMBT.MBsCreated() - 1 != mFirstMBInConfirmationNumber)
    {
        EAHelper::InvalidateSetup<TestEA>(this, false, false);
        EAHelper::ResetLiquidationMBSetup<TestEA>(this, false);
        EAHelper::ResetSingleMBConfirmation<TestEA>(this, false);
    }

    if (!mHasSetup)
    {
        return;
    }
}

void TestEA::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TestEA>(this, deletePendingOrder, false, error);
    mHasSetup = true;
    mEntryCandleTime = 0;
}

bool TestEA::Confirmation()
{
    // bool dojiInHoldingZone = false;
    // int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, dojiInHoldingZone);
    // if (error != ERR_NO_ERROR)
    // {
    //     return false;
    // }

    // MBState *tempMBState;
    // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    // {
    //     return false;
    // }

    // ZoneState *tempZoneState;
    // if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    // {
    //     return false;
    // }

    // double minPercentChange = 0.5;
    // double mbValChange = MathAbs((iOpen(Symbol(), 15, tempMBState.EndIndex()) - iClose(Symbol(), 15, tempMBState.EndIndex())) /
    //                              iOpen(Symbol(), 15, tempMBState.EndIndex()));

    // mbValChange = false;
    // int zoneImbalance = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    // double zoneImbalanceChange = MathAbs((iOpen(Symbol(), 15, zoneImbalance) - iClose(Symbol(), 15, zoneImbalance)) /
    //                                      iOpen(Symbol(), 15, zoneImbalance));

    // bool hasConfirmation = dojiInHoldingZone && ((mbValChange > (minPercentChange / 100)) || (zoneImbalanceChange > (minPercentChange / 100)));

    // mHasMBValChange = mbValChange > (minPercentChange / 100);
    // mHasZoneImbalanceChange = zoneImbalanceChange > (minPercentChange / 100);

    // return hasConfirmation;
    bool zoneIsHolding = false;
    int zoneIsHoldingError = EAHelper::MostRecentMBZoneIsHolding<TestEA>(this, mConfirmationMBT, mFirstMBInConfirmationNumber, zoneIsHolding);
    if (zoneIsHoldingError != ERR_NO_ERROR)
    {
        InvalidateSetup(true);
        return false;
    }

    if (!zoneIsHolding)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mConfirmationMBT.GetMB(mFirstMBInConfirmationNumber, tempMBState))
    {
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        RecordError(GetLastError());
        return false;
    }

    bool potentialDoji = false;
    bool withinZone = false;

    if (mSetupType == OP_BUY)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
                        currentTick.bid < iLow(mEntrySymbol, mEntryTimeFrame, 1);

        withinZone = iLow(mEntrySymbol, mEntryTimeFrame, 0) <= tempZoneState.EntryPrice() && currentTick.bid >= tempZoneState.ExitPrice();
    }
    else if (mSetupType == OP_SELL)
    {
        potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
                        currentTick.bid > iHigh(mEntrySymbol, mEntryTimeFrame, 1);

        withinZone = iHigh(mEntrySymbol, mEntryTimeFrame, 0) >= tempZoneState.EntryPrice() && currentTick.bid <= tempZoneState.ExitPrice();
    }

    return mCurrentSetupTicket.Number() != EMPTY || (potentialDoji && withinZone);
}

void TestEA::PlaceOrders()
{
    // int currentBars = iBars(Symbol(), Period());
    // if (currentBars <= mBarCount)
    // {
    //     return;
    // }

    // if (mCurrentSetupTicket.Number() != EMPTY)
    // {
    //     return;
    // }

    // MBState *tempMBState;
    // if (!mConfirmationMBT.GetMB(mFirstMBInConfirmationNumber, tempMBState))
    // {
    //     return;
    // }

    // ZoneState *tempZoneState;
    // if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    // {
    //     return;
    // }

    // EAHelper::PlaceStopOrderForCandelBreak<TestEA>(this, Symbol(), 1, iTime(Symbol(), 1, 1), iTime(Symbol(), 1, 1));

    // mEntryCandleTime = iTime(Symbol(), 1, 1);
    // mBarCount = currentBars;

    // string info = mCurrentSetupTicket.Number() + " " + mMBCount + " " + mHasMBValChange + " " + mHasZoneImbalanceChange;
    // RecordError(-234, info);

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
    double stopLossPips = 3;

    if (mSetupType == OP_BUY)
    {
        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);

        // don't place the order if it is going to activate right away
        if (currentTick.ask > entry)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);

        if (currentTick.bid < entry)
        {
            return;
        }
    }

    EAHelper::PlaceStopOrder<TestEA>(this, entry, stopLoss);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }
}

void TestEA::ManageCurrentPendingSetupTicket()
{
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // EAHelper::CheckBrokePastCandle<TestEA>(this, Symbol(), Period(), mSetupType, mEntryCandleTime);
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
        mCurrentSetupTicket.Close();
    }
}

void TestEA::ManageCurrentActiveSetupTicket()
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
    double pipsToWait = 2;
    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(pipsToWait);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(pipsToWait);
    }

    double additionalPips = 0.2;
    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TestEA>(this, additionalPips);
    }
}

bool TestEA::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return EAHelper::TicketStopLossIsMovedToBreakEven<TestEA>(this, ticket);
}

void TestEA::ManagePreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckPartialPreviousSetupTicket<TestEA>(this, ticketIndex);
}

void TestEA::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TestEA>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TestEA>(this);
}

void TestEA::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TestEA>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TestEA>(this, ticketIndex);
}

void TestEA::RecordTicketOpenData()
{
    EAHelper::RecordMultiTimeFrameEntryTradeRecord<TestEA>(this, mSetupMBT.TimeFrame());
}

void TestEA::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TestEA>(this, oldTicketIndex, newTicketNumber);
}

void TestEA::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordMultiTimeFrameExitTradeRecord<TestEA>(this, ticket, mConfirmationMBT.TimeFrame(), mSetupMBT.TimeFrame());
}

void TestEA::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TestEA>(this, error, additionalInformation);
}

void TestEA::Reset()
{
    // this should never get called unless we have higher spread in which case we really don't need to do anything
}