//+------------------------------------------------------------------+
//|                                                     EAHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB - Copy.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB - Copy.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB - Copy.mqh>

class EAHelper
{
public:
    // =========================================================================
    // Filling Strategy Magic Numbers
    // =========================================================================
    template <typename TEA>
    static void FillSunriseShatterMagicNumbers(TEA &ea);

    template <typename TEA>
    static void FillBullishKataraMagicNumbers(TEA &ea);
    template <typename TEA>
    static void FillBearishKataraMagicNumbers(TEA &ea);

    // =========================================================================
    // Set Active Ticket
    // =========================================================================
    template <typename TEA>
    static void SetSingleActiveTicket(TEA &ea);

    // =========================================================================
    // Run
    // =========================================================================
    template <typename TEA>
    static void Run(TEA &ea);
    template <typename TEA>
    static void RunDrawMBT(TEA &ea);
    template <typename TEA>
    static void RunDrawMBTAndMRFTS(TEA &ea);

    // =========================================================================
    // Allowed To Trade
    // =========================================================================
    template <typename TEA>
    static bool BelowSpread(TEA &ea);
    template <typename TEA>
    static bool PastMinROCOpenTime(TEA &ea);

    // =========================================================================
    // Check Set Setup
    // =========================================================================
private:
    template <typename TEA>
    static bool CheckSetFirstMBInSetup(TEA &ea);
    template <typename TEA>
    static bool CheckSetSecondMBInSetup(TEA &ea);
    template <typename TEA>
    static bool CheckSetLiquidationMBInSetup(TEA &ea);
    template <typename TEA>
    static bool CheckBreakAfterMinROC(TEA &ea);

public:
    template <typename TEA>
    static bool CheckSetSingleMBAfterMinROCBreak(TEA &ea);
    template <typename TEA>
    static bool CheckSetDoubleMBAfterMinROCBreak(TEA &ea);
    template <typename TEA>
    static bool CheckSetLiquidationMBAfterMinROCBreak(TEA &ea);

    // =========================================================================
    // Check Stop Trading
    // =========================================================================
private:
    template <typename TEA>
    static bool CheckBrokeMBRangeEnd(TEA &ea, int mbNumber);

public:
    template <typename TEA>
    static bool CheckBrokeRangeStart(TEA &ea);
    template <typename TEA>
    static bool CheckBrokeSingleMBRangeEnd(TEA &ea);
    template <typename TEA>
    static bool CheckBrokeDoubleMBRangeEnd(TEA &ea);
    template <typename TEA>
    static bool CheckBrokeLiquidationMBRangeEnd(TEA &ea);

    template <typename TEA>
    static bool CheckCrossedOpenPriceAfterMinROC(TEA &ea);

    // =========================================================================
    // Stop Trading
    // =========================================================================
    template <typename TEA>
    static void StopTrading(TEA &ea, bool deletePendingOrder, int error);

    // =========================================================================
    // Confirmation
    // =========================================================================
private:
    template <typename TEA>
    static bool MostRecentMBZoneIsHolding(TEA &ea, int mbNumber);

public:
    template <typename TEA>
    static bool FirstMBZoneIsHolding(TEA &ea);
    template <typename TEA>
    static bool SecondMBZoneIsHolding(TEA &ea);
    template <typename TEA>
    static bool LiquidationMBZoneIsHolding(TEA &ea);

    // =========================================================================
    // Place Order
    // =========================================================================
    template <typename TEA>
    static bool PrePlaceOrderChecks(TEA &ea);
    template <typename TEA>
    static void PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error);

    template <typename TEA>
    static void PlaceOrderOnFirstMB(TEA &ea);
    template <typename TEA>
    static void PlaceOrderOnSecondMB(TEA &ea);
    template <typename TEA>
    static void PlaceOrderOnLiquidationMB(TEA &ea);

    // =========================================================================
    // Manage Pending Ticket
    // =========================================================================
private:
    template <typename TEA>
    static void CheckEditPendingOrderStopLossOnValidationOfMB(TEA &ea, int mbNumber);

    template <typename TEA>
    static void CheckEditPendingOrderStopLossOnBreakOfMB(TEA &ea, int mbNumber);

public:
    template <typename TEA>
    static void CheckEditPendingOrderStopLossOnValidationOfFirstMB(TEA &ea);
    template <typename TEA>
    static void CheckEditPendingOrderStopLossOnValidationOfSecondMB(TEA &ea);
    template <typename TEA>
    static void CheckEditPendingOrderStopLossOnBreakOfLiquidationMB(TEA &ea);

    // =========================================================================
    // Manage Active Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckTrailStopLossWithMBs(TEA &ea);
    template <typename TEA>
    static void CheckPartial(TEA &ea);

    // =========================================================================
    // Check Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckTicket(TEA &ea);

    // =========================================================================
    // Record Data
    // =========================================================================
    template <typename TEA>
    static void RecordOrderOpenData(TEA &ea);
    template <typename TEA>
    static void RecordOrderCloseData(TEA &ea);

    // =========================================================================
    // Reset
    // =========================================================================
private:
    template <typename TEA>
    static void BaseReset(TEA &ea);

public:
    template <typename TEA>
    static void ResetSingleMBEA(TEA &ea);
    template <typename TEA>
    static void ResetDoubleMBEA(TEA &ea);
};
/*

   _____ _ _ _ _               ____  _             _                     __  __             _        _   _                 _
  |  ___(_) | (_)_ __   __ _  / ___|| |_ _ __ __ _| |_ ___  __ _ _   _  |  \/  | __ _  __ _(_) ___  | \ | |_   _ _ __ ___ | |__   ___ _ __ ___
  | |_  | | | | | '_ \ / _` | \___ \| __| '__/ _` | __/ _ \/ _` | | | | | |\/| |/ _` |/ _` | |/ __| |  \| | | | | '_ ` _ \| '_ \ / _ \ '__/ __|
  |  _| | | | | | | | | (_| |  ___) | |_| | | (_| | ||  __/ (_| | |_| | | |  | | (_| | (_| | | (__  | |\  | |_| | | | | | | |_) |  __/ |  \__ \
  |_|   |_|_|_|_|_| |_|\__, | |____/ \__|_|  \__,_|\__\___|\__, |\__, | |_|  |_|\__,_|\__, |_|\___| |_| \_|\__,_|_| |_| |_|_.__/ \___|_|  |___/
                       |___/                               |___/ |___/                |___/

*/
template <typename TEA>
static void EAHelper::FillSunriseShatterMagicNumbers(TEA &ea)
{
    ArrayFree(ea.mStrategyMagicNumbers);
    ArrayResize(ea.mStrategyMagicNumbers, 3);

    ea.mStrategyMagicNumbers[0] = TheSunriseShatterSingleMBC::MagicNumber;
    ea.mStrategyMagicNumbers[1] = TheSunriseShatterDoubleMBC::MagicNumber;
    ea.mStrategyMagicNumbers[2] = TheSunriseShatterLiquidationMBC::MagicNumber;
}

template <typename TEA>
static void EAHelper::FillBullishKataraMagicNumbers(TEA &ea)
{
    // TDOD
}

template <typename TEA>
static void EAHelper::FillBearishKataraMagicNumbers(TEA &ea)
{
    // TODO
}
/*

   ____       _        _        _   _             _____ _      _        _
  / ___|  ___| |_     / \   ___| |_(_)_   _____  |_   _(_) ___| | _____| |_
  \___ \ / _ \ __|   / _ \ / __| __| \ \ / / _ \   | | | |/ __| |/ / _ \ __|
   ___) |  __/ |_   / ___ \ (__| |_| |\ V /  __/   | | | | (__|   <  __/ |_
  |____/ \___|\__| /_/   \_\___|\__|_| \_/ \___|   |_| |_|\___|_|\_\___|\__|


*/
template <typename TEA>
static void EAHelper::SetSingleActiveTicket(TEA &ea)
{
    int tickets[];
    int findTicketsError = OrderHelper::FindActiveTicketsByMagicNumber(true, ea.MagicNumber, tickets);
    if (findTicketsError != ERR_NO_ERROR)
    {
        ea.RecordError(findTicketsError);
    }

    if (ArraySize(tickets) > 0)
    {
        ea.mTicket.SetNewTicket(tickets[0]);
    }
}
/*

   ____
  |  _ \ _   _ _ __
  | |_) | | | | '_ \
  |  _ <| |_| | | | |
  |_| \_\\__,_|_| |_|


*/
template <typename TEA>
static void EAHelper::Run(TEA &ea)
{
    if (ea.mTicket.Number() != EMPTY)
    {
        ea.CheckTicket();
    }

    if (ea.mTicket.Number() != EMPTY)
    {
        bool isActive;
        int isActiveError = ea.mTicket.IsActive(isActive);
        if (TerminalErrors::IsTerminalError(isActiveError))
        {
            ea.StopTrading(false, isActiveError);
            return;
        }

        if (isActive)
        {
            ea.ManageActiveTicket();
        }
        else
        {
            ea.ManagePendingTicket();
        }
    }

    ea.CheckStopTrading();

    if (!ea.AllowedToTrade())
    {
        if (!ea.mWasReset)
        {
            ea.Reset();
            ea.mWasReset = true;
        }

        return;
    }

    if (ea.mStopTrading)
    {
        return;
    }

    if (ea.mHasSetup && ea.Confirmation())
    {
        ea.PlaceOrders();
        return;
    }

    if (!ea.mHasSetup)
    {
        ea.CheckSetSetup();
    }
}

template <typename TEA>
static void EAHelper::RunDrawMBT(TEA &ea)
{
    ea.mMBT.DrawNMostRecentMBs(1);
    ea.mMBT.DrawZonesForNMostRecentMBs(1);

    Run(ea);
}

template <typename TEA>
static void EAHelper::RunDrawMBTAndMRFTS(TEA &ea)
{
    ea.mMBT.DrawNMostRecentMBs(1);
    ea.mMBT.DrawZonesForNMostRecentMBs(1);
    ea.mMRFTS.Draw();

    Run(ea);
}
/*

      _    _ _                       _   _____       _____              _
     / \  | | | _____      _____  __| | |_   _|__   |_   _| __ __ _  __| | ___
    / _ \ | | |/ _ \ \ /\ / / _ \/ _` |   | |/ _ \    | || '__/ _` |/ _` |/ _ \
   / ___ \| | | (_) \ V  V /  __/ (_| |   | | (_) |   | || | | (_| | (_| |  __/
  /_/   \_\_|_|\___/ \_/\_/ \___|\__,_|   |_|\___/    |_||_|  \__,_|\__,_|\___|


*/
template <typename TEA>
static bool EAHelper::BelowSpread(TEA &ea)
{
    return (MarketInfo(Symbol(), MODE_SPREAD) / 10) <= ea.mMaxSpreadPips;
}
template <typename TEA>
static bool EAHelper::PastMinROCOpenTime(TEA &ea)
{
    return ea.mMRFTS.OpenPrice() > 0.0 || ea.mHasSetup;
}
/*

    ____ _               _      ____       _     ____       _
   / ___| |__   ___  ___| | __ / ___|  ___| |_  / ___|  ___| |_ _   _ _ __
  | |   | '_ \ / _ \/ __| |/ / \___ \ / _ \ __| \___ \ / _ \ __| | | | '_ \
  | |___| | | |  __/ (__|   <   ___) |  __/ |_   ___) |  __/ |_| |_| | |_) |
   \____|_| |_|\___|\___|_|\_\ |____/ \___|\__| |____/ \___|\__|\__,_| .__/
                                                                     |_|

*/
template <typename TEA>
static bool EAHelper::CheckSetFirstMBInSetup(TEA &ea)
{
    ea.mLastState = EAStates::GETTING_FIRST_MB_IN_SETUP;

    MBState *mbOneTempState;
    if (!ea.mMBT.GetNthMostRecentMB(0, mbOneTempState))
    {
        ea.StopTrading(false, TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    ea.mFirstMBInSetupNumber = mbOneTempState.Number();
    ea.mSetupType = mbOneTempState.Type();

    return true;
}
template <typename TEA>
static bool EAHelper::CheckSetSecondMBInSetup(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_GETTING_SECOND_MB_IN_SETUP;

    MBState *mbTwoTempState;
    if (!ea.mMBT.GetSubsequentMB(ea.mFirstMBInSetupNumber, mbTwoTempState))
    {
        return false;
    }

    if (mbTwoTempState.Type() != ea.mSetupType)
    {
        ea.StopTrading(false);
        return false;
    }

    ea.mSecondMBInSetupNumber = mbTwoTempState.Number();
    return true;
}
template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBInSetup(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_GETTING_LIQUIDATION_MB_IN_SETUP;

    MBState *mbThreeTempState;
    if (!ea.mMBT.GetSubsequentMB(ea.mSecondMBInSetupNumber, mbThreeTempState))
    {
        return false;
    }

    if (mbThreeTempState.Type() == ea.mSetupType)
    {
        ea.StopTrading(false);
        return false;
    }

    return true;
}
template <typename TEA>
static bool EAHelper::CheckBreakAfterMinROC(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC;

    bool isTrue = false;
    int setupError = SetupHelper::BreakAfterMinROC(ea.mMRFTS, ea.mMBT, isTrue);
    if (TerminalErrors::IsTerminalError(setupError))
    {
        ea.StopTrading(false, setupError);
        return false;
    }

    return isTrue;
}
template <typename TEA>
static bool EAHelper::CheckSetSingleMBAfterMinROCBreak(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (CheckBreakAfterMinROC(ea))
    {
        if (CheckSetFirstMBInSetup(ea))
        {
            return true;
        }
    }

    return false;
}
template <typename TEA>
static bool EAHelper::CheckSetDoubleMBAfterMinROCBreak(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (ea.mFirstMBInSetupNumber == EMPTY)
    {
        CheckSetSingleMBAfterMinROCBreak(ea);
    }
    else if (ea.mSecondMBInSetupNumber == EMPTY)
    {
        if (CheckSetSecondMBInSetup(ea))
        {
            return true;
        }
    }

    return false;
}
template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBAfterMinROCBreak(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (ea.mFirstMBInSetupNumber == EMPTY || ea.mSecondMBInSetupNumber == EMPTY)
    {
        CheckSetDoubleMBAfterMinROCBreak(ea);
    }
    else
    {
        if (CheckSetLiquidationMBInSetup(ea))
        {
            return true;
        }
    }

    return false;
}
/*

    ____ _               _      ____  _                _____              _ _
   / ___| |__   ___  ___| | __ / ___|| |_ ___  _ __   |_   _| __ __ _  __| (_)_ __   __ _
  | |   | '_ \ / _ \/ __| |/ / \___ \| __/ _ \| '_ \    | || '__/ _` |/ _` | | '_ \ / _` |
  | |___| | | |  __/ (__|   <   ___) | || (_) | |_) |   | || | | (_| | (_| | | | | | (_| |
   \____|_| |_|\___|\___|_|\_\ |____/ \__\___/| .__/    |_||_|  \__,_|\__,_|_|_| |_|\__, |
                                              |_|                                   |___/

*/
template <typename TEA>
static bool EAHelper::CheckBrokeMBRangeEnd(TEA &ea, int mbNumber)
{
    ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_END;

    MBState *tempMBState;
    if (!ea.mMBT.GetNthMostRecentMB(0, tempMBState))
    {
        ea.StopTrading(true, TerminalErrors::MB_DOES_NOT_EXIST);
        return true;
    }

    // should invalide the setup no matter if we have a ticket or not. Just don't cancel the ticket if we do
    // will allow the ticket to be hit since there is spread calculated and it is above the mb
    if (tempMBState.Number() != mbNumber)
    {
        ea.StopTrading(false);
        return true;
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckBrokeRangeStart(TEA &ea)
{
    if (ea.mFirstMBInSetupNumber != EMPTY && ea.mMBT.MBExists(ea.mFirstMBInSetupNumber))
    {
        ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_START;

        bool brokeRangeStart;
        int brokeRangeStartError = SetupHelper::BrokeMBRangeStart(ea.mFirstMBInSetupNumber, ea.mMBT, brokeRangeStart);
        if (TerminalErrors::IsTerminalError(brokeRangeStartError))
        {
            ea.StopTrading(true, brokeRangeStartError);
            return true;
        }

        if (brokeRangeStart)
        {
            ea.StopTrading(true);
            return true;
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckBrokeSingleMBRangeEnd(TEA &ea)
{
    return CheckBrokeMBRangeEnd(ea, ea.mFirstMBInSetupNumber);
}

template <typename TEA>
static bool EAHelper::CheckBrokeDoubleMBRangeEnd(TEA &ea)
{
    return CheckBrokeMBRangeEnd(ea, ea.mSecondMBInSetupNumber);
}

template <typename TEA>
static bool EAHelper::CheckBrokeLiquidationMBRangeEnd(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_END;

    bool brokeRangeEnd;
    int brokeRangeEndError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(ea.mSecondMBInSetupNumber, ea.mSetupType, ea.mMBT, brokeRangeEnd);
    if (brokeRangeEndError != ERR_NO_ERROR)
    {
        return true;
    }

    // should invalide the setup no matter if we have a ticket or not. Just don't cancel the ticket if we do
    // will allow the ticket to be hit since there is spread calculated and it is above the mb
    if (brokeRangeEnd)
    {
        ea.StopTrading(false);
        return true;
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckCrossedOpenPriceAfterMinROC(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;

    if (ea.mMRFTS.CrossedOpenPriceAfterMinROC())
    {
        ea.StopTrading(true);
        return true;
    }

    return false;
}
/*

   ____  _                _____              _ _
  / ___|| |_ ___  _ __   |_   _| __ __ _  __| (_)_ __   __ _
  \___ \| __/ _ \| '_ \    | || '__/ _` |/ _` | | '_ \ / _` |
   ___) | || (_) | |_) |   | || | | (_| | (_| | | | | | (_| |
  |____/ \__\___/| .__/    |_||_|  \__,_|\__,_|_|_| |_|\__, |
                 |_|                                   |___/

*/
template <typename TEA>
static void EAHelper::StopTrading(TEA &ea, bool deletePendingOrder, int error = ERR_NO_ERROR)
{
    ea.mHasSetup = false;
    ea.mStopTrading = true;

    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(error);
    }

    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    if (!deletePendingOrder)
    {
        return;
    }

    bool isActive = false;
    int isActiveError = ea.mTicket.IsActive(isActive);

    // Only close the order if it is pending or else every active order would get closed
    // as soon as the setup is finished
    if (!isActive)
    {
        int closeError = ea.mTicket.Close();
        if (TerminalErrors::IsTerminalError(closeError))
        {
            ea.RecordError(closeError);
        }

        ea.mTicket.SetNewTicket(EMPTY);
    }
}
/*

    ____             __ _                      _   _
   / ___|___  _ __  / _(_)_ __ _ __ ___   __ _| |_(_) ___  _ __
  | |   / _ \| '_ \| |_| | '__| '_ ` _ \ / _` | __| |/ _ \| '_ \
  | |__| (_) | | | |  _| | |  | | | | | | (_| | |_| | (_) | | | |
   \____\___/|_| |_|_| |_|_|  |_| |_| |_|\__,_|\__|_|\___/|_| |_|


*/
template <typename TEA>
static bool EAHelper::MostRecentMBZoneIsHolding(TEA &ea, int mbNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool isTrue = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mbNumber, ea.mMBT, isTrue);
    if (confirmationError != ERR_NO_ERROR)
    {
        ea.StopTrading(false, confirmationError);
        return false;
    }

    return isTrue;
}
template <typename TEA>
static bool EAHelper::FirstMBZoneIsHolding(TEA &ea)
{
    return MostRecentMBZoneIsHolding(ea, ea.mFirstMBInSetupNumber);
}
template <typename TEA>
static bool EAHelper::SecondMBZoneIsHolding(TEA &ea)
{
    return MostRecentMBZoneIsHolding(ea, ea.mSecondMBInSetupNumber);
}
template <typename TEA>
static bool EAHelper::LiquidationMBZoneIsHolding(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool hasConfirmation = false;
    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(ea.mFirstMBInSetupNumber, ea.mSecondMBInSetupNumber, ea.mMBT, hasConfirmation);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        ea.StopTrading(false, confirmationError);
        return false;
    }

    return hasConfirmation;
}
/*

   ____  _                   ___          _
  |  _ \| | __ _  ___ ___   / _ \ _ __ __| | ___ _ __
  | |_) | |/ _` |/ __/ _ \ | | | | '__/ _` |/ _ \ '__|
  |  __/| | (_| | (_|  __/ | |_| | | | (_| |  __/ |
  |_|   |_|\__,_|\___\___|  \___/|_|  \__,_|\___|_|


*/
template <typename TEA>
static bool EAHelper::PrePlaceOrderChecks(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_TO_PLACE_ORDER;

    if (ea.mTicket.Number() != EMPTY)
    {
        return false;
    }

    ea.mLastState = EAStates::COUNTING_OTHER_EA_ORDERS;

    int orders = 0;
    int ordersError = OrderHelper::CountOtherEAOrders(true, ea.mStrategyMagicNumbers, orders);
    if (ordersError != ERR_NO_ERROR)
    {
        ea.StopTrading(false, ordersError);
        return false;
    }

    if (orders >= ea.mMaxTradesPerStrategy)
    {
        ea.StopTrading(false);
        return false;
    }

    return true;
}
template <typename TEA>
static void EAHelper::PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error)
{
    if (ticketNumber == EMPTY)
    {
        ea.PendingRecord.Reset();
        if (TerminalErrors::IsTerminalError(error))
        {
            ea.StopTrading(false, error);
        }
        else
        {
            ea.StopTrading(false);
        }

        return;
    }

    ea.mTicket.SetNewTicket(ticketNumber);
}
template <typename TEA>
static void EAHelper::PlaceOrderOnFirstMB(TEA &ea)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingMBValidation(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber,
                                                                            ea.mFirstMBInSetupNumber, ea.mMBT, ticketNumber);
    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}
template <typename TEA>
static void EAHelper::PlaceOrderOnSecondMB(TEA &ea)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingMBValidation(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber,
                                                                            ea.mSecondMBInSetupNumber, ea.mMBT, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}
template <typename TEA>
static void EAHelper::PlaceOrderOnLiquidationMB(TEA &ea)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForBreakOfMB(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber,
                                                                  ea.mSecondMBInSetupNumber + 1, ea.mMBT, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}
/*

   __  __
  |  \/  | __ _ _ __   __ _  __ _  ___
  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \
  | |  | | (_| | | | | (_| | (_| |  __/
  |_|  |_|\__,_|_| |_|\__,_|\__, |\___|
                            |___/

*/
template <typename TEA>
static void EAHelper::CheckEditPendingOrderStopLossOnValidationOfMB(TEA &ea, int mbNumber)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, mbNumber, ea.mMBT, ea.mTicket);

    if (TerminalErrors::IsTerminalError(editStopLossError))
    {
        ea.StopTrading(true, editStopLossError);
        return;
    }
}

template <typename TEA>
static void EAHelper::CheckEditPendingOrderStopLossOnBreakOfMB(TEA &ea, int mbNumber)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnBreakOfMB(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, mbNumber, ea.mMBT, ea.mTicket);

    if (TerminalErrors::IsTerminalError(editStopLossError))
    {
        ea.StopTrading(true, editStopLossError);
        return;
    }
}

template <typename TEA>
static void EAHelper::CheckEditPendingOrderStopLossOnValidationOfFirstMB(TEA &ea)
{
    CheckEditPendingOrderStopLossOnValidationOfMB(ea, ea.mFirstMBInSetupNumber);
}

template <typename TEA>
static void EAHelper::CheckEditPendingOrderStopLossOnValidationOfSecondMB(TEA &ea)
{
    CheckEditPendingOrderStopLossOnValidationOfMB(ea, ea.mSecondMBInSetupNumber);
}

template <typename TEA>
static void EAHelper::CheckEditPendingOrderStopLossOnBreakOfLiquidationMB(TEA &ea)
{
    CheckEditPendingOrderStopLossOnBreakOfMB(ea, ea.mSecondMBInSetupNumber + 1);
}

template <typename TEA>
static void EAHelper::CheckTrailStopLossWithMBs(TEA &ea)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_TRAIL_STOP_LOSS;

    bool succeeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mFirstMBInSetupNumber, ea.mSetupType, ea.mMBT, ea.mTicket, succeeeded);

    if (TerminalErrors::IsTerminalError(trailError))
    {
        ea.StopTrading(false, trailError);
        return;
    }
}

template <typename TEA>
static void EAHelper::CheckPartial(TEA &ea)
{
}
/*

    ____ _               _      _____ _      _        _
   / ___| |__   ___  ___| | __ |_   _(_) ___| | _____| |_
  | |   | '_ \ / _ \/ __| |/ /   | | | |/ __| |/ / _ \ __|
  | |___| | | |  __/ (__|   <    | | | | (__|   <  __/ |_
   \____|_| |_|\___|\___|_|\_\   |_| |_|\___|_|\_\___|\__|


*/
template <typename TEA>
void EAHelper::CheckTicket(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_TICKET;

    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool activated;
    int activatedError = ea.mTicket.WasActivated(activated);
    if (TerminalErrors::IsTerminalError(activatedError))
    {
        ea.StopTrading(false, activatedError);
        return;
    }

    if (activated)
    {
        ea.RecordOrderOpenData();
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_CLOSED;

    bool closed;
    int closeError = ea.mTicket.WasClosed(closed);
    if (TerminalErrors::IsTerminalError(closeError))
    {
        ea.StopTrading(false, closeError);
        return;
    }

    if (closed)
    {
        ea.RecordOrderCloseData();
        ea.Write();

        ea.StopTrading(false);
        ea.mTicket.SetNewTicket(EMPTY);
    }
}
/*

   ____                        _   ____        _
  |  _ \ ___  ___ ___  _ __ __| | |  _ \  __ _| |_ __ _
  | |_) / _ \/ __/ _ \| '__/ _` | | | | |/ _` | __/ _` |
  |  _ <  __/ (_| (_) | | | (_| | | |_| | (_| | || (_| |
  |_| \_\___|\___\___/|_|  \__,_| |____/ \__,_|\__\__,_|


*/
template <typename TEA>
static void EAHelper::RecordOrderOpenData(TEA &ea)
{
    ea.mLastState = EAStates::RECORDING_POST_ORDER_OPEN_DATA;

    string imageName = ScreenShotHelper::TryTakeScreenShot(ea.Directory());

    ea.PendingRecord.Symbol = ea.mMBT.Symbol();
    ea.PendingRecord.TimeFrame = ea.mMBT.TimeFrame();
    ea.PendingRecord.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    ea.PendingRecord.AccountBalanceBefore = AccountBalance();
    ea.PendingRecord.EntryTime = OrderOpenTime();
    ea.PendingRecord.EntryImage = imageName;
    ea.PendingRecord.EntryPrice = OrderOpenPrice();
    ea.PendingRecord.EntryStopLoss = OrderStopLoss();
    ea.PendingRecord.Lots = OrderLots();
}
template <typename TEA>
static void EAHelper::RecordOrderCloseData(TEA &ea)
{
    ea.mLastState = EAStates::RECORDING_POST_ORDER_CLOSE_DATA;

    string imageName = ScreenShotHelper::TryTakeScreenShot(ea.Directory());

    ea.PendingRecord.AccountBalanceAfter = AccountBalance();
    ea.PendingRecord.ExitTime = OrderCloseTime();
    ea.PendingRecord.ExitImage = imageName;
    ea.PendingRecord.ExitPrice = OrderClosePrice();
    ea.PendingRecord.ExitStopLoss = OrderStopLoss();
}
/*

   ____                _
  |  _ \ ___  ___  ___| |_
  | |_) / _ \/ __|/ _ \ __|
  |  _ <  __/\__ \  __/ |_
  |_| \_\___||___/\___|\__|


*/
template <typename TEA>
static void EAHelper::BaseReset(TEA &ea)
{
    ea.mLastState = EAStates::RESETING;

    ea.mStopTrading = false;
    ea.mHasSetup = false;

    ea.mSetupType = EMPTY;
}
template <typename TEA>
static void EAHelper::ResetSingleMBEA(TEA &ea)
{
    BaseReset(ea);
    ea.mFirstMBInSetupNumber = EMPTY;
}
template <typename TEA>
static void EAHelper::ResetDoubleMBEA(TEA &ea)
{
    ResetSingleMBEA(ea);
    ea.mSecondMBInSetupNumber = EMPTY;
}