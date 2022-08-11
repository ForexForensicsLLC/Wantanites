//+------------------------------------------------------------------+
//|                                      TheSunriseShatterSingleMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>

#include <SummitCapital\Framework\EAs\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>

class TheSunriseShatterSingleMB : public EA<DefaultTradeRecord>
{
private:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mMBStopOrderTicket;
    int mSetupType;
    int mFirstMBInSetupNumber;

public:
    TheSunriseShatterSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                              MBTracker *&mbt);
    ~TheSunriseShatterSingleMB();

    static int MagicNumber;

    virtual void FillStrategyMagicNumbers();

    virtual void RecordPreOrderOpenData();
    virtual void RecordPostOrderOpenData();
    virtual void CheckRecordOrderCloseData();

    virtual void Manage();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup();
    virtual bool AllowedToTrade();
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void CheckSetSetup();
    virtual void Reset();
    virtual void Run();
};

static int TheSunriseShatterSingleMB::MagicNumber = 10003;

TheSunriseShatterSingleMB::TheSunriseShatterSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                                     MinROCFromTimeStamp *&mrfts, MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterSingleMB/";
    mCSVFileName = "TheSunriseShatterSingleMB.csv";

    mMRFTS = mrfts;
    mMBT = mbt;

    FillStrategyMagicNumbers();
}

TheSunriseShatterSingleMB::~TheSunriseShatterSingleMB()
{
}

void TheSunriseShatterSingleMB::FillStrategyMagicNumbers()
{
    ArrayResize(mStrategyMagicNumbers, 3);

    mStrategyMagicNumbers[0] = MagicNumber;
    mStrategyMagicNumbers[1] = TheSunriseShatterDoubleMB::MagicNumber;
    mStrategyMagicNumbers[2] = TheSunriseShatterLiquidationMB::MagicNumber;
}

void TheSunriseShatterSingleMB::Manage()
{
    mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (mMBStopOrderTicket == EMPTY)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_PENDING_ORDER;

    bool isPendingOrder = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(mMBStopOrderTicket, isPendingOrder);
    if (TerminalErrors::IsTerminalError(pendingOrderError))
    {
        EA<DefaultTradeRecord>::RecordError(pendingOrderError);
        mStopTrading = true;

        return;
    }

    if (isPendingOrder)
    {
        mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
            mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, mFirstMBInSetupNumber, mMBT, mMBStopOrderTicket);

        if (TerminalErrors::IsTerminalError(editStopLossError))
        {
            EA<DefaultTradeRecord>::RecordError(editStopLossError);
            mStopTrading = true;
        }
    }
    else
    {
        mLastState = EAStates::CHECKING_TO_TRAIL_STOP_LOSS;

        bool succeeeded = false;
        int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(
            mMBStopOrderTicket, mStopLossPaddingPips, mMaxSpreadPips, mFirstMBInSetupNumber, mSetupType, mMBT, succeeeded);

        if (TerminalErrors::IsTerminalError(trailError))
        {
            EA<DefaultTradeRecord>::RecordError(trailError);
            mStopTrading = true;
        }
    }
}
// TODO: Split this up into InvalidSetup() and InvalidateSetup()
void TheSunriseShatterSingleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (!mHasSetup)
    {
        return;
    }

    // don't have to check for broken start range or if the next mb is the same type
    // the setup is invalid if ANY mb gets printed after the set up
    mLastState = EAStates::CHECKING_IF_MOST_RECENT_MB;
    if (!MBT.MBIsMostRecent(mFirstMBInSetupNumber))
    {
        InvalidateSetup();
        return;
    }

    /*
    mLastState = EAStates::CHECKING_IF_BROKE_RANGE_START;

    bool brokeRange = false;
    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mFirstMBInSetupNumber, mMBT, brokeRange);
    if (TerminalErrors::IsTerminalError(brokeRangeError))
    {
        EA<DefaultTradeRecord>::RecordError(brokeRangeError);
        mStopTrading = true;

        return;
    }

    if (brokeRange)
    {
        InvalidateSetup();
        return;
    }

    mLastState = EAStates::CHECKING_FOR_SAME_TYPE_SUBSEQUENT_MB;

    bool sameTypeSubsequentMB = false;
    SetupHelper::SameTypeSubsequentMB(mFirstMBInSetupNumber, mMBT, sameTypeSubsequentMB);

    if (sameTypeSubsequentMB)
    {
        InvalidateSetup();
        return;
    }
    */

    mLastState = EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;

    if (mMRFTS.CrossedOpenPriceAfterMinROC())
    {
        InvalidateSetup();
    }
}

void TheSunriseShatterSingleMB::InvalidateSetup()
{
    mLastState = EAStates::INVALIDATING_SETUP;

    mHasSetup = false;
    mStopTrading = true;

    if (mMBStopOrderTicket == EMPTY)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_PENDING_ORDER;

    bool isPending = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(mMBStopOrderTicket, isPending);

    if (TerminalErrors::IsTerminalError(pendingOrderError))
    {
        EA<DefaultTradeRecord>::RecordError(pendingOrderError);
    }

    if (isPending)
    {
        mLastState = EAStates::CANCELING_PENDING_ORDER;

        int cancelPendingOrderError = OrderHelper::CancelPendingOrderByTicket(mMBStopOrderTicket);
        if (TerminalErrors::IsTerminalError(cancelPendingOrderError))
        {
            EA<DefaultTradeRecord>::RecordError(cancelPendingOrderError);
        }
    }
}

bool TheSunriseShatterSingleMB::AllowedToTrade()
{
    mLastState = EAStates::CHECKING_IF_ALLOWED_TO_TRADE;

    return mMRFTS.OpenPrice() > 0.0 && (MarketInfo(Symbol(), MODE_SPREAD) / 10) <= mMaxSpreadPips;
}

bool TheSunriseShatterSingleMB::Confirmation()
{
    mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool isTrue = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mFirstMBInSetupNumber, mMBT, isTrue);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        mHasSetup = false;
        mStopTrading = true;

        return false;
    }

    return isTrue;
}

void TheSunriseShatterSingleMB::PlaceOrders()
{
    if (mMBStopOrderTicket != EMPTY)
    {
        return;
    }

    mLastState = EAStates::COUNTING_OTHER_EA_ORDERS;

    int orders = 0;
    int ordersError = OrderHelper::CountOtherEAOrders(mStrategyMagicNumbers, orders);
    if (ordersError != ERR_NO_ERROR)
    {
        mHasSetup = false;
        mStopTrading = true;
        return;
    }

    if (orders > mMaxTradesPerStrategy)
    {
        mHasSetup = false;
        mStopTrading = true;
        return;
    }

    RecordPreOrderOpenData();

    mLastState = EAStates::PLACING_ORDER;

    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingMBValidation(mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, MagicNumber, mFirstMBInSetupNumber,
                                                                            mMBT, mMBStopOrderTicket);
    if (mMBStopOrderTicket == EMPTY)
    {
        PendingRecord.Reset();
        mHasSetup = false;
        mStopTrading = true;

        return;
    }

    RecordPostOrderOpenData();
}

void TheSunriseShatterSingleMB::RecordPreOrderOpenData()
{
    mLastState = EAStates::RECORDING_PRE_ORDER_OPEN_DATA;
    PendingRecord.AccountBalanceBefore = AccountBalance();
}

void TheSunriseShatterSingleMB::RecordPostOrderOpenData()
{
    mLastState = EAStates::RECORDING_POST_ORDER_OPEN_DATA;

    string imageName = "";
    ScreenShotHelper::TryTakeScreenShot(Directory(), imageName);

    // TODO: I think this is flawed. This could just be a pending order and not an actual order
    PendingRecord.Symbol = mMBT.Symbol();
    PendingRecord.TimeFrame = mMBT.TimeFrame();
    PendingRecord.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    PendingRecord.EntryTime = OrderOpenTime();
    PendingRecord.EntryImage = imageName;
    PendingRecord.EntryPrice = OrderOpenPrice();
    PendingRecord.EntryStopLoss = OrderStopLoss();
    PendingRecord.Lots = OrderLots();
}

void TheSunriseShatterSingleMB::CheckRecordOrderCloseData()
{
    mLastState = EAStates::RECORDING_POST_ORDER_CLOSE_DATA;

    string imageName = "";
    ScreenShotHelper::TryTakeScreenShot(Directory(), imageName);

    PendingRecord.AccountBalanceAfter = AccountBalance();
    PendingRecord.ExitTime = OrderCloseTime();
    PendingRecord.ExitImage = imageName;
    PendingRecord.ExitPrice = OrderClosePrice();
    PendingRecord.ExitStopLoss = OrderStopLoss();

    CSVRecordWriter<DefaultTradeRecord>::Write();
}

void TheSunriseShatterSingleMB::CheckSetSetup()
{
    mLastState = EAStates::CHECKING_FOR_SETUP;

    if (mHasSetup)
    {
        return;
    }

    mLastState = EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC;

    bool isTrue = false;
    int setupError = SetupHelper::BreakAfterMinROC(mMRFTS, mMBT, isTrue);
    if (TerminalErrors::IsTerminalError(setupError))
    {
        EA<DefaultTradeRecord>::RecordError(setupError);
        mStopTrading = true;
        mHasSetup = false;

        return;
    }

    if (!isTrue)
    {
        return;
    }

    mLastState = EAStates::GETTING_NTH_MOST_RECENT_MB;

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        EA<DefaultTradeRecord>::RecordError(setupError);
        mStopTrading = true;
        mHasSetup = false;

        return;
    }

    mFirstMBInSetupNumber = tempMBState.Number();
    mSetupType = tempMBState.Type();
    mHasSetup = true;
}

void TheSunriseShatterSingleMB::Reset()
{
    mLastState = EAStates::RESETING;

    mStopTrading = false;
    mHasSetup = false;

    mMBStopOrderTicket = -1;
    mSetupType = -1;
    mFirstMBInSetupNumber = -1;
}

void TheSunriseShatterSingleMB::Run()
{
    mMBT.DrawNMostRecentMBs(1);
    mMBT.DrawZonesForNMostRecentMBs(1);
    mMRFTS.Draw();

    CheckRecordOrderCloseData();
    Manage();
    CheckInvalidateSetup();

    if (!AllowedToTrade())
    {
        if (!mWasReset)
        {
            Reset();
            mWasReset = true;
        }

        return;
    }

    if (mStopTrading)
    {
        return;
    }

    if (mHasSetup && Confirmation())
    {
        PlaceOrders();
        return;
    }

    CheckSetSetup();
}