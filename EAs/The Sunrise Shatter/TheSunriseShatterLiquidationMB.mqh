//+------------------------------------------------------------------+
//|                               TheSunriseShatterLiquidationMB.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordWriter.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultTradeRecord.mqh>

#include <SummitCapital\Framework\EAs\EA.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>

class TheSunriseShatterLiquidationMB : public EA<DefaultTradeRecord>
{
private:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;

    Ticket *mTicket;
    int mSetupType;
    int mFirstMBInSetupNumber;
    int mSecondMBInSetupNumber;

public:
    TheSunriseShatterLiquidationMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                                   MBTracker *&mbt);
    ~TheSunriseShatterLiquidationMB();

    static int MagicNumber;

    virtual void FillStrategyMagicNumbers();
    virtual void SetActiveTickets();

    virtual void RecordPreOrderOpenData();
    virtual void RecordPostOrderOpenData();
    virtual void RecordOrderCloseData();

    virtual void CheckTicket();
    virtual void Manage();
    virtual void CheckInvalidateSetup();
    virtual void StopTrading(int error);
    virtual bool AllowedToTrade();
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void CheckSetSetup();
    virtual void Reset();
    virtual void Run();
};

static int TheSunriseShatterLiquidationMB::MagicNumber = 10005;

TheSunriseShatterLiquidationMB::TheSunriseShatterLiquidationMB(
    int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts, MBTracker *&mbt)
    : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterLiquidationMB/";
    mCSVFileName = "TheSunriseShatterLiquidationMB.csv";

    mMRFTS = mrfts;
    mMBT = mbt;

    FillStrategyMagicNumbers();
}

TheSunriseShatterLiquidationMB::~TheSunriseShatterLiquidationMB()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterLiquidationMB::FillStrategyMagicNumbers()
{
    ArrayResize(mStrategyMagicNumbers, 3);

    mStrategyMagicNumbers[0] = MagicNumber;
    mStrategyMagicNumbers[1] = TheSunriseShatterSingleMB::MagicNumber;
    mStrategyMagicNumbers[2] = TheSunriseShatterDoubleMB::MagicNumber;
}

void TheSunriseShatterLiquidationMB::SetActiveTickets()
{
    int tickets[];
    int findTicketsError = OrderHelper::FindActiveTicketsByMagicNumber(MagicNumber, tickets);
    if (findTicketsError != ERR_NO_ERROR)
    {
        EA<DefaultTradeRecord>::RecordError(findTicketsError);
    }

    if (ArraySize(tickets) > 0)
    {
        mTicket.SetNewTicket(tickets[0]);
    }
}

void TheSunriseShatterLiquidationMB::CheckTicket()
{
    bool activated;
    int activatedError = mTicket.WasActivated(activated);
    if (TerminalErrors::IsTerminalError(activatedError))
    {
        StopTrading(activatedError);
        return;
    }

    if (activated)
    {
        RecordPostOrderOpenData();
    }

    bool closed;
    int closeError = mTicket.WasClosed(closed);
    if (TerminalErrors::IsTerminalError(closeError))
    {
        StopTrading(closeError);
        return;
    }

    if (closed)
    {
        RecordOrderCloseData();
        CSVRecordWriter<DefaultTradeRecord>::Write();
    }
}

void TheSunriseShatterLiquidationMB::Manage()
{
    mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (mTicket.Number() == EMPTY)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_PENDING_ORDER;

    bool isActive;
    int isActiveError = mTicket.IsActive(isActive);
    if (TerminalErrors::IsTerminalError(isActiveError))
    {
        StopTrading(isActiveError);
        return;
    }

    if (!isActive)
    {
        mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
            mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, mSecondMBInSetupNumber, mMBT, mTicket);

        if (TerminalErrors::IsTerminalError(editStopLossError))
        {
            StopTrading(editStopLossError);
            return;
        }
    }
    else
    {
        mLastState = EAStates::CHECKING_TO_TRAIL_STOP_LOSS;

        bool succeeeded = false;
        int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(
            mStopLossPaddingPips, mMaxSpreadPips, mSecondMBInSetupNumber, mSetupType, mMBT, mTicket, succeeeded);

        if (TerminalErrors::IsTerminalError(trailError))
        {
            StopTrading(trailError);
            return;
        }
    }
}

void TheSunriseShatterLiquidationMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (!mHasSetup)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;

    if (mMRFTS.CrossedOpenPriceAfterMinROC())
    {
        StopTrading();
        return;
    }

    mLastState = EAStates::CHECKING_IF_BROKE_RANGE_START;
    bool brokeRangeStart;
    int brokeRangeStartError = SetupHelper::BrokeMBRangeStart(mFirstMBInSetupNumber, mMBT, brokeRangeStart);
    if (TerminalErrors::IsTerminalError(brokeRangeStartError))
    {
        StopTrading(brokeRangeStartError);
        return;
    }

    if (brokeRangeStart)
    {
        StopTrading();
        return;
    }

    mLastState = EAStates::CHECKING_IF_BROKE_RANGE_END;

    bool brokeRangeEnd;
    int brokeRangeEndError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(mSecondMBInSetupNumber, mSetupType, mMBT, brokeRangeEnd);
    if (brokeRangeEndError != ERR_NO_ERROR)
    {
        return;
    }

    if (brokeRangeEnd)
    {
        StopTrading();
        return;
    }
}

void TheSunriseShatterLiquidationMB::StopTrading(int error = ERR_NO_ERROR)
{
    mLastState = EAStates::INVALIDATING_SETUP;

    mHasSetup = false;
    mStopTrading = true;

    if (error != ERR_NO_ERROR)
    {
        EA<DefaultTradeRecord>::RecordError(error);
    }

    if (mTicket.Number() == EMPTY)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_PENDING_ORDER;

    bool isActive = false;
    int isActiveError = mTicket.IsActive(isActive);

    // Only close the order if it is pending or else every active order would get closed
    // as soon as the setup is finished
    if (!isActive)
    {
        mLastState = EAStates::CLOSING_PENDING_ORDER;

        int closeError = mTicket.Close();
        if (TerminalErrors::IsTerminalError(closeError))
        {
            EA<DefaultTradeRecord>::RecordError(closeError);
        }
    }
}

bool TheSunriseShatterLiquidationMB::AllowedToTrade()
{
    mLastState = EAStates::CHECKING_IF_ALLOWED_TO_TRADE;

    return (mMRFTS.OpenPrice() > 0.0 || mHasSetup) && (MarketInfo(Symbol(), MODE_SPREAD) / 10) <= mMaxSpreadPips;
}

bool TheSunriseShatterLiquidationMB::Confirmation()
{
    mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool hasConfirmation = false;
    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(mFirstMBInSetupNumber, mSecondMBInSetupNumber, mMBT, hasConfirmation);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        StopTrading(confirmationError);
        return false;
    }

    return hasConfirmation;
}

void TheSunriseShatterLiquidationMB::PlaceOrders()
{
    if (mTicket.Number() != EMPTY)
    {
        return;
    }

    mLastState = EAStates::COUNTING_OTHER_EA_ORDERS;

    int orders = 0;
    int ordersError = OrderHelper::CountOtherEAOrders(mStrategyMagicNumbers, orders);
    if (ordersError != ERR_NO_ERROR)
    {
        StopTrading(ordersError);
        return;
    }

    if (orders > mMaxTradesPerStrategy)
    {
        StopTrading();
        return;
    }

    RecordPreOrderOpenData();

    mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForBreakOfMB(mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, MagicNumber, mSecondMBInSetupNumber + 1,
                                                                  mMBT, ticketNumber);
    if (ticketNumber == EMPTY)
    {
        PendingRecord.Reset();
        StopTrading(orderPlaceError);

        return;
    }

    mTicket.SetNewTicket(ticketNumber);
}

void TheSunriseShatterLiquidationMB::RecordPreOrderOpenData()
{
    mLastState = EAStates::RECORDING_PRE_ORDER_OPEN_DATA;
    PendingRecord.AccountBalanceBefore = AccountBalance();
}

void TheSunriseShatterLiquidationMB::RecordPostOrderOpenData()
{
    mLastState = EAStates::RECORDING_POST_ORDER_OPEN_DATA;

    string imageName = ScreenShotHelper::TryTakeScreenShot(Directory());

    PendingRecord.Symbol = mMBT.Symbol();
    PendingRecord.TimeFrame = mMBT.TimeFrame();
    PendingRecord.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    PendingRecord.EntryTime = OrderOpenTime();
    PendingRecord.EntryImage = imageName;
    PendingRecord.EntryPrice = OrderOpenPrice();
    PendingRecord.EntryStopLoss = OrderStopLoss();
    PendingRecord.Lots = OrderLots();
}

void TheSunriseShatterLiquidationMB::RecordOrderCloseData()
{
    mLastState = EAStates::RECORDING_POST_ORDER_CLOSE_DATA;

    string imageName = ScreenShotHelper::TryTakeScreenShot(Directory());

    PendingRecord.AccountBalanceAfter = AccountBalance();
    PendingRecord.ExitTime = OrderCloseTime();
    PendingRecord.ExitImage = imageName;
    PendingRecord.ExitPrice = OrderClosePrice();
    PendingRecord.ExitStopLoss = OrderStopLoss();

    CSVRecordWriter<DefaultTradeRecord>::Write();
}

void TheSunriseShatterLiquidationMB::CheckSetSetup()
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
        StopTrading(setupError);
        return;
    }

    if (!isTrue)
    {
        return;
    }

    if (mFirstMBInSetupNumber == EMPTY)
    {
        mLastState = EAStates::GETTING_FIRST_MB_IN_SETUP;

        MBState *mbOneTempState;
        if (!mMBT.GetNthMostRecentMB(0, mbOneTempState))
        {
            StopTrading(TerminalErrors::MB_DOES_NOT_EXIST);
            return;
        }

        mFirstMBInSetupNumber = mbOneTempState.Number();
    }
    else if (mSecondMBInSetupNumber == EMPTY)
    {
        MBState *mbTwoTempState;
        if (!mMBT.GetSubsequentMB(mFirstMBInSetupNumber, mbTwoTempState))
        {
            return;
        }

        mSecondMBInSetupNumber = mbTwoTempState.Number();
        mSetupType = mbTwoTempState.Type();
    }
    else
    {
        MBState *mbThreeTempState;
        if (!mMBT.GetSubsequentMB(mSecondMBInSetupNumber, mbThreeTempState))
        {
            return;
        }

        if (mbThreeTempState.Type() == mSetupType)
        {
            StopTrading();
            return;
        }

        mHasSetup = true;
    }
}

void TheSunriseShatterLiquidationMB::Reset()
{
    mLastState = EAStates::RESETING;

    mStopTrading = false;
    mHasSetup = false;

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
    mSecondMBInSetupNumber = EMPTY;
}

void TheSunriseShatterLiquidationMB::Run()
{
    mMBT.DrawNMostRecentMBs(1);
    mMBT.DrawZonesForNMostRecentMBs(1);
    mMRFTS.Draw();

    CheckTicket();
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
