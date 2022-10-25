//+------------------------------------------------------------------+
//|                                                    TheGrannySmith.mqh |
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

class TheGrannySmith : public EA<MBEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mSetupMBT;

    int mFirstMBInSetupNumber;

    int mSetupMBsCreated;

    datetime mEntryCandleTime;
    datetime mStopLossCandleTime;
    int mBarCount;
    int mManageCurrentSetupBarCount;
    int mConfirmationBarCount;
    int mSetupBarCount;
    int mCheckInvalidateSetupBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;

    int mSetupTimeFrame;
    string mSetupSymbol;

    int mLastEntryMB;
    int mLastEntryZone;

    int mMBCount;
    int mLastDay;
    int mEntryMBNumber;

    double mImbalanceCandlePercentChange;

public:
    TheGrannySmith(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                   CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                   CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT);
    ~TheGrannySmith();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::BullishKataraSingleMB : MagicNumbers::BearishKataraSingleMB; }
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

TheGrannySmith::TheGrannySmith(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                               CSVRecordWriter<MBEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&setupMBT)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mSetupMBT = setupMBT;
    mFirstMBInSetupNumber = EMPTY;

    EAHelper::FindSetPreviousAndCurrentSetupTickets<TheGrannySmith>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<TheGrannySmith, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<TheGrannySmith, MultiTimeFrameEntryTradeRecord>(this);

    mSetupMBsCreated = 0;

    mConfirmationBarCount = 0;
    mBarCount = 0;
    mManageCurrentSetupBarCount = 0;
    mCheckInvalidateSetupBarCount = 0;
    mSetupBarCount = 0;
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;

    mLastEntryMB = EMPTY;
    mLastEntryZone = EMPTY;

    mMBCount = 0;
    mLastDay = 0;

    mImbalanceCandlePercentChange = 0.0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mSetupSymbol = Symbol();
    mSetupTimeFrame = 15;

    mEntryMBNumber = EMPTY;

    // TODO: Change Back
    mLargestAccountBalance = AccountBalance();
}

TheGrannySmith::~TheGrannySmith()
{
}

double TheGrannySmith::RiskPercent()
{
    double riskPercent = 0.25;

    double percentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;
    // for each one percent that we lost, reduce risk by 0.05 %
    while (percentLost >= 1)
    {
        riskPercent -= 0.05;
        percentLost -= 1;
    }

    return riskPercent;
}

void TheGrannySmith::Run()
{
    EAHelper::RunDrawMBT<TheGrannySmith>(this, mSetupMBT);
}

bool TheGrannySmith::AllowedToTrade()
{
    return EAHelper::BelowSpread<TheGrannySmith>(this) && EAHelper::WithinTradingSession<TheGrannySmith>(this);
}

void TheGrannySmith::CheckSetSetup()
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

    if (EAHelper::CheckSetSingleMBSetup<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, mSetupType))
    {
        // MBState *tempMBState;
        // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        // {
        //     return;
        // }

        // if (!tempMBState.HasImpulseValidation())
        // {
        //     return;
        // }

        mHasSetup = true;
    }

    // int currentBars = iBars(mSetupSymbol, mSetupTimeFrame);
    // if (currentBars <= mSetupBarCount)
    // {
    //     return;
    // }

    // mSetupBarCount = currentBars;

    // int entryCandle = 1;
    // if (mSetupType == OP_BUY)
    // {
    //     bool previousIsBearish = iClose(mSetupSymbol, mSetupTimeFrame, entryCandle) < iOpen(mSetupSymbol, mSetupTimeFrame, entryCandle);
    //     bool previousDidNotBreakLower = iClose(mSetupSymbol, mSetupTimeFrame, entryCandle) > iLow(mSetupSymbol, mSetupTimeFrame, entryCandle + 1);
    //     bool twoPreviousBrokeAbove = iClose(mSetupSymbol, mSetupTimeFrame, entryCandle + 1) > iHigh(mSetupSymbol, mSetupTimeFrame, entryCandle + 2);

    //     if (previousIsBearish && previousDidNotBreakLower && twoPreviousBrokeAbove)
    //     {
    //         mHasSetup = true;
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     bool previousIsBullish = iClose(mSetupSymbol, mSetupTimeFrame, entryCandle) > iOpen(mSetupSymbol, mSetupTimeFrame, entryCandle);
    //     bool previousDidNotBreakHigher = iClose(mSetupSymbol, mSetupTimeFrame, entryCandle) < iHigh(mSetupSymbol, mSetupTimeFrame, entryCandle + 1);
    //     bool twoPreviousBrokeBelow = iClose(mSetupSymbol, mSetupTimeFrame, entryCandle + 1) < iLow(mSetupSymbol, mSetupTimeFrame, entryCandle + 2);

    //     if (previousIsBullish && previousDidNotBreakHigher && twoPreviousBrokeBelow)
    //     {
    //         mHasSetup = true;
    //     }
    // }
}

void TheGrannySmith::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // int currentBars = iBars(mSetupSymbol, mSetupTimeFrame);
    // if (currentBars > mCheckInvalidateSetupBarCount)
    // {
    //     mCheckInvalidateSetupBarCount = currentBars;

    //     if (mSetupType == OP_BUY)
    //     {
    //         // invalide if we broke below a candle on the setup time frame
    //         if (iClose(mSetupSymbol, mSetupTimeFrame, 1) < iLow(mSetupSymbol, mSetupTimeFrame, 2))
    //         {
    //             InvalidateSetup(true);
    //         }
    //     }
    //     else if (mSetupType == OP_SELL)
    //     {
    //         // invalide if we broke above a candle on the setup time frame
    //         if (iClose(mSetupSymbol, mSetupTimeFrame, 1) > iHigh(mSetupSymbol, mSetupTimeFrame, 2))
    //         {
    //             InvalidateSetup(true);
    //         }
    //     }
    // }

    if (mFirstMBInSetupNumber != EMPTY)
    {
        // invalidate if we are not the most recent MB
        if (mSetupMBT.MBsCreated() - 1 != mFirstMBInSetupNumber)
        {
            InvalidateSetup(true);
        }
    }
}

void TheGrannySmith::InvalidateSetup(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    EAHelper::InvalidateSetup<TheGrannySmith>(this, deletePendingOrder, false, error);
    mFirstMBInSetupNumber = EMPTY;
    mEntryCandleTime = 0;
    mStopLossCandleTime = 0;
}

bool TheGrannySmith::Confirmation()
{
    bool hasTicket = mCurrentSetupTicket.Number() != EMPTY;

    int bars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (bars <= mConfirmationBarCount)
    {
        return hasTicket;
    }

    mConfirmationBarCount = bars;

    // int entryCandle = 2;
    // bool isTrue = false;
    // int error = EAHelper::DojiInsideMostRecentMBsHoldingZone<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, isTrue, entryCandle);
    // if (error != ERR_NO_ERROR)
    // {
    //     return false;
    // }

    MBState *tempMBState;
    if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
    {
        return false;
    }

    // if (mLastEntryMB == tempMBState.Number())
    // {
    //     return hasTicket;
    // }

    double minMBHeightPips = 700;
    double maxMBHeightPips = 2500;
    // int minMBWidthCandles = 7;
    // int minPipsPerCandle = 70;
    // double currentMBPercentIntoPrevious = 0.5;

    // double previousMBWidthCandles = tempMBState.StartIndex() - tempMBState.EndIndex();
    double previousMBHeightPips = OrderHelper::RangeToPips(iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) - iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()));
    // if (previousMBWidthCandles < minMBWidthCandles || previousMBHeightPips > maxMBHeightPips)
    // {
    //     return false;
    // }
    // double percentOfMBPrice = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) -
    //                           ((iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()) - iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex())) * currentMBPercentIntoPrevious);

    if (previousMBHeightPips > maxMBHeightPips || previousMBHeightPips < minMBHeightPips)
    {
        return false;
    }

    // double pipsPerCandle = previousMBHeightPips / previousMBWidthCandles;
    // if (pipsPerCandle < minPipsPerCandle)
    // {
    //     return false;
    // }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    // int zoneImbalance = tempZoneState.StartIndex() - tempZoneState.EntryOffset() - 1;
    // bool furthestInZone = false;
    // if (mSetupType == OP_BUY)
    // {
    //     int lowestIndex = EMPTY;
    //     if (!MQLHelper::GetLowest(mEntrySymbol, mEntryTimeFrame, MODE_LOW, zoneImbalance, entryCandle, false, lowestIndex))
    //     {
    //         RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_LOW);
    //         return false;
    //     }

    //     furthestInZone = lowestIndex == entryCandle;
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     int highestIndex = EMPTY;
    //     if (!MQLHelper::GetHighest(mEntrySymbol, mEntryTimeFrame, MODE_HIGH, zoneImbalance, entryCandle, false, highestIndex))
    //     {
    //         RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_HIGH);
    //         return false;
    //     }

    //     furthestInZone = highestIndex == entryCandle;
    // }

    bool inZone = false;
    bool zoneIsHolding = false;
    int holdingError = EAHelper::MostRecentMBZoneIsHolding<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, zoneIsHolding);

    bool doji = false;
    bool potentialDoji = false;
    bool brokeCandle = false;
    bool furthestCandle = false;

    bool impulseIntoZone = false;
    bool impulseOutOfZone = false;

    int dojiCandleIndex = 2;
    double minBodyPercent = 0.7;

    if (mSetupType == OP_BUY)
    {
        // potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle) > iLow(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) &&
        //                 iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandle + 1);

        doji = SetupHelper::HammerCandleStickPattern(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex);
        if (!doji)
        {
            return false;
        }

        inZone = iLow(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex) < tempZoneState.EntryPrice() &&
                 MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex), iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex) > tempZoneState.ExitPrice());

        // make sure zone is within mb
        if (tempZoneState.EntryPrice() > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        {
            return false;
        }

        brokeCandle = iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1) > iHigh(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex);
        if (!brokeCandle)
        {
            return false;
        }

        double totalLength = iHigh(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1) - iLow(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1);
        double bodyLength = iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1) - iOpen(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1);

        if (bodyLength / totalLength < minBodyPercent)
        {
            return false;
        }

        // want an imbalance push into the zone
        int firstIndexIntoZone = EMPTY;
        for (int i = dojiCandleIndex + 3; i > dojiCandleIndex; i--)
        {
            if (iLow(mEntrySymbol, mEntryTimeFrame, i) <= tempZoneState.EntryPrice() && iLow(mEntrySymbol, mEntryTimeFrame, i + 1) > tempZoneState.EntryPrice())
            {
                firstIndexIntoZone = i;
                break;
            }
        }

        // we've been in the zone for more than 4 candles, don't enter
        if (firstIndexIntoZone == EMPTY)
        {
            return false;
        }

        // we won't have an imbalance since we just broke above it. We'll check the previuos candle before instead
        if (firstIndexIntoZone == dojiCandleIndex + 1)
        {
            firstIndexIntoZone += 1;
        }

        impulseIntoZone = iLow(mEntrySymbol, mEntryTimeFrame, firstIndexIntoZone + 1) > iHigh(mEntrySymbol, mEntryTimeFrame, firstIndexIntoZone - 1);
        // make sure zone is below 50% of mb
        // if (tempZoneState.EntryPrice() > percentOfMBPrice)
        // {
        //     return false;
        // }

        // int currentBullishRetracementIndex = EMPTY;
        // if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(currentBullishRetracementIndex))
        // {
        //     return false;
        // }

        // we need to enter the previous MB within 3 candles
        // if (tempMBState.EndIndex() - currentBullishRetracementIndex > 3)
        // {
        //     return false;
        // }

        // int lowestIndex = EMPTY;
        // if (!MQLHelper::GetLowestIndexBetween(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex, 1, true, lowestIndex))
        // {
        //     return false;
        // }

        // double lowest = -1.0;
        // if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex, 1, true, lowest))
        // {
        //     return false;
        // }

        // if (lowest > iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex()))
        // {
        //     return false;
        // }

        // make sure we pushed at least 50% into the MB
        // if (lowest > percentOfMBPrice)
        // {
        //     return hasTicket;
        // }

        // make sure we pushed 50% into the previous MB
        // if (lowest > percentOfMBPrice)
        // {
        //     return hasTicket;
        // }
        // make sure pending MB is within height
        // double pendingMBHeight = iHigh(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex) - lowest;
        // if (pendingMBHeight > maxMBHeight || pendingMBHeight < minMBHeight)
        // {
        //     return false;
        // }
        // if (currentBullishRetracementIndex > maxMBWidth)
        // {
        //     return false;
        // }

        // only allow for 1 bullish candle in the retracemnt into the zone
        // int bullishCandleCount = 0;
        // for (int i = currentBullishRetracementIndex; i > entryCandle; i--)
        // {
        //     if (bullishCandleCount > 1)
        //     {
        //         return false;
        //     }

        //     if (iClose(mEntrySymbol, mEntryTimeFrame, i) > iOpen(mEntrySymbol, mEntryTimeFrame, i))
        //     {
        //         bullishCandleCount += 1;
        //     }
        // }

        // furthestCandle = lowestIndex == entryCandle;
        // brokeCandle = iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2);
        // if (brokeCandle)
        // {
        //     double percentOfPendingMB = iHigh(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex) -
        //                                 ((iHigh(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex) - lowest) * currentMBPercentIntoPrevious);
        //     // don't enter if the candle that broke pushed further than 50% of the mb
        //     if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > percentOfPendingMB)
        //     {
        //         string info = percentOfPendingMB + " ";
        //         RecordError(-6, info);
        //         return hasTicket;
        //     }
        // }

        // bool previousIsBearish = iClose(mEntrySymbol, mEntryTimeFrame, 1) < iOpen(mEntrySymbol, mEntryTimeFrame, 1);
        // bool previousDidNotGoLower = iLow(mEntrySymbol, mEntryTimeFrame, 1) > iLow(mEntrySymbol, mEntryTimeFrame, 2);
        // bool twoPreviousBrokeAbove = iClose(mEntrySymbol, mEntryTimeFrame, 2) > iHigh(mEntrySymbol, mEntryTimeFrame, 3);
        // bool twoPreviousHasImbalance = iHigh(mEntrySymbol, mEntryTimeFrame, 3) < iLow(mEntrySymbol, mEntryTimeFrame, 1);

        // isTrue = previousIsBearish && previousDidNotGoLower && twoPreviousBrokeAbove && twoPreviousHasImbalance;
        // isTrue = previousIsBearish;

        // if (EAHelper::CheckSetSingleMBSetup<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, OP_SELL))
        // {
        //     return true;
        // }
    }
    else if (mSetupType == OP_SELL)
    {
        // potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle) < iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) &&
        //                 iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle + 1);

        doji = SetupHelper::ShootingStarCandleStickPattern(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex);
        if (!doji)
        {
            return false;
        }

        inZone = iHigh(mEntrySymbol, mEntryTimeFrame, 0) > tempZoneState.EntryPrice() &&
                 MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, 0), iClose(mEntrySymbol, mEntryTimeFrame, 0) < tempZoneState.ExitPrice());

        // make sure zone is in mb
        if (tempZoneState.EntryPrice() < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        {
            return false;
        }

        brokeCandle = iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1) < iLow(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex);
        if (!brokeCandle)
        {
            return false;
        }

        double totalLength = iHigh(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1) - iLow(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1);
        double bodyLength = iOpen(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1) - iClose(mEntrySymbol, mEntryTimeFrame, dojiCandleIndex - 1);

        if (bodyLength / totalLength < minBodyPercent)
        {
            return false;
        }

        // want an imbalance push into the zone
        int firstIndexIntoZone = EMPTY;
        for (int i = dojiCandleIndex + 3; i > dojiCandleIndex; i--)
        {
            if (iHigh(mEntrySymbol, mEntryTimeFrame, i) >= tempZoneState.EntryPrice() && iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) < tempZoneState.EntryPrice())
            {
                firstIndexIntoZone = i;
                break;
            }
        }

        // we've been in the zone for more than 4 candles, don't enter
        if (firstIndexIntoZone == EMPTY)
        {
            return false;
        }

        // we won't have an imbalance since we just broke above it. We'll check the previuos candle before instead
        if (firstIndexIntoZone == dojiCandleIndex + 1)
        {
            firstIndexIntoZone += 1;
        }

        impulseIntoZone = iHigh(mEntrySymbol, mEntryTimeFrame, firstIndexIntoZone + 1) < iLow(mEntrySymbol, mEntryTimeFrame, firstIndexIntoZone - 1);

        // make sure zone is below 50% of mb
        // if (tempZoneState.EntryPrice() < percentOfMBPrice)
        // {
        //     RecordError(-2);
        //     return false;
        // }

        // int currentBearishRetracementIndex = EMPTY;
        // if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(currentBearishRetracementIndex))
        // {
        //     return false;
        // }

        // if (tempMBState.EndIndex() - currentBearishRetracementIndex > 3)
        // {
        //     return false;
        // }

        // double highest = -1.0;
        // if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, currentBearishRetracementIndex, 1, true, highest))
        // {
        //     return false;
        // }

        // if (highest < iLow(mEntrySymbol, mEntryTimeFrame, tempMBState.LowIndex()))
        // {
        //     return false;
        // }

        // if (highest < percentOfMBPrice)
        // {
        //     return hasTicket;
        // }

        // // make sure pending MB is within height
        // double pendingMBHeight = highest - iLow(mEntrySymbol, mEntryTimeFrame, currentBearishRetracementIndex);
        // if (pendingMBHeight > maxMBHeight || pendingMBHeight < minMBHeight)
        // {
        //     return false;
        // }

        // if (currentBearishRetracementIndex > maxMBWidth)
        // {
        //     return false;
        // }

        // int lowestIndex = EMPTY;
        // if (!MQLHelper::GetHighestIndexBetween(mEntrySymbol, mEntryTimeFrame, currentBearishRetracementIndex, 1, true, lowestIndex))
        // {
        //     return false;
        // }

        // int bearishCandleCount = 0;
        // for (int i = currentBearishRetracementIndex; i > entryCandle; i--)
        // {
        //     if (bearishCandleCount > 1)
        //     {
        //         return false;
        //     }

        //     if (iClose(mEntrySymbol, mEntryTimeFrame, i) < iOpen(mEntrySymbol, mEntryTimeFrame, i))
        //     {
        //         bearishCandleCount += 1;
        //     }
        // }

        // furthestCandle = lowestIndex == entryCandle;
        // brokeCandle = iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2);
        // if (brokeCandle)
        // {
        //     double percentOfPendingMB = highest - ((highest - iLow(mEntrySymbol, mEntryTimeFrame, currentBearishRetracementIndex)) * currentMBPercentIntoPrevious);
        //     // don't enter if the candle that broke pushed further than 50% of the mb
        //     if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < percentOfPendingMB)
        //     {
        //         return hasTicket;
        //     }
        // }

        // bool previousIsBullish = iClose(mEntrySymbol, mEntryTimeFrame, 1) > iOpen(mEntrySymbol, mEntryTimeFrame, 1);
        // bool previousDidNotGoHigher = iHigh(mEntrySymbol, mEntryTimeFrame, 1) < iHigh(mEntrySymbol, mEntryTimeFrame, 2);
        // bool twoPreviousBrokeBelow = iClose(mEntrySymbol, mEntryTimeFrame, 2) < iLow(mEntrySymbol, mEntryTimeFrame, 3);
        // bool twoPreviousHasImbalance = iLow(mEntrySymbol, mEntryTimeFrame, 3) > iHigh(mEntrySymbol, mEntryTimeFrame, 1);

        // isTrue = previousIsBullish;

        // if (EAHelper::CheckSetSingleMBSetup<TheGrannySmith>(this, mSetupMBT, mFirstMBInSetupNumber, OP_BUY))
        // {
        //     return true;
        // }
    }

    // double minWickLength = 18;
    // if (mSetupType == OP_BUY)
    // {
    //     if (MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) - iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) <
    //         minWickLength)
    //     {
    //         return false;
    //     }

    //     if (iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) > tempZoneState.EntryPrice())
    //     {
    //         return false;
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) - MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) < minWickLength)
    //     {
    //         return false;
    //     }

    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) < tempZoneState.EntryPrice())
    //     {
    //         return false;
    //     }
    // }

    // double minPercentChange = 0.4; // Nas 15 min
    // // double minPercentChange = 0.1; // Currencies & Gold & nas 5 min

    // int zoneImbalance = tempZoneState.StartIndex() - tempZoneState.EntryOffset();
    // double zoneImbalanceChange = MathAbs((iClose(mEntrySymbol, mEntryTimeFrame, zoneImbalance) - iOpen(mEntrySymbol, mEntryTimeFrame, zoneImbalance)) /
    //                                      iClose(mEntrySymbol, mEntryTimeFrame, zoneImbalance));

    // bool hasConfirmation = potentialDoji && inZone && (zoneImbalanceChange >= (minPercentChange / 100));
    // bool hasConfirmation = isTrue;
    // if (hasConfirmation)
    // {
    //     mEntryCandleTime = iTime(Symbol(), Period(), entryCandle);
    //     mStopLossCandleTime = iTime(Symbol(), Period(), entryCandle);
    //     //mEntryMBNumber = tempMBState.Number();
    // }

    return mCurrentSetupTicket.Number() != EMPTY || (inZone && impulseIntoZone);
}

void TheGrannySmith::PlaceOrders()
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

    MBState *mostRecentMB;
    if (!mSetupMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return;
    }

    ZoneState *holdingZone;
    if (!mostRecentMB.GetClosestValidZone(holdingZone))
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
    double stopLossPips = 250; // Nas
    // double stopLossPips = 0.4; // Currencies
    // double stopLossPips = 1.3; // Gold
    // double stopLossPips = 30; // S&P
    double additionalEntryPips = 0;

    // if (mSetupType == OP_BUY)
    // {
    //     // entry = Ask;
    //     // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
    //     // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 0) - OrderHelper::PipsToRange(mStopLossPaddingPips);
    //     // stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     //  entry = Bid;
    //     // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
    //     // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 0) + OrderHelper::PipsToRange(mStopLossPaddingPips + mMaxSpreadPips);
    //     // stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);
    // }

    if (mSetupType == OP_BUY)
    {
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mMaxSpreadPips);
        // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);

        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) >= iHigh(mEntrySymbol, mEntryTimeFrame, 1))
        // {
        //     return;
        // }

        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) /*+ OrderHelper::PipsToRange(additionalEntryPips)*/;
        // stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);

        // if (iLow(mEntrySymbol, mEntryTimeFrame, 0) > entry - OrderHelper::PipsToRange(additionalEntryPips))
        // {
        //     return;
        // }

        // enter after pending doji and new high
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 0);
        // if (entry - iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderHelper::PipsToRange(additionalEntryPips))
        // {
        //     return;
        // }

        // // don't place the order if it is going to activate right away
        // if (currentTick.ask >= entry)
        // {
        //     stopLoss = currentTick.ask - OrderHelper::PipsToRange(stopLossPips); // TODO: Change to bid to account for spread?
        //     // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 0);
        //     EAHelper::PlaceMarketOrder<TheGrannySmith>(this, currentTick.ask, stopLoss);
        //     // return;
        // }

        // Lil Dipper
        // make sure we are low enough before placing the stop order so that we don't automatically execute it
        // if (currentTick.ask >= iHigh(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(additionalEntryPips))
        // {
        //     return;
        // }

        // int currentBullishRetracementIndex = EMPTY;
        // if (!mSetupMBT.CurrentBullishRetracementIndexIsValid(currentBullishRetracementIndex))
        // {
        //     return;
        // }

        // double lowest = -1.0;
        // if (!MQLHelper::GetLowestLowBetween(mEntrySymbol, mEntryTimeFrame, currentBullishRetracementIndex, 1, true, lowest))
        // {
        //     return;
        // }

        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(additionalEntryPips);
        // if (currentTick.ask >= entry)
        // {
        //     return;
        // }

        // stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);
        // stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), iLow(mEntrySymbol, mEntryTimeFrame, 2));
        // stopLoss = MathMin(lowest, entry - OrderHelper::PipsToRange(stopLossPips));
        // stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), entry - OrderHelper::PipsToRange(stopLossPips));

        // MBState *tempMBState;
        // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        // {
        //     return;
        // }

        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, tempMBState.HighIndex());
        // stopLoss = entry - OrderHelper::PipsToRange(stopLossPips);

        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 2);
        EAHelper::PlaceMarketOrder<TheGrannySmith>(this, currentTick.ask, stopLoss);
    }
    else if (mSetupType == OP_SELL)
    {
        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mMaxSpreadPips);
        // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1);

        // if (iLow(mEntrySymbol, mEntryTimeFrame, 0) <= iLow(mEntrySymbol, mEntryTimeFrame, 1))
        // {
        //     return;
        // }

        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) /*- OrderHelper::PipsToRange(additionalEntryPips)*/;
        // stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);

        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) < entry + OrderHelper::PipsToRange(additionalEntryPips))
        // {
        //     return;
        // }

        // enter after potential doji and then creating a new low
        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 0);
        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) - entry < OrderHelper::PipsToRange(additionalEntryPips))
        // {
        //     return;
        // }

        // if (currentTick.bid <= entry)
        // {
        //     stopLoss = currentTick.bid + OrderHelper::PipsToRange(stopLossPips);
        //     // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 0);
        //     EAHelper::PlaceMarketOrder<TheGrannySmith>(this, currentTick.bid, stopLoss);
        //     // return;
        // }

        // Lil Dipper
        // make sure we are low enough before placing the stop order so that we don't automatically execute it
        // if (currentTick.bid <= iLow(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(additionalEntryPips))
        // {
        //     return;
        // }

        // int currentBearishRetracementIndex = EMPTY;
        // if (!mSetupMBT.CurrentBearishRetracementIndexIsValid(currentBearishRetracementIndex))
        // {
        //     return;
        // }

        // if (tempMBState.EndIndex() - currentBearishRetracementIndex > 3)
        // {
        //     return false;
        // }

        // double highest = -1.0;
        // if (!MQLHelper::GetHighestHighBetween(mEntrySymbol, mEntryTimeFrame, currentBearishRetracementIndex, 1, true, highest))
        // {
        //     return;
        // }

        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(additionalEntryPips);
        // if (currentTick.bid <= entry)
        // {
        //     return;
        // }

        // stopLoss = entry + OrderHelper::PipsToRange(stopLossPips);
        // stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), iHigh(mEntrySymbol, mEntryTimeFrame, 2));
        // stopLoss = MathMax(highest, entry + OrderHelper::PipsToRange(stopLossPips));
        // stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), entry + OrderHelper::PipsToRange(stopLossPips));

        // MBState *tempMBState;
        // if (!mSetupMBT.GetMB(mFirstMBInSetupNumber, tempMBState))
        // {
        //     return;
        // }

        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 2);
        EAHelper::PlaceMarketOrder<TheGrannySmith>(this, currentTick.bid, stopLoss);
    }

    // double lotSize = OrderHelper::GetLotSize(stopLossPips, RiskPercent());
    // int ticket = OrderSend(mEntrySymbol, mSetupType, 0.01, entry, 0, stopLoss, 0, NULL, MagicNumber(), 0, clrNONE);
    // EAHelper::PostPlaceOrderChecks<TheGrannySmith>(this, ticket, GetLastError());
    //  EAHelper::PlaceStopOrderForCandelBreak<TheGrannySmith>(this, mEntrySymbol, mEntryTimeFrame, mEntryCandleTime, mStopLossCandleTime);
    //  EAHelper::PlaceStopOrderForTheLittleDipper<TheGrannySmith>(this);
    // EAHelper::PlaceStopOrder<TheGrannySmith>(this, entry, stopLoss);

    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastEntryMB = mostRecentMB.Number();
        mLastEntryZone = holdingZone.Number();

        mBarCount = currentBars;
    }
}

void TheGrannySmith::ManageCurrentPendingSetupTicket()
{
    // int entryCandleIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    // if (entryCandleIndex >= 2)
    // {
    //     InvalidateSetup(true);
    // }

    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // if (mSetupType == OP_BUY && entryCandleIndex > 1)
    // {
    //     if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }
    // else if (mSetupType == OP_SELL && entryCandleIndex > 1)
    // {
    //     if (iClose(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandleIndex))
    //     {
    //         InvalidateSetup(true);
    //     }
    // }

    // EAHelper::CheckBrokePastCandle<TheGrannySmith>(this, mEntrySymbol, mEntryTimeFrame, mSetupType, mEntryCandleTime);
    //  EAHelper::CheckEditStopLossForTheLittleDipper<TheGrannySmith>(this);
}

void TheGrannySmith::ManageCurrentActiveSetupTicket()
{
    // Test BE with candle past
    // Test with Trail with candles after they close up to BE
    // EAHelper::MoveToBreakEvenAfterMBValidation<TheGrannySmith>(this, mSetupMBT, mLastEntryMB);
    // EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry<TheGrannySmith>(this, false);
    // EAHelper::CloseIfPriceCrossedTicketOpen<TheGrannySmith>(this, 1);
    // EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this);

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

    // int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);
    // int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    // if (currentBars > mManageCurrentSetupBarCount && entryIndex > 1)
    // {
    //     mManageCurrentSetupBarCount = currentBars;

    //     // close if we didn't have a body that is at least 90% of the candle
    //     if (entryIndex == 2)
    //     {
    //         double minPercentBody = 0.9;
    //         if ((MathAbs(iOpen(mEntrySymbol, mEntryTimeFrame, 1) - iClose(mEntrySymbol, mEntryTimeFrame, 1)) /
    //              (iHigh(mEntrySymbol, mEntryTimeFrame, 1) - iLow(mEntrySymbol, mEntryTimeFrame, 1))) < minPercentBody)
    //         {
    //             mCurrentSetupTicket.Close();
    //             return;
    //         }
    //     }

    //     if (mSetupType == OP_BUY)
    //     {
    //         // close if we fail to go higher
    //         // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) <= iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
    //         // {
    //         //     mCurrentSetupTicket.Close();
    //         //     return;
    //         // }

    //         // close if we break below a candle
    //         // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, 2))
    //         // {
    //         //     mCurrentSetupTicket.Close();
    //         //     return;
    //         // }

    //         // move to BE if we moved more than 50 pips
    //         // if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() + OrderHelper::PipsToRange(250))
    //         // {
    //         //     EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this);
    //         // }
    //     }
    //     else if (mSetupType == OP_SELL)
    //     {
    //         // close if we fail to go lower
    //         // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) >= iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
    //         // {
    //         //     mCurrentSetupTicket.Close();
    //         //     return;
    //         // }

    //         // close if we break above a candle
    //         // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, 2))
    //         // {
    //         //     mCurrentSetupTicket.Close();
    //         //     return;
    //         // }

    //         // BE if we have a candle further the the candle that broke the entry candle (aka basically the second further candle)

    //         // move to BE if we move more than 50 pips
    //         // if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() - OrderHelper::PipsToRange(250))
    //         // {
    //         //     EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this);
    //         // }
    //     }
    // }

    // bool potentialDojiClose = false;
    // if (mSetupType == OP_BUY && entryIndex > 1)
    // {
    //     // close if we put in an opposite doji that gets within 20 pips of our entry
    //     // potentialDojiClose = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
    //     //                      iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
    //     //                      currentTick.bid <= (iHigh(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(0));

    //     // if (potentialDojiClose)
    //     // {
    //     //     mCurrentSetupTicket.Close();
    //     //     return;
    //     // }

    //     // close if we push below our previous candle
    //     // if (iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1))
    //     // {
    //     //     mCurrentSetupTicket.Close();
    //     //     return;
    //     // }

    //     // BE if we push above the candle that entered us in
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex - 1))
    //     {
    //         EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this);
    //     }
    // }
    // else if (mSetupType == OP_SELL && entryIndex > 1)
    // {
    //     // close if we put in an opposite doji that gets within 20 pips of our entry
    //     // potentialDojiClose = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
    //     //                      iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
    //     //                      currentTick.ask >= (iLow(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(0));

    //     // if (potentialDojiClose)
    //     // {
    //     //     mCurrentSetupTicket.Close();
    //     //     return;
    //     // }

    //     // if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1))
    //     // {
    //     //     mCurrentSetupTicket.Close();
    //     //     return;
    //     // }

    //     // BE if we push below the candle that entered us in
    //     if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex - 1))
    //     {
    //         EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this);
    //     }
    // }

    bool movedPips = false;
    double pipsToWaitBeforeBE = 200;
    double beAdditionalPips = 50;
    if (mSetupType == OP_BUY)
    {
        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(pipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(pipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this, beAdditionalPips);
    }
}

bool TheGrannySmith::MoveToPreviousSetupTickets(Ticket &ticket)
{
    // return true;
    return EAHelper::TicketStopLossIsMovedToBreakEven<TheGrannySmith>(this, ticket);
    //  TODO: Switch to never move to previous setup tickets to conform to the FIFO Rule
    //  Not doing it now so that I can see how for most of my trades run
    //  return false;
}

void TheGrannySmith::ManagePreviousSetupTicket(int ticketIndex)
{
    // EAHelper::MoveStopLossToCoverCommissions<TheGrannySmith>(this);
    // int selectError = mPreviousSetupTickets[ticketIndex].SelectIfOpen("Stuff");
    // if (TerminalErrors::IsTerminalError(selectError))
    // {
    //     RecordError(selectError);
    //     return;
    // }

    // MqlTick currentTick;
    // if (!SymbolInfoTick(Symbol(), currentTick))
    // {
    //     RecordError(GetLastError());
    //     return;
    // }

    // bool movedPips = false;
    // if (mSetupType == OP_BUY)
    // {
    //     if (OrderStopLoss() - OrderOpenPrice() >= OrderHelper::PipsToRange(5))
    //     {
    //         return;
    //     }

    //     if (currentTick.bid - OrderStopLoss() >= OrderHelper::PipsToRange(30))
    //     {
    //         OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), currentTick.bid - OrderHelper::PipsToRange(30), 0, NULL, clrNONE);
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (OrderOpenPrice() - OrderStopLoss() >= OrderHelper::PipsToRange(5))
    //     {
    //         return;
    //     }

    //     if (OrderStopLoss() - currentTick.ask >= OrderHelper::PipsToRange(30))
    //     {
    //         OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), currentTick.ask + OrderHelper::PipsToRange(30), 0, NULL, clrNONE);
    //     }
    // }

    EAHelper::CheckPartialPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::CheckCurrentSetupTicket()
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheGrannySmith>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<TheGrannySmith>(this);
}

void TheGrannySmith::CheckPreviousSetupTicket(int ticketIndex)
{
    EAHelper::CheckUpdateHowFarPriceRanFromOpen<TheGrannySmith>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<TheGrannySmith>(this, ticketIndex);
}

void TheGrannySmith::RecordTicketOpenData()
{
    EAHelper::RecordMBEntryTradeRecord<TheGrannySmith>(this, mSetupMBT.MBsCreated() - 1, mSetupMBT, mMBCount, mLastEntryZone);
}

void TheGrannySmith::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<TheGrannySmith>(this, oldTicketIndex, newTicketNumber);
}

void TheGrannySmith::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TheGrannySmith>(this, ticket, Period());
}

void TheGrannySmith::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TheGrannySmith>(this, error, additionalInformation);
}

void TheGrannySmith::Reset()
{
    mMBCount = 0;
}