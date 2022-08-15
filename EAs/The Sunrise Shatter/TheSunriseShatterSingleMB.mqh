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
#include <SummitCapital\Framework\Objects\Ticket.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>

class TheSunriseShatterSingleMB : public EA<DefaultTradeRecord>
{
private:
    MinROCFromTimeStamp *mMRFTS;
    MBTracker *mMBT;
    Ticket *mTicket;

    int mSetupType;
    int mFirstMBInSetupNumber;

public:
    TheSunriseShatterSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent, MinROCFromTimeStamp *&mrfts,
                              MBTracker *&mbt);
    ~TheSunriseShatterSingleMB();

    static int MagicNumber;
    int FirstMBInSetupNumber() { return mFirstMBInSetupNumber; }
    int TicketNumber() { return mTicket.Number(); }

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

static int TheSunriseShatterSingleMB::MagicNumber = 10003;

TheSunriseShatterSingleMB::TheSunriseShatterSingleMB(int maxTradesPerStrategy, int stopLossPaddingPips, int maxSpreadPips, double riskPercent,
                                                     MinROCFromTimeStamp *&mrfts, MBTracker *&mbt) : EA(maxTradesPerStrategy, stopLossPaddingPips, maxSpreadPips, riskPercent)
{
    mDirectory = "/TheSunriseShatter/TheSunriseShatterSingleMB/";
    mCSVFileName = "TheSunriseShatterSingleMB.csv";

    mMBT = mbt;
    mMRFTS = mrfts;
    mTicket = new Ticket();

    FillStrategyMagicNumbers();
    SetActiveTickets();
}

TheSunriseShatterSingleMB::~TheSunriseShatterSingleMB()
{
    delete mMBT;
    delete mMRFTS;
    delete mTicket;
}

void TheSunriseShatterSingleMB::FillStrategyMagicNumbers()
{
    ArrayResize(mStrategyMagicNumbers, 3);

    mStrategyMagicNumbers[0] = MagicNumber;
    mStrategyMagicNumbers[1] = TheSunriseShatterDoubleMB::MagicNumber;
    mStrategyMagicNumbers[2] = TheSunriseShatterLiquidationMB::MagicNumber;
}

void TheSunriseShatterSingleMB::SetActiveTickets()
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

void TheSunriseShatterSingleMB::CheckTicket()
{
    if (mTicket.Number() == EMPTY)
    {
        return;
    }

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

void TheSunriseShatterSingleMB::Manage()
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
            mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, mFirstMBInSetupNumber, mMBT, mTicket);

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
            mStopLossPaddingPips, mMaxSpreadPips, mFirstMBInSetupNumber, mSetupType, mMBT, mTicket, succeeeded);

        if (TerminalErrors::IsTerminalError(trailError))
        {
            StopTrading(trailError);
            return;
        }
    }
}

void TheSunriseShatterSingleMB::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (!mHasSetup)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_MOST_RECENT_MB;

    // don't have to check for broken start range or if the next mb is the same type.
    // The setup is invalid if ANY mb gets printed after the first
    if (!mMBT.MBIsMostRecent(mFirstMBInSetupNumber))
    {
        StopTrading();
        return;
    }

    mLastState = EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;

    if (mMRFTS.CrossedOpenPriceAfterMinROC())
    {
        StopTrading();
    }
}

void TheSunriseShatterSingleMB::StopTrading(int error = ERR_NO_ERROR)
{
    mLastState = EAStates::INVALIDATING_SETUP;

    mHasSetup = false;
    mStopTrading = true;

    if (mTicket.Number() == EMPTY)
    {
        return;
    }

    if (error != ERR_NO_ERROR)
    {
        EA<DefaultTradeRecord>::RecordError(error);
    }

    mLastState = EAStates::CHECKING_IF_PENDING_ORDER;

    bool isActive = false;
    int isActiveError = mTicket.IsActive(isActive);

    // Only close the order if it is pending or else every active order wouls get closed
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

bool TheSunriseShatterSingleMB::AllowedToTrade()
{
    mLastState = EAStates::CHECKING_IF_ALLOWED_TO_TRADE;

    return (mMRFTS.OpenPrice() > 0.0 || mHasSetup) && (MarketInfo(Symbol(), MODE_SPREAD) / 10) <= mMaxSpreadPips;
}

bool TheSunriseShatterSingleMB::Confirmation()
{
    mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool isTrue = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mFirstMBInSetupNumber, mMBT, isTrue);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        StopTrading(confirmationError);
        return false;
    }

    return isTrue;
}

void TheSunriseShatterSingleMB::PlaceOrders()
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
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingMBValidation(mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, MagicNumber, mFirstMBInSetupNumber,
                                                                            mMBT, ticketNumber);
    if (ticketNumber == EMPTY)
    {
        PendingRecord.Reset();
        StopTrading(orderPlaceError);

        return;
    }

    mTicket.SetNewTicket(ticketNumber);
}

void TheSunriseShatterSingleMB::RecordPreOrderOpenData()
{
    mLastState = EAStates::RECORDING_PRE_ORDER_OPEN_DATA;
    PendingRecord.AccountBalanceBefore = AccountBalance();
}

void TheSunriseShatterSingleMB::RecordPostOrderOpenData()
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

void TheSunriseShatterSingleMB::RecordOrderCloseData()
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
        StopTrading(setupError);
        return;
    }

    if (!isTrue)
    {
        return;
    }

    mLastState = EAStates::GETTING_FIRST_MB_IN_SETUP;

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        StopTrading(TerminalErrors::MB_DOES_NOT_EXIST);
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

    mSetupType = -1;
    mFirstMBInSetupNumber = -1;
}

void TheSunriseShatterSingleMB::Run()
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