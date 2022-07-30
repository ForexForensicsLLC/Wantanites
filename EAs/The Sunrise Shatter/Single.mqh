//+------------------------------------------------------------------+
//|                                      TheSunriseShatterSingle.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>

#include <SummitCapital\Framework\EAs\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>

class TheSunriseShatterSingle : public EA<DefaultTradeRecord>
{
private:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    int mMBStopOrderTicket;
    int mSetupType;
    int mFirstMBInSetupNumber;

public:
    TheSunriseShatterSingle(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                            MBTracker *&mbt);
    ~TheSunriseShatterSingle();

    static int MagicNumber;

    virtual void FillStrategyMagicNumbers();

    virtual void RecordPreOrderOpenData();
    virtual void RecordPostOrderOpenData();
    virtual void CheckRecordOrderCloseData();

    virtual void Manage();
    virtual void CheckInvalidateSetup();
    virtual bool AllowedToTrade();
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void CheckSetSetup();
    virtual void Reset();
    virtual void Run();
};

static int TheSunriseShatterSingle::MagicNumber = 10003;

TheSunriseShatterSingle::TheSunriseShatterSingle(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TSSS/";
    mCSVFileName = "TSSS.csv";

    mMRFTS = mrfts;
    mMBT = mbt;

    FillStrategyMagicNumbers();
}

TheSunriseShatterSingle::~TheSunriseShatterSingle()
{
}

void TheSunriseShatterSingle::FillStrategyMagicNumbers()
{
    ArrayResize(mStrategyMagicNumbers, 3);
    mStrategyMagicNumbers[0] = MagicNumber;
}

void TheSunriseShatterSingle::Manage()
{
    if (mMBStopOrderTicket == EMPTY)
    {
        return;
    }

    bool isPendingOrder = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(mMBStopOrderTicket, isPendingOrder);

    if (isPendingOrder)
    {
        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
            mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, mFirstMBInSetupNumber, mMBT, mMBStopOrderTicket);
    }
    else
    {
        bool succeeeded = false;
        OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(mMBStopOrderTicket, mStopLossPaddingPips, mMaxSpreadPips, mFirstMBInSetupNumber, mSetupType, mMBT, succeeeded);
    }
}

void TheSunriseShatterSingle::CheckInvalidateSetup()
{
    if (!mHasSetup)
    {
        return;
    }

    bool brokeRangeStart = false;
    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mFirstMBInSetupNumber, mMBT, brokeRangeStart);
    bool doubleMB = mMBT.MBIsMostRecent(mFirstMBInSetupNumber + 1) && mMBT.HasNMostRecentConsecutiveMBs(2);

    if (mMRFTS.CrossedOpenPriceAfterMinROC() || brokeRangeStart || doubleMB || brokeRangeError != ERR_NO_ERROR)
    {
        mHasSetup = false;
        mStopTrading = true;

        if (mMBStopOrderTicket == EMPTY)
        {
            return;
        }

        bool isPending = false;
        int pendingOrderError = OrderHelper::IsPendingOrder(mMBStopOrderTicket, isPending);
        if (pendingOrderError == ERR_NO_ERROR && isPending)
        {
            mMBStopOrderTicket = OrderHelper::CancelPendingOrderByTicket(mMBStopOrderTicket);
        }
    }
}

bool TheSunriseShatterSingle::AllowedToTrade()
{
    return mMRFTS.OpenPrice() > 0.0 && (MarketInfo(Symbol(), MODE_SPREAD) / 10) <= mMaxSpreadPips;
}

bool TheSunriseShatterSingle::Confirmation()
{
    bool isTrue = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mFirstMBInSetupNumber, mMBT, isTrue);
    if (confirmationError != ERR_NO_ERROR)
    {
        mHasSetup = false;
        mStopTrading = true;
        return false;
    }

    return isTrue;
}

void TheSunriseShatterSingle::PlaceOrders()
{
    if (mMBStopOrderTicket != EMPTY)
    {
        return;
    }

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

void TheSunriseShatterSingle::RecordPreOrderOpenData()
{
    PendingRecord.AccountBalanceBefore = AccountBalance();
}

void TheSunriseShatterSingle::RecordPostOrderOpenData()
{
    string imageFilePath = "";
    int entryScreenShotError = ScreenShotHelper::TryTakeOrderOpenScreenShot(mMBStopOrderTicket, Directory(), imageFilePath);
    if (entryScreenShotError != ERR_NO_ERROR)
    {
        // TODO: Send Email
        return;
    }

    // TODO: I think this is flawed. This could just be a pending order and not an actual order
    PendingRecord.Symbol = mMBT.Symbol();
    PendingRecord.TimeFrame = mMBT.TimeFrame();
    PendingRecord.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    PendingRecord.EntryTime = OrderOpenTime();
    PendingRecord.EntryImage = imageFilePath;
    PendingRecord.EntryPrice = OrderOpenPrice();
    PendingRecord.EntryStopLoss = OrderStopLoss();
    PendingRecord.Lots = OrderLots();
}

void TheSunriseShatterSingle::CheckRecordOrderCloseData()
{
    string imageFilePath = "";
    int entryScreenShotError = ScreenShotHelper::TryTakeOrderCloseScreenShot(mMBStopOrderTicket, Directory(), imageFilePath);
    if (entryScreenShotError != ERR_NO_ERROR)
    {
        // TODO: Send Email
        return;
    }

    PendingRecord.AccountBalanceAfter = AccountBalance();
    PendingRecord.ExitTime = OrderCloseTime();
    PendingRecord.ExitImage = imageFilePath;
    PendingRecord.ExitPrice = OrderClosePrice();
    PendingRecord.ExitStopLoss = OrderStopLoss();

    CSVRecordWriter<DefaultTradeRecord>::Write();
}

void TheSunriseShatterSingle::CheckSetSetup()
{
    if (mHasSetup)
    {
        return;
    }

    bool isTrue = false;
    int setupError = SetupHelper::BreakAfterMinROC(mMRFTS, mMBT, isTrue);

    if (setupError == Errors::ERR_MB_DOES_NOT_EXIST)
    {
        mStopTrading = true;
        return;
    }

    if (setupError != ERR_NO_ERROR)
    {
        return;
    }

    if (!isTrue)
    {
        return;
    }

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        mStopTrading = true;
        return;
    }

    mFirstMBInSetupNumber = tempMBState.Number();
    mSetupType = tempMBState.Type();
    mHasSetup = true;
}

void TheSunriseShatterSingle::Reset()
{
    mStopTrading = false;
    mHasSetup = false;

    mMBStopOrderTicket = -1;
    mSetupType = -1;
    mFirstMBInSetupNumber = -1;
}

void TheSunriseShatterSingle::Run()
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