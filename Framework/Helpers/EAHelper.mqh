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

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

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
    static void RunDrawMBT(TEA &ea, MBTracker *&mbt);
    template <typename TEA>
    static void RunDrawMBTAndMRFTS(TEA &ea, MBTracker *&mbt);

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
    static bool CheckSetFirstMB(TEA &ea, MBTracker *&mbt, int &mbNumber, int forcedType);
    template <typename TEA>
    static bool CheckSetSecondMB(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber);
    template <typename TEA>
    static bool CheckSetLiquidationMB(TEA &ea, MBTracker *&mbt, int &secondMBNumber, int &liquidationMBNumber);
    template <typename TEA>
    static bool CheckBreakAfterMinROC(TEA &ea, MBTracker *&mbt);

public:
    template <typename TEA>
    static bool CheckSetFirstMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber);
    template <typename TEA>
    static bool CheckSetDoubleMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber);
    template <typename TEA>
    static bool CheckSetLiquidationMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber);

    template <typename TEA>
    static bool CheckSetFirstMBAfterBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType);
    template <typename TEA>
    static bool CheckSetSecondMBAfterBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType);
    template <typename TEA>
    static bool CheckSetLiquidationMBAfterBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber, int forcedType);

    template <typename TEA>
    static bool MBPushedFurtherIntoSetupZone(TEA &ea, MBTracker *&setupMBT, int setupMBNumber, MBTracker *&confirmationMBT);
    template <typename TEA>
    static bool MBRetappedSetupZone(TEA &ea, MBTracker *&setupMBT, int setupMBNumber, MBTracker *&confirmationMBT);

    // =========================================================================
    // Check Invalidate Setup
    // =========================================================================
public:
    template <typename TEA>
    static bool CheckBrokeMBRangeStart(TEA &ea, MBTracker *&mbt, int mbNumber, bool cancelPendingOrder);
    template <typename TEA>
    static bool CheckBrokeMBRangeEnd(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static bool CheckCrossedOpenPriceAfterMinROC(TEA &ea);

    // =========================================================================
    // Invalidate Setup
    // =========================================================================
    template <typename TEA>
    static void InvalidateSetup(TEA &ea, bool deletePendingOrder, bool stopTrading, int error);

    // =========================================================================
    // Confirmation
    // =========================================================================
    template <typename TEA>
    static bool MostRecentMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static bool LiquidationMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber);

    // =========================================================================
    // Place Order
    // =========================================================================
    template <typename TEA>
    static bool PrePlaceOrderChecks(TEA &ea);
    template <typename TEA>
    static void PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error);

    template <typename TEA>
    static void PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static void PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber);

    // =========================================================================
    // Manage Pending Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckEditStopLossForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static void CheckEditStopLossForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber);

    // =========================================================================
    // Manage Active Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckTrailStopLossWithMBs(TEA &ea, MBTracker *&mbt, int lastMBNumberInSetup);
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
    static void RecordDefaultTradeRecordOpenData(TEA &ea, int entryTimeFrame);
    template <typename TEA>
    static void EAHelper::RecordDefaultTradeRecordCloseData(TEA &ea);

    template <typename TEA>
    static void EAHelper::RecordSingleTimeFrameRecordOpenData(TEA &ea, int timeFrame);
    template <typename TEA>
    static void EAHelper::RecordSingleTimeFrameRecordCloseData(TEA &ea);

    template <typename TEA>
    static void EAHelper::RecordMultiTimeFrameRecordOpenData(TEA &ea, int lowerTimeFrame, int higherTimeFrame);
    template <typename TEA>
    static void EAHelper::RecordMultiTimeFrameRecordCloseData(TEA &ea, int lowerTimeFrame, int higherTimeFrame);

    // =========================================================================
    // Reset
    // =========================================================================
private:
    template <typename TEA>
    static void BaseReset(TEA &ea);

public:
    template <typename TEA>
    static void ResetSingleMBSetup(TEA &ea, bool baseReset);
    template <typename TEA>
    static void ResetDoubleMBSetup(TEA &ea, bool baseReset);
    template <typename TEA>
    static void ResetLiquidationMBSetup(TEA &ea, bool baseReset);

    template <typename TEA>
    static void ResetSingleMBConfirmation(TEA &ea, bool baseReset);
    template <typename TEA>
    static void ResetDoubleMBConfirmation(TEA &ea, bool baseReset);
    template <typename TEA>
    static void ResetLiquidationMBConfirmation(TEA &ea, bool baseReset);
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

    ea.mStrategyMagicNumbers[0] = MagicNumbers::TheSunriseShatterSingleMB;
    ea.mStrategyMagicNumbers[1] = MagicNumbers::TheSunriseShatterDoubleMB;
    ea.mStrategyMagicNumbers[2] = MagicNumbers::TheSunriseShatterLiquidationMB;
}

template <typename TEA>
static void EAHelper::FillBullishKataraMagicNumbers(TEA &ea)
{
    // TDOD
}

template <typename TEA>
static void EAHelper::FillBearishKataraMagicNumbers(TEA &ea)
{
    ArrayFree(ea.mStrategyMagicNumbers);
    ArrayResize(ea.mStrategyMagicNumbers, 3);

    ea.mStrategyMagicNumbers[0] = MagicNumbers::BearishKataraSingleMB;
    ea.mStrategyMagicNumbers[1] = MagicNumbers::BearishKataraDoubleMB;
    ea.mStrategyMagicNumbers[2] = MagicNumbers::BearishKataraLiquidationMB;
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
    int findTicketsError = OrderHelper::FindActiveTicketsByMagicNumber(true, ea.MagicNumber(), tickets);
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
            ea.InvalidateSetup(false, isActiveError);
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

    ea.CheckInvalidateSetup();

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

    if (ea.mHasSetup)
    {
        if (ea.mTicket.Number() == EMPTY)
        {
            if (ea.Confirmation())
            {
                ea.PlaceOrders();
            }
        }
        else
        {
            ea.mLastState = EAStates::CHECKING_IF_CONFIRMATION_IS_STILL_VALID;

            bool isActive;
            int isActiveError = ea.mTicket.IsActive(isActive);
            if (TerminalErrors::IsTerminalError(isActiveError))
            {
                ea.InvalidateSetup(false, isActiveError);
                return;
            }

            if (!isActive && !ea.Confirmation())
            {
                ea.mTicket.Close();
                ea.mTicket.SetNewTicket(EMPTY);
            }
        }
    }
    else
    {
        ea.CheckSetSetup();
    }
}

template <typename TEA>
static void EAHelper::RunDrawMBT(TEA &ea, MBTracker *&mbt)
{
    mbt.DrawNMostRecentMBs(1);
    mbt.DrawZonesForNMostRecentMBs(1);

    Run(ea);
}

template <typename TEA>
static void EAHelper::RunDrawMBTAndMRFTS(TEA &ea, MBTracker *&mbt)
{
    mbt.DrawNMostRecentMBs(1);
    mbt.DrawZonesForNMostRecentMBs(1);
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
static bool EAHelper::CheckSetFirstMB(TEA &ea, MBTracker *&mbt, int &mbNumber, int forcedType = EMPTY)
{
    ea.mLastState = EAStates::GETTING_FIRST_MB_IN_SETUP;

    MBState *mbOneTempState;
    if (!mbt.GetNthMostRecentMB(0, mbOneTempState))
    {
        ea.InvalidateSetup(false, TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    if (forcedType != EMPTY)
    {
        if (mbOneTempState.Type() != forcedType)
        {
            return false;
        }

        mbNumber = mbOneTempState.Number();
    }
    else
    {
        mbNumber = mbOneTempState.Number();
        ea.mSetupType = mbOneTempState.Type();
    }

    return true;
}

template <typename TEA>
static bool EAHelper::CheckSetSecondMB(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_GETTING_SECOND_MB_IN_SETUP;

    MBState *mbTwoTempState;
    if (!mbt.GetSubsequentMB(firstMBNumber, mbTwoTempState))
    {
        return false;
    }

    if (mbTwoTempState.Type() != ea.mSetupType)
    {
        ea.InvalidateSetup(false);
        return false;
    }

    secondMBNumber = mbTwoTempState.Number();
    return true;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMB(TEA &ea, MBTracker *&mbt, int &secondMBNumber, int &liquidationMBNumber)
{
    ea.mLastState = EAStates::CHECKING_GETTING_LIQUIDATION_MB_IN_SETUP;

    MBState *mbThreeTempState;
    if (!mbt.GetSubsequentMB(secondMBNumber, mbThreeTempState))
    {
        return false;
    }

    if (mbThreeTempState.Type() == ea.mSetupType)
    {
        ea.InvalidateSetup(false);
        return false;
    }

    liquidationMBNumber = mbThreeTempState.Number();
    return true;
}

template <typename TEA>
static bool EAHelper::CheckBreakAfterMinROC(TEA &ea, MBTracker *&mbt)
{
    ea.mLastState = EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC;

    bool isTrue = false;
    int setupError = SetupHelper::BreakAfterMinROC(ea.mMRFTS, mbt, isTrue);
    if (TerminalErrors::IsTerminalError(setupError))
    {
        ea.InvalidateSetup(false, setupError);
        return false;
    }

    return isTrue;
}

template <typename TEA>
static bool EAHelper::CheckSetFirstMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY)
    {
        if (CheckBreakAfterMinROC(ea, mbt))
        {
            if (CheckSetFirstMB(ea, mbt, firstMBNumber))
            {
                return true;
            }
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckSetDoubleMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY)
    {
        CheckSetFirstMBAfterMinROCBreak(ea, mbt, firstMBNumber);
    }
    else if (secondMBNumber == EMPTY)
    {
        if (CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber))
        {
            return true;
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY || secondMBNumber == EMPTY)
    {
        CheckSetDoubleMBAfterMinROCBreak(ea, mbt, firstMBNumber, secondMBNumber);
    }
    else
    {
        if (CheckSetLiquidationMB(ea, mbt, secondMBNumber, liquidationMBNumber))
        {
            return true;
        }
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY && liquidationMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetFirstMBAfterBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType = EMPTY)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY)
    {
        if (mbt.NthMostRecentMBIsOpposite(0))
        {
            if (CheckSetFirstMB(ea, mbt, firstMBNumber, forcedType))
            {
                return true;
            }
        }
    }

    return firstMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetSecondMBAfterBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType = EMPTY)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY)
    {
        CheckSetFirstMBAfterBreak(ea, mbt, firstMBNumber, forcedType);
    }
    else if (secondMBNumber == EMPTY)
    {
        if (CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber))
        {
            return true;
        }
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBAfterBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber, int forcedType = EMPTY)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY || secondMBNumber == EMPTY)
    {
        CheckSetSecondMBAfterBreak(ea, mbt, firstMBNumber, secondMBNumber, forcedType);
    }
    else
    {
        if (CheckSetLiquidationMB(ea, mbt, secondMBNumber, liquidationMBNumber))
        {
            return true;
        }
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY && liquidationMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::MBPushedFurtherIntoSetupZone(TEA &ea, MBTracker *&setupMBT, int setupMBNumber, MBTracker *&confirmationMBT)
{
    ea.mLastState = EAStates::CHECKING_IF_PUSHED_FURTHER_INTO_ZONE;

    bool pushedFurtherIntoZone = false;
    int error = SetupHelper::MBPushedFurtherIntoSetupZone(setupMBNumber, setupMBT, confirmationMBT, pushedFurtherIntoZone);
    if (error != ERR_NO_ERROR)
    {
        ea.InvalidateSetup(true, error);
    }

    return pushedFurtherIntoZone;
}

template <typename TEA>
static bool EAHelper::MBRetappedSetupZone(TEA &ea, MBTracker *&setupMBT, int setupMBNumber, MBTracker *&confirmationMBT)
{
    ea.mLastState = EAStates::CHECKING_IF_RETAPPED_ZONE;

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedSetupZone(setupMBNumber, setupMBT, confirmationMBT, retappedZone);
    if (error != ERR_NO_ERROR)
    {
        ea.InvalidateSetup(true, error);
    }

    return retappedZone;
}
/*

    ____ _               _      ___                 _ _     _       _         ____       _
   / ___| |__   ___  ___| | __ |_ _|_ ____   ____ _| (_) __| | __ _| |_ ___  / ___|  ___| |_ _   _ _ __
  | |   | '_ \ / _ \/ __| |/ /  | || '_ \ \ / / _` | | |/ _` |/ _` | __/ _ \ \___ \ / _ \ __| | | | '_ \
  | |___| | | |  __/ (__|   <   | || | | \ V / (_| | | | (_| | (_| | ||  __/  ___) |  __/ |_| |_| | |_) |
   \____|_| |_|\___|\___|_|\_\ |___|_| |_|\_/ \__,_|_|_|\__,_|\__,_|\__\___| |____/ \___|\__|\__,_| .__/
                                                                                                  |_|

*/
template <typename TEA>
static bool EAHelper::CheckBrokeMBRangeStart(TEA &ea, MBTracker *&mbt, int mbNumber, bool cancelPendingOrder = true)
{
    if (mbNumber != EMPTY && mbt.MBExists(mbNumber))
    {
        ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_START;

        bool brokeRangeStart;
        int brokeRangeStartError = mbt.MBStartIsBroken(mbNumber, brokeRangeStart);
        if (TerminalErrors::IsTerminalError(brokeRangeStartError))
        {
            ea.InvalidateSetup(true, brokeRangeStartError);
            return true;
        }

        if (brokeRangeStart)
        {
            ea.InvalidateSetup(cancelPendingOrder);
            return true;
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckBrokeMBRangeEnd(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_END;

    bool brokeRangeEnd = false;
    int error = mbt.MBEndIsBroken(mbNumber, brokeRangeEnd);
    if (TerminalErrors::IsTerminalError(error))
    {
        ea.InvalidateSetup(true, error);
        return true;
    }

    // should invalide the setup no matter if we have a ticket or not. Just don't cancel the ticket if we do
    // will allow the ticket to be hit since there is spread calculated and it is above the mb
    if (brokeRangeEnd)
    {
        ea.InvalidateSetup(false);
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
        ea.InvalidateSetup(true);
        return true;
    }

    return false;
}
/*

   ___                 _ _     _       _         ____       _
  |_ _|_ ____   ____ _| (_) __| | __ _| |_ ___  / ___|  ___| |_ _   _ _ __
   | || '_ \ \ / / _` | | |/ _` |/ _` | __/ _ \ \___ \ / _ \ __| | | | '_ \
   | || | | \ V / (_| | | | (_| | (_| | ||  __/  ___) |  __/ |_| |_| | |_) |
  |___|_| |_|\_/ \__,_|_|_|\__,_|\__,_|\__\___| |____/ \___|\__|\__,_| .__/
                                                                     |_|

*/
template <typename TEA>
static void EAHelper::InvalidateSetup(TEA &ea, bool deletePendingOrder, bool stopTrading, int error = ERR_NO_ERROR)
{
    ea.mHasSetup = false;
    ea.mStopTrading = stopTrading;

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
static bool EAHelper::MostRecentMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool isTrue = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mbNumber, mbt, isTrue);
    if (confirmationError != ERR_NO_ERROR)
    {
        ea.InvalidateSetup(false, confirmationError);
        return false;
    }

    return isTrue;
}
template <typename TEA>
static bool EAHelper::LiquidationMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool hasConfirmation = false;
    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(firstMBNumber, secondMBNumber, mbt, hasConfirmation);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        ea.InvalidateSetup(false, confirmationError);
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
        ea.InvalidateSetup(false, ordersError);
        return false;
    }

    if (orders >= ea.mMaxTradesPerStrategy)
    {
        ea.InvalidateSetup(false);
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
            ea.InvalidateSetup(false, error);
        }
        else
        {
            ea.InvalidateSetup(false);
        }

        return;
    }

    ea.mTicket.SetNewTicket(ticketNumber);
}

template <typename TEA>
static void EAHelper::PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingMBValidation(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                            mbNumber, mbt, ticketNumber);
    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAHelper::PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForBreakOfMB(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                  mbNumber, mbt, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}
/*

   __  __                                ____                _ _               _____ _      _        _
  |  \/  | __ _ _ __   __ _  __ _  ___  |  _ \ ___ _ __   __| (_)_ __   __ _  |_   _(_) ___| | _____| |_
  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ | |_) / _ \ '_ \ / _` | | '_ \ / _` |   | | | |/ __| |/ / _ \ __|
  | |  | | (_| | | | | (_| | (_| |  __/ |  __/  __/ | | | (_| | | | | | (_| |   | | | | (__|   <  __/ |_
  |_|  |_|\__,_|_| |_|\__,_|\__, |\___| |_|   \___|_| |_|\__,_|_|_| |_|\__, |   |_| |_|\___|_|\_\___|\__|
                            |___/                                      |___/

*/
template <typename TEA>
static void EAHelper::CheckEditStopLossForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, mbNumber, mbt, ea.mTicket);

    if (TerminalErrors::IsTerminalError(editStopLossError))
    {
        ea.InvalidateSetup(true, editStopLossError);
        return;
    }
}

template <typename TEA>
static void EAHelper::CheckEditStopLossForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnBreakOfMB(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, mbNumber, mbt, ea.mTicket);

    if (TerminalErrors::IsTerminalError(editStopLossError))
    {
        ea.InvalidateSetup(true, editStopLossError);
        return;
    }
}
/*

   __  __                                   _        _   _             _____ _      _        _
  |  \/  | __ _ _ __   __ _  __ _  ___     / \   ___| |_(_)_   _____  |_   _(_) ___| | _____| |_
  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \   / _ \ / __| __| \ \ / / _ \   | | | |/ __| |/ / _ \ __|
  | |  | | (_| | | | | (_| | (_| |  __/  / ___ \ (__| |_| |\ V /  __/   | | | | (__|   <  __/ |_
  |_|  |_|\__,_|_| |_|\__,_|\__, |\___| /_/   \_\___|\__|_| \_/ \___|   |_| |_|\___|_|\_\___|\__|
                            |___/

*/
template <typename TEA>
static void EAHelper::CheckTrailStopLossWithMBs(TEA &ea, MBTracker *&mbt, int lastMBNumberInSetup)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;
    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_TRAIL_STOP_LOSS;

    bool succeeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, lastMBNumberInSetup, ea.mSetupType, mbt, ea.mTicket, succeeeded);

    if (TerminalErrors::IsTerminalError(trailError))
    {
        ea.InvalidateSetup(false, trailError);
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
        ea.InvalidateSetup(false, activatedError);
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
        ea.InvalidateSetup(false, closeError);
        return;
    }

    if (closed)
    {
        ea.RecordOrderCloseData();
        ea.Write();

        ea.InvalidateSetup(false);
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
static void EAHelper::RecordDefaultTradeRecordOpenData(TEA &ea, int entryTimeFrame)
{
    ea.mLastState = EAStates::RECORDING_ORDER_OPEN_DATA;

    ea.PendingRecord.Symbol = Symbol();
    ea.PendingRecord.EntryTimeFrame = entryTimeFrame;
    ea.PendingRecord.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    ea.PendingRecord.AccountBalanceBefore = AccountBalance();
    ea.PendingRecord.Lots = OrderLots();
    ea.PendingRecord.EntryPrice = OrderOpenPrice();
    ea.PendingRecord.EntryStopLoss = OrderStopLoss();
}

template <typename TEA>
static void EAHelper::RecordDefaultTradeRecordCloseData(TEA &ea)
{
    ea.mLastState = EAStates::RECORDING_ORDER_CLOSE_DATA;

    ea.PendingRecord.AccountBalanceAfter = AccountBalance();
    ea.PendingRecord.ExitTime = OrderCloseTime();
    ea.PendingRecord.ExitPrice = OrderClosePrice();
    ea.PendingRecord.ExitStopLoss = OrderStopLoss();
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameRecordOpenData(TEA &ea, int timeFrame)
{
    RecordDefaultTradeRecordOpenData(ea, timeFrame);
    ea.PendingRecord.EntryImage = ScreenShotHelper::TryTakeScreenShot(ea.Directory());
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameRecordCloseData(TEA &ea)
{
    RecordDefaultTradeRecordCloseData(ea);
    ea.PendingRecord.ExitImage = ScreenShotHelper::TryTakeScreenShot(ea.Directory());
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameRecordOpenData(TEA &ea, int lowerTimeFrame, int higherTimeFrame)
{
    RecordDefaultTradeRecordOpenData(ea, lowerTimeFrame);

    string lowerTimeFrameImage;
    string higherTimeFrameImage;

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(error);
        return;
    }

    ea.PendingRecord.LowerTimeFrameEntryImage = lowerTimeFrameImage;
    ea.PendingRecord.HigherTimeFrameEntryImage = higherTimeFrameImage;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameRecordCloseData(TEA &ea, int lowerTimeFrame, int higherTimeFrame)
{
    RecordDefaultTradeRecordCloseData(ea);

    string lowerTimeFrameImage;
    string higherTimeFrameImage;

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(error);
        return;
    }

    ea.PendingRecord.LowerTimeFrameExitImage = lowerTimeFrameImage;
    ea.PendingRecord.HigherTimeFrameExitImage = higherTimeFrameImage;
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
    ea.mStopTrading = false;
    ea.mHasSetup = false;

    ea.mSetupType = EMPTY;
}

template <typename TEA>
static void EAHelper::ResetSingleMBSetup(TEA &ea, bool baseReset)
{
    ea.mLastState = EAStates::RESETING;

    if (baseReset)
    {
        BaseReset(ea);
    }

    ea.mFirstMBInSetupNumber = EMPTY;
}

template <typename TEA>
static void EAHelper::ResetDoubleMBSetup(TEA &ea, bool baseReset)
{
    ResetSingleMBSetup(ea, baseReset);
    ea.mSecondMBInSetupNumber = EMPTY;
}

template <typename TEA>
static void EAHelper::ResetLiquidationMBSetup(TEA &ea, bool baseReset)
{
    ResetDoubleMBSetup(ea, baseReset);
    ea.mLiquidationMBInSetupNumber = EMPTY;
}

template <typename TEA>
static void EAHelper::ResetSingleMBConfirmation(TEA &ea, bool baseReset)
{
    ea.mLastState = EAStates::RESETING;

    if (baseReset)
    {
        BaseReset(ea);
    }

    ea.mFirstMBInConfirmationNumber = EMPTY;
}

template <typename TEA>
static void EAHelper::ResetDoubleMBConfirmation(TEA &ea, bool baseReset)
{
    ResetSingleMBConfirmation(ea, baseReset);
    ea.mSecondMBInConfirmationNumber = EMPTY;
}

template <typename TEA>
static void EAHelper::ResetLiquidationMBConfirmation(TEA &ea, bool baseReset)
{
    ResetDoubleMBSetup(ea, baseReset);
    ea.mLiquidationMBInConfirmationNumber = EMPTY;
}
