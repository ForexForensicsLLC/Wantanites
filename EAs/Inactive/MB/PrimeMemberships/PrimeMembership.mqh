//+------------------------------------------------------------------+
//|                                                    PrimeMembership.mqh |
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

class PrimeMembership : public EA<SingleTimeFrameEntryTradeRecord, PartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    double mAdditionalEntryPips;
    double mFixedStopLossPips;
    double mPipsToWaitBeforeBE;
    double mBEAdditionalPips;

    int mBarCount;
    int mManageCurrentSetupBarCount;
    int mManageCurrentPendingSetupBarCount;
    int mConfirmationBarCount;

    int mEntryTimeFrame;
    string mEntrySymbol;
    datetime mEntryCandleTime;

    datetime mTempLastPercentChange;
    datetime mLastPercentChange;

    double mStartingAccountBalance;

    datetime mStartTime;

    bool mReachedProfit;
    bool mResetReachedProfit;

public:
    PrimeMembership(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                    CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                    CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter);
    ~PrimeMembership();

    virtual int MagicNumber() { return mSetupType == OP_BUY ? MagicNumbers::NasPrimeBuys : MagicNumbers::NasPrimeSells; }
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

PrimeMembership::PrimeMembership(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips,
                                 double riskPercent,
                                 CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                 CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter,
         exitCSVRecordWriter, errorCSVRecordWriter)
{
    mAdditionalEntryPips = 0.0;
    mFixedStopLossPips = 0.0;
    mPipsToWaitBeforeBE = 0.0;
    mBEAdditionalPips = 0.0;

    mBarCount = 0;
    mManageCurrentSetupBarCount = 0;
    mManageCurrentPendingSetupBarCount = 0;
    mConfirmationBarCount = 0;

    mEntrySymbol = Symbol();
    mEntryTimeFrame = Period();

    mEntryCandleTime = 0;

    mTempLastPercentChange = 0;
    mLastPercentChange = 0;

    mReachedProfit = false;
    mResetReachedProfit = false;

    mStartTime = 0;

    mLargestAccountBalance = 100000;
    mStartingAccountBalance = 100000;

    ArrayResize(mStrategyMagicNumbers, 1);
    mStrategyMagicNumbers[0] = MagicNumber();

    EAHelper::FindSetPreviousAndCurrentSetupTickets<PrimeMembership>(this);
    EAHelper::UpdatePreviousSetupTicketsRRAcquried<PrimeMembership, PartialTradeRecord>(this);
    EAHelper::SetPreviousSetupTicketsOpenData<PrimeMembership, SingleTimeFrameEntryTradeRecord>(this);
}

PrimeMembership::~PrimeMembership()
{
}

double PrimeMembership::RiskPercent()
{
    // double totalPercentLost = (AccountBalance() - mLargestAccountBalance) / mLargestAccountBalance * 100;

    // // we lost 4 %, risk only 0.1% / Trade
    // if (totalPercentLost >= 4)
    // {
    //     return 0.1;
    // }
    // // we lost 3%, risk only 0.25% / trade
    // else if (totalPercentLost >= 3)
    // {
    //     return 0.25;
    // }

    // else, just risk normal amount
    return mRiskPercent;
}

void PrimeMembership::Run()
{
    EAHelper::Run<PrimeMembership>(this);
}

bool PrimeMembership::AllowedToTrade()
{
    // if (Day() == 1 && !mResetReachedProfit)
    // {
    //     mReachedProfit = false;
    //     mStartingAccountBalance = AccountBalance();
    //     mResetReachedProfit = true;
    // }
    // else if (Day() == 2)
    // {
    //     mResetReachedProfit = false;
    // }

    // don't trade past friday at hour 23 since we have to close our positions over the weekend
    if (DayOfWeek() == 5 && Hour() >= 23)
    {
        return false;
    }

    return EAHelper::BelowSpread<PrimeMembership>(this) && EAHelper::WithinTradingSession<PrimeMembership>(this) /*&& !mReachedProfit*/;
}

void PrimeMembership::CheckSetSetup()
{
    if (mStartTime == 0)
    {
        mStartTime = iTime(mEntrySymbol, mEntryTimeFrame, 0);
    }

    mHasSetup = true;
}

void PrimeMembership::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;
}

void PrimeMembership::InvalidateSetup(bool deletePendingOrder, int error = Errors::NO_ERROR)
{
    EAHelper::InvalidateSetup<PrimeMembership>(this, deletePendingOrder, false, error);
}

bool PrimeMembership::Confirmation()
{
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars <= mConfirmationBarCount)
    {
        return mCurrentSetupTicket.Number() != EMPTY;
    }

    mConfirmationBarCount = currentBars;

    bool doji = false;
    bool potentialDoji = false;
    bool hasOppositeCandle = false;
    // bool hasMinWickLength = false;
    // bool hasMinCandleGap = false;
    // bool wentFurtherThanPreviousCandle = false;

    // bool furtherThanBand = false;
    int entryCandle = 1;

    // double minCandleGapPips = 50;
    // double minWickLengthPips = 50;
    if (mSetupType == OP_BUY)
    {
        // double lowerBand = iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, entryCandle);
        // potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle) > iLow(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) &&
        //                 iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) < iLow(mEntrySymbol, mEntryTimeFrame, entryCandle + 1);
        doji = SetupHelper::HammerCandleStickPattern(mEntrySymbol, mEntryTimeFrame, entryCandle);
        hasOppositeCandle = iClose(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) < iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle + 1);
        // hasMinWickLength = OrderHelper::RangeToPips(
        //                        MathMin(
        //                            iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) -
        //                        iLow(mEntrySymbol, mEntryTimeFrame, entryCandle)) >=
        //                    minWickLengthPips;

        // hasMinCandleGap = OrderHelper::RangeToPips(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle) - iLow(mEntrySymbol, mEntryTimeFrame, entryCandle + 1)) >=
        //                   minCandleGapPips;

        // wentFurtherThanPreviousCandle = OrderHelper::RangeToPips(iLow(
        //                                                              mEntrySymbol, mEntryTimeFrame, entryCandle + 1) -
        //                                                          iLow(mEntrySymbol, mEntryTimeFrame, entryCandle)) >= mAdditionalEntryPips;
        // furtherThanBand = iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) < lowerBand;
    }
    else if (mSetupType == OP_SELL)
    {
        // double upperBand = iBands(mEntrySymbol, mEntryTimeFrame, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, entryCandle);
        // potentialDoji = iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle) < iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) &&
        //                 iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) > iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle + 1);

        doji = SetupHelper::ShootingStarCandleStickPattern(mEntrySymbol, mEntryTimeFrame, entryCandle);
        hasOppositeCandle = iClose(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) > iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle + 1);

        // hasMinWickLength = OrderHelper::RangeToPips(
        //                        iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) -
        //                        MathMax(
        //                            iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle))) >=
        //                    minWickLengthPips;

        // hasMinCandleGap = OrderHelper::RangeToPips(iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle + 1) - iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle)) >=
        //                   minCandleGapPips;

        // wentFurtherThanPreviousCandle = OrderHelper::RangeToPips(iHigh(
        //                                                              mEntrySymbol, mEntryTimeFrame, entryCandle) -
        //                                                          iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle + 1)) >= mAdditionalEntryPips;

        // furtherThanBand = iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) > upperBand;
    }

    // bool hasPercentChange = false;
    // double minPercentChange = 0.75;
    // for (int i = 1; i <= 5; i++)
    // {
    //     double percentChanged = (iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i)) / iClose(mEntrySymbol, mEntryTimeFrame, i);
    //     datetime candleTime = iTime(mEntrySymbol, mEntryTimeFrame, i);

    //     if (mSetupType == OP_BUY)
    //     {
    //         hasPercentChange = percentChanged <= (minPercentChange / 100 * -1);
    //     }
    //     else if (mSetupType == OP_SELL)
    //     {
    //         hasPercentChange = percentChanged >= (minPercentChange / 100);
    //     }

    //     if (hasPercentChange && (candleTime > mLastPercentChange || mLastPercentChange == 0))
    //     {
    //         mTempLastPercentChange = candleTime;
    //         break;
    //     }
    // }

    // double minPercentChange = 0.3; // original: 0.4
    // if (potentialDoji)
    // {
    //     // int startIndex = entryCandle + 2;
    //     // int endIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mStartTime);
    //     int startIndex = 1;
    //     int endIndex = 5;

    //     if (mSetupType == OP_BUY)
    //     {
    //         for (int i = startIndex; i <= endIndex; i++)
    //         {
    //             double percentChanged = (iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i)) / iClose(mEntrySymbol, mEntryTimeFrame, i);
    //             // have opposite percent change
    //             if (percentChanged <= (minPercentChange / 100 * -1))
    //             {
    //                 // have imbalance
    //                 // if (iHigh(mEntrySymbol, mEntryTimeFrame, i + 1) < iLow(mEntrySymbol, mEntryTimeFrame, i - 1))
    //                 // {
    //                 //     // within zone
    //                 //     double zoneStart = iHigh(mEntrySymbol, mEntryTimeFrame, i + 1);
    //                 //     double zoneEnd = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, i + 1), iLow(mEntrySymbol, mEntryTimeFrame, i));

    //                 //     if (iLow(mEntrySymbol, mEntryTimeFrame, entryCandle) <= zoneStart &&
    //                 //         MathMin(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) >= zoneEnd)
    //                 //     {
    //                 //     }
    //                 // }
    //                 int lowestIndex = EMPTY;
    //                 if (!MQLHelper::GetLowest(mEntrySymbol, mEntryTimeFrame, MODE_LOW, i, entryCandle, false, lowestIndex))
    //                 {
    //                     RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_LOW);
    //                     return false;
    //                 }

    //                 return lowestIndex == entryCandle;
    //             }
    //         }
    //     }
    //     else if (mSetupType == OP_SELL)
    //     {
    //         for (int i = startIndex; i <= endIndex; i++)
    //         {
    //             double percentChanged = (iClose(mEntrySymbol, mEntryTimeFrame, i) - iOpen(mEntrySymbol, mEntryTimeFrame, i)) / iClose(mEntrySymbol, mEntryTimeFrame, i);
    //             // have opposite percent change
    //             if (percentChanged >= (minPercentChange / 100))
    //             {
    //                 // have imbalance
    //                 // if (iLow(mEntrySymbol, mEntryTimeFrame, i + 1) > iHigh(mEntrySymbol, mEntryTimeFrame, i - 1))
    //                 // {
    //                 //     // within zone
    //                 //     double zoneStart = iLow(mEntrySymbol, mEntryTimeFrame, i + 1);
    //                 //     double zoneEnd = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, i + 1), iHigh(mEntrySymbol, mEntryTimeFrame, i));

    //                 //     if (iHigh(mEntrySymbol, mEntryTimeFrame, entryCandle) >= zoneStart &&
    //                 //         MathMax(iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle), iClose(mEntrySymbol, mEntryTimeFrame, entryCandle)) <= zoneEnd)
    //                 //     {
    //                 //     }
    //                 // }

    //                 int highestIndex = EMPTY;
    //                 if (!MQLHelper::GetHighest(mEntrySymbol, mEntryTimeFrame, MODE_HIGH, i, entryCandle, false, highestIndex))
    //                 {
    //                     RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_HIGH);
    //                     return false;
    //                 }

    //                 return highestIndex == entryCandle;
    //             }
    //         }
    //     }
    // }

    // double minPercentChange = 0.0;
    // bool hasPercentChange = false;
    // double percentChanged = (iClose(mEntrySymbol, mEntryTimeFrame, entryCandle) - iOpen(mEntrySymbol, mEntryTimeFrame, entryCandle)) /
    //                         iClose(mEntrySymbol, mEntryTimeFrame, entryCandle);
    // if (mSetupType == OP_BUY)
    // {
    //     hasPercentChange = percentChanged >= (minPercentChange / 100);
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     hasPercentChange = percentChanged <= (minPercentChange / 100 * -1);
    // }

    return mCurrentSetupTicket.Number() != EMPTY || (doji && hasOppositeCandle);
}

void PrimeMembership::PlaceOrders()
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
        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1) /*+ OrderHelper::PipsToRange(mAdditionalEntryPips) */;
        // // stopLoss = entry - OrderHelper::PipsToRange(mFixedStopLossPips);

        // // stop order break
        // // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        // // stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);

        // if (iLow(mEntrySymbol, mEntryTimeFrame, 0) > entry - OrderHelper::PipsToRange(mAdditionalEntryPips))
        // {
        //     return;
        // }

        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 0);
        // if (entry - iLow(mEntrySymbol, mEntryTimeFrame, 0) < OrderHelper::PipsToRange(mAdditionalEntryPips))
        // {
        //     return;
        // }

        // don't place the order if it is going to activate right away
        // if (currentTick.ask >= entry)
        // {
        //     // stopLoss = currentTick.ask - OrderHelper::PipsToRange(mFixedStopLossPips); // TODO: Change to bid to account for spread?
        //     // EAHelper::PlaceMarketOrder<PrimeMembership>(this, currentTick.ask, stopLoss);
        //     // return;
        // }

        // Lil Dipper
        // make sure we are low enough before placing the stop order so that we don't automatically execute it
        // if (currentTick.ask >= iHigh(mEntrySymbol, mEntryTimeFrame, 1) - OrderHelper::PipsToRange(mAdditionalEntryPips))
        // {
        //     return;
        // }

        entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = entry - OrderHelper::PipsToRange(mFixedStopLossPips);
        // stopLoss = MathMin(iLow(mEntrySymbol, mEntryTimeFrame, 1), entry - OrderHelper::PipsToRange(mFixedStopLossPips));
        stopLoss = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        if (currentTick.ask >= entry)
        {
            return;
        }
    }
    else if (mSetupType == OP_SELL)
    {
        // entry = iHigh(mEntrySymbol, mEntryTimeFrame, 1) /*- OrderHelper::PipsToRange(mAdditionalEntryPips) */;
        // // stopLoss = entry + OrderHelper::PipsToRange(mFixedStopLossPips);

        // // stop order break
        // // entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        // // stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1);

        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) < entry + OrderHelper::PipsToRange(mAdditionalEntryPips))
        // {
        //     return;
        // }

        // entry = iLow(mEntrySymbol, mEntryTimeFrame, 0);
        // if (iHigh(mEntrySymbol, mEntryTimeFrame, 0) - entry < OrderHelper::PipsToRange(mAdditionalEntryPips))
        // {
        //     return;
        // }

        // if (currentTick.bid <= entry)
        // {
        //     stopLoss = currentTick.bid + OrderHelper::PipsToRange(mFixedStopLossPips);
        //     EAHelper::PlaceMarketOrder<PrimeMembership>(this, currentTick.bid, stopLoss);
        //     // return;
        // }

        // Lil Dipper
        // make sure we are low enough before placing the stop order so that we don't automatically execute it
        // if (currentTick.bid <= iLow(mEntrySymbol, mEntryTimeFrame, 1) + OrderHelper::PipsToRange(mAdditionalEntryPips))
        // {
        //     return;
        // }

        entry = iLow(mEntrySymbol, mEntryTimeFrame, 1);
        // stopLoss = entry + OrderHelper::PipsToRange(mFixedStopLossPips);
        // stopLoss = MathMax(iHigh(mEntrySymbol, mEntryTimeFrame, 1), entry + OrderHelper::PipsToRange(mFixedStopLossPips));
        stopLoss = iHigh(mEntrySymbol, mEntryTimeFrame, 1);
        if (currentTick.bid <= entry)
        {
            return;
        }
    }

    // EAHelper::PlaceStopOrderForTheLittleDipper<PrimeMembership>(this);
    EAHelper::PlaceStopOrder<PrimeMembership>(this, entry, stopLoss);

    // we successfully placed an order
    if (mCurrentSetupTicket.Number() != EMPTY)
    {
        mLastPercentChange = mTempLastPercentChange;
        mBarCount = currentBars;
        mEntryCandleTime = iTime(mEntrySymbol, mEntryTimeFrame, 1);
    }
}

void PrimeMembership::ManageCurrentPendingSetupTicket()
{
    mLastState = -2;
    // if (mCurrentSetupTicket.Number() == EMPTY)
    // {
    //     return;
    // }

    // if (mEntryCandleTime == 0)
    // {
    //     return;
    // }

    // int entryIndex = iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime);

    // // cancel if we don't get entered on the next candle
    // if (entryIndex > 1)
    // {
    //     InvalidateSetup(true);
    //     return;
    // }

    // if (mSetupType == OP_BUY)
    // {
    //     // cancel if we filled the pending imbalance
    //     if (iLow(mEntrySymbol, mEntryTimeFrame, entryIndex - 1) <= iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex + 1))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     // cancel if we filled the pending imbalance
    //     if (iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex - 1) >= iLow(mEntrySymbol, mEntryTimeFrame, entryIndex + 1))
    //     {
    //         InvalidateSetup(true);
    //         return;
    //     }
    // }

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
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars > mManageCurrentPendingSetupBarCount && entryIndex > 1)
    {
        mManageCurrentPendingSetupBarCount = currentBars;

        if (mSetupType == OP_BUY)
        {
            // close if we break above the entry candle
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) < iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
            {
                mCurrentSetupTicket.Close();
                mCurrentSetupTicket.SetNewTicket(EMPTY); // need to set empty here since the framework only resets the ticket if it was already activated
                return;
            }
        }
        else if (mSetupType == OP_SELL)
        {
            // close if we break above the entry candle
            if (iClose(mEntrySymbol, mEntryTimeFrame, 1) > iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
            {
                mCurrentSetupTicket.Close();
                mCurrentSetupTicket.SetNewTicket(EMPTY); // need to set empty here since the framework only resets the ticket if it was already activated
                return;
            }
        }
    }
}

void PrimeMembership::ManageCurrentActiveSetupTicket()
{
    mLastState = -1;
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
    int currentBars = iBars(mEntrySymbol, mEntryTimeFrame);
    if (currentBars > mManageCurrentSetupBarCount && entryIndex > 0)
    {
        mManageCurrentSetupBarCount = currentBars;

        if (mSetupType == OP_BUY)
        {
            // close if we didn't break the candle before our entry
            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) < iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex + 1))
            // {
            //     mCurrentSetupTicket.Close();
            //     return;
            // }
            // close if we fail to go higher
            // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) <= iHigh(mEntrySymbol, mEntryTimeFrame, entryIndex))
            // {
            //     mCurrentSetupTicket.Close();
            //     return;
            // }

            // move to BE if we moved more than 50 pips
            // if (iHigh(mEntrySymbol, mEntryTimeFrame, 1) > OrderOpenPrice() + OrderHelper::PipsToRange(mPipsToWaitBeforeBE))
            // {
            //     EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this, mBEAdditionalPips);
            // }
        }
        else if (mSetupType == OP_SELL)
        {
            // if (iClose(mEntrySymbol, mEntryTimeFrame, entryIndex) > iLow(mEntrySymbol, mEntryTimeFrame, entryIndex + 1))
            // {
            //     mCurrentSetupTicket.Close();
            //     return;
            // }
            // close if we fail to go lower
            // if (iClose(mEntrySymbol, mEntryTimeFrame, 1) >= iLow(mEntrySymbol, mEntryTimeFrame, entryIndex))
            // {
            //     mCurrentSetupTicket.Close();
            //     return;
            // }

            // move to BE if we move more than 50 pips
            // if (iLow(mEntrySymbol, mEntryTimeFrame, 1) < OrderOpenPrice() - OrderHelper::PipsToRange(mPipsToWaitBeforeBE))
            // {
            //     EAHelper::MoveToBreakEvenAsSoonAsPossible<TheGrannySmith>(this, mBEAdditionalPips);
            // }
        }
    }

    bool potentialDojiClose = false;
    if (mSetupType == OP_BUY && entryIndex > 0)
    {
        // close if we put in an opposite doji that gets within 20 pips of our entry
        // potentialDojiClose = iOpen(mEntrySymbol, mEntryTimeFrame, 0) < iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
        //                      iHigh(mEntrySymbol, mEntryTimeFrame, 0) > iHigh(mEntrySymbol, mEntryTimeFrame, 1) &&
        //                      currentTick.bid <= (OrderOpenPrice() + OrderHelper::PipsToRange(mBEAdditionalPips));

        // if (potentialDojiClose)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }
    }
    else if (mSetupType == OP_SELL && entryIndex > 0)
    {
        // close if we put in an opposite doji that gets within 20 pips of our entry
        // potentialDojiClose = iOpen(mEntrySymbol, mEntryTimeFrame, 0) > iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
        //                      iLow(mEntrySymbol, mEntryTimeFrame, 0) < iLow(mEntrySymbol, mEntryTimeFrame, 1) &&
        //                      currentTick.ask >= (OrderOpenPrice() - OrderHelper::PipsToRange(mBEAdditionalPips));

        // if (potentialDojiClose)
        // {
        //     mCurrentSetupTicket.Close();
        //     return;
        // }
    }

    bool movedPips = false;
    if (mSetupType == OP_BUY)
    {
        // if (currentTick.bid - mCurrentSetupTicket.mOriginalStopLoss <= OrderHelper::PipsToRange(150))
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }
    else if (mSetupType == OP_SELL)
    {
        // if (mCurrentSetupTicket.mOriginalStopLoss - currentTick.ask <= OrderHelper::PipsToRange(150))
        // {
        //     mCurrentSetupTicket.Close();
        // }

        movedPips = OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mPipsToWaitBeforeBE);
    }

    if (movedPips)
    {
        EAHelper::MoveToBreakEvenAsSoonAsPossible<PrimeMembership>(this, mBEAdditionalPips);
    }
}

bool PrimeMembership::MoveToPreviousSetupTickets(Ticket &ticket)
{
    mLastState = -3;
    // bool wasActivated = false;
    // int activeError = mCurrentSetupTicket.WasActivated(wasActivated);
    // if (activeError != Errors::NO_ERROR)
    // {
    //     RecordError(activeError);
    //     return false;
    // }

    // return wasActivated;
    return EAHelper::TicketStopLossIsMovedToBreakEven<PrimeMembership>(this, ticket) /*&& iBarShift(mEntrySymbol, mEntryTimeFrame, mEntryCandleTime) >= 1*/;
    // return true;
    // return false;
}

void PrimeMembership::ManagePreviousSetupTicket(int ticketIndex)
{
    mLastState = -4;
    EAHelper::CheckPartialPreviousSetupTicket<PrimeMembership>(this, ticketIndex);

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
    //     if (currentTick.bid - OrderOpenPrice() >= OrderHelper::PipsToRange(mFixedStopLossPips))
    //     {
    //         OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), currentTick.bid - OrderHelper::PipsToRange(mFixedStopLossPips), 0, NULL, clrNONE);
    //     }
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     if (OrderOpenPrice() - currentTick.ask >= OrderHelper::PipsToRange(mFixedStopLossPips))
    //     {
    //         OrderModify(mPreviousSetupTickets[ticketIndex].Number(), OrderOpenPrice(), currentTick.ask + OrderHelper::PipsToRange(mFixedStopLossPips), 0, NULL, clrNONE);
    //     }
    // }

    // double profitTargetPercent = 10;
    // double profitTargetPercentPadding = 0;

    // double currentProfitPercent = (AccountBalance() - mStartingAccountBalance) / AccountBalance() * 100;
    // if (currentProfitPercent >= profitTargetPercent)
    // {
    //     return;
    // }

    // double currentTradeProfitRR = -1.0;
    // if (mSetupType == OP_BUY)
    // {
    //     currentTradeProfitRR = (currentTick.bid - OrderOpenPrice()) / (OrderOpenPrice() - mPreviousSetupTickets[ticketIndex].mOriginalStopLoss);
    // }
    // else if (mSetupType == OP_SELL)
    // {
    //     currentTradeProfitRR = (OrderOpenPrice() - currentTick.ask) / (mPreviousSetupTickets[ticketIndex].mOriginalStopLoss - OrderOpenPrice());
    // }

    // if (currentTradeProfitRR * RiskPercent() >= profitTargetPercent + profitTargetPercentPadding)
    // {
    //     mPreviousSetupTickets[ticketIndex].Close();
    //     mReachedProfit = true;
    // }
}

void PrimeMembership::CheckCurrentSetupTicket()
{
    mLastState = -6;
    if (DayOfWeek() == 5 && Hour() >= 23)
    {
        if (mCurrentSetupTicket.Number() != EMPTY)
        {
            mCurrentSetupTicket.Close();
        }
    }

    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PrimeMembership>(this, mCurrentSetupTicket);
    EAHelper::CheckCurrentSetupTicket<PrimeMembership>(this);
}

void PrimeMembership::CheckPreviousSetupTicket(int ticketIndex)
{
    mLastState = -7;
    if (DayOfWeek() == 5 && Hour() >= 23)
    {
        if (mPreviousSetupTickets[ticketIndex].Number() != EMPTY)
        {
            mPreviousSetupTickets[ticketIndex].Close();
        }
    }

    EAHelper::CheckUpdateHowFarPriceRanFromOpen<PrimeMembership>(this, mPreviousSetupTickets[ticketIndex]);
    EAHelper::CheckPreviousSetupTicket<PrimeMembership>(this, ticketIndex);
}

void PrimeMembership::RecordTicketOpenData()
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<PrimeMembership>(this);
}

void PrimeMembership::RecordTicketPartialData(int oldTicketIndex, int newTicketNumber)
{
    EAHelper::RecordPartialTradeRecord<PrimeMembership>(this, oldTicketIndex, newTicketNumber);
}

void PrimeMembership::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<PrimeMembership>(this, ticket, Period());
}

void PrimeMembership::RecordError(int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<PrimeMembership>(this, error, additionalInformation);
}

void PrimeMembership::Reset()
{
    mStartTime = 0;
}
