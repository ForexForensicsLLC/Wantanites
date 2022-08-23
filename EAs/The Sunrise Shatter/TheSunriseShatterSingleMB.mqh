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
    void Ticket(Ticket *&ticket) { ticket = mTicket; }

    // Tested
    virtual void FillStrategyMagicNumbers();
    virtual void SetActiveTickets();

    virtual void RecordPreOrderOpenData();
    virtual void RecordPostOrderOpenData();
    virtual void RecordOrderCloseData();

    virtual void CheckTicket();

    // Tested
    virtual void Manage();

    // Tested
    virtual void CheckStopTrading();

    // Tested
    virtual void StopTrading(bool deletePendingOrder, int error);

    // Tested
    virtual bool AllowedToTrade();

    // Tested
    virtual bool Confirmation();
    virtual void PlaceOrders();

    // Tested
    virtual void CheckSetSetup();
    virtual void Reset();

    // Tested
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

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;

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
    int findTicketsError = OrderHelper::FindActiveTicketsByMagicNumber(true, MagicNumber, tickets);
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
    mLastState = EAStates::CHECKING_TICKET;

    if (mTicket.Number() == EMPTY)
    {
        return;
    }

    mLastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool activated;
    int activatedError = mTicket.WasActivated(activated);
    if (TerminalErrors::IsTerminalError(activatedError))
    {
        StopTrading(false, activatedError);
        return;
    }

    if (activated)
    {
        RecordPostOrderOpenData();
    }

    mLastState = EAStates::CHECKING_IF_TICKET_IS_CLOSED;

    bool closed;
    int closeError = mTicket.WasClosed(closed);
    if (TerminalErrors::IsTerminalError(closeError))
    {
        StopTrading(false, closeError);
        return;
    }

    if (closed)
    {
        RecordOrderCloseData();
        CSVRecordWriter<DefaultTradeRecord>::Write();

        StopTrading(false);
        mTicket.SetNewTicket(EMPTY);
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
        StopTrading(false, isActiveError);
        return;
    }

    if (!isActive)
    {
        mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
            mStopLossPaddingPips, mMaxSpreadPips, mRiskPercent, mFirstMBInSetupNumber, mMBT, mTicket);

        if (TerminalErrors::IsTerminalError(editStopLossError))
        {
            StopTrading(true, editStopLossError);
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
            StopTrading(false, trailError);
            return;
        }
    }
}

void TheSunriseShatterSingleMB::CheckStopTrading()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    // Want to try to close the pending order if we have a setup or not and we break the range start
    if (mFirstMBInSetupNumber != EMPTY)
    {
        mLastState = EAStates::CHECKING_IF_BROKE_RANGE_START;

        bool brokeRangeStart;
        int brokeRangeStartError = SetupHelper::BrokeMBRangeStart(mFirstMBInSetupNumber, mMBT, brokeRangeStart);
        if (TerminalErrors::IsTerminalError(brokeRangeStartError))
        {
            StopTrading(true, brokeRangeStartError);
            return;
        }

        if (brokeRangeStart)
        {
            StopTrading(true);
            return;
        }
    }

    if (!mHasSetup)
    {
        return;
    }

    // should be checked before checking if we broke the range end so that it can cancel the pending order
    // Can be checked only if we have a setup. If we don't have a setup at this point then the order should be closed
    // anyways
    mLastState = EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;

    if (mMRFTS.CrossedOpenPriceAfterMinROC())
    {
        StopTrading(true);
        return;
    }

    mLastState = EAStates::CHECKING_IF_BROKE_RANGE_END;

    MBState *tempMBState;
    if (!mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        StopTrading(true, TerminalErrors::MB_DOES_NOT_EXIST);
        return;
    }

    // should invalide the setup no matter if we have a ticket or not. Just don't cancel the ticket if we do
    // will allow the ticket to be hit since there is spread calculated and it is above the mb
    if (tempMBState.Number() != mFirstMBInSetupNumber)
    {
        StopTrading(false);
        return;
    }
}

void TheSunriseShatterSingleMB::StopTrading(bool deletePendingOrder, int error = ERR_NO_ERROR)
{
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

    if (!deletePendingOrder)
    {
        return;
    }

    bool isActive = false;
    int isActiveError = mTicket.IsActive(isActive);

    // Only close the order if it is pending or else every active order would get closed
    // as soon as the setup is finished
    if (!isActive)
    {
        int closeError = mTicket.Close();
        if (TerminalErrors::IsTerminalError(closeError))
        {
            EA<DefaultTradeRecord>::RecordError(closeError);
        }

        mTicket.SetNewTicket(EMPTY);
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
    if (confirmationError != ERR_NO_ERROR)
    {
        StopTrading(false, confirmationError);
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
    int ordersError = OrderHelper::CountOtherEAOrders(true, mStrategyMagicNumbers, orders);
    if (ordersError != ERR_NO_ERROR)
    {
        StopTrading(false, ordersError);
        return;
    }

    if (orders >= mMaxTradesPerStrategy)
    {
        StopTrading(false);
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
        if (TerminalErrors::IsTerminalError(orderPlaceError))
        {
            StopTrading(false, orderPlaceError);
        }
        else
        {
            StopTrading(false);
        }

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
        StopTrading(false, setupError);
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
        StopTrading(false, TerminalErrors::MB_DOES_NOT_EXIST);
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

    mSetupType = EMPTY;
    mFirstMBInSetupNumber = EMPTY;
}

void TheSunriseShatterSingleMB::Run()
{
    mMBT.DrawNMostRecentMBs(1);
    mMBT.DrawZonesForNMostRecentMBs(1);
    mMRFTS.Draw();

    CheckTicket();
    Manage();
    CheckStopTrading();

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