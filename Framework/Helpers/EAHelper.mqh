//+------------------------------------------------------------------+
//|                                                     EAHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

template <typename TEA>
class EAHelper
{
public:
    // =========================================================================
    // Filling Strategy Magic Numbers
    // =========================================================================
    static void FillSunriseShatterMagicNumbers(TEA &ea);

    static void FillBullishKataraMagicNumbers(TEA &ea);
    static void FillBearishKataraMagicNumbers(TEA &ea);

    // =========================================================================
    // Set Active Ticket
    // =========================================================================
    static void SetSingleActiveTicket(TEA &ea);

    // =========================================================================
    // Run
    // =========================================================================
    static void RunDrawMBT(TEA &ea);
    static void RunDrawMBTAndMRFTS(TEA &ea);

    // =========================================================================
    // Allowed To Trade
    // =========================================================================
    static bool BelowSpread(TEA &ea);
    static bool PastMinROCOpenTime(TEA &ea);

    // =========================================================================
    // Check Set Setup
    // =========================================================================
    static void CheckSetFirstMBInSetup(TEA &ea);
    static void CheckSetSecondMBInSetup(TEA &ea);
    static void CheckSetLiquidationMBInSetup(TEA &ea);

    static void CheckBreakAfterMinROC(TEA &ea);

    // =========================================================================
    // Check Stop Trading
    // =========================================================================
    static void CheckBrokeSingleMBRangeStart(TEA &ea);
    static void CheckBrokeSingleMBRangeEnd(TEA &ea);

    static void CheckBrokeDoubleMBRangeStart(TEA &ea);
    static void CheckBrokeDoubleMBRangeEnd(TEA &ea);

    static void CheckBrokeLiquidationRangeEnd(TEA &ea);

    static void CheckCrossedOpenPriceAfterMinROC(TEA &ea);

    // =========================================================================
    // Stop Trading
    // =========================================================================
    static void StopTrading(TEA &ea);

    // =========================================================================
    // Confirmation
    // =========================================================================
    static void SingleMBZoneHolding(TEA &ea);
    static void DoubleMBZoneHolding(TEA &ea);
    static void LiquidationMBZoneHolding(TEA &ea);

    // =========================================================================
    // Place Order
    // =========================================================================
    static void PlaceOrderOnSingleMB(TEA &ea);
    static void PlaceOrderForDoubleMB(TEA &ea);
    static void PlaceOrderForLiquidationMB(TEA &ea);

    // =========================================================================
    // Manage
    // =========================================================================
    static void CheckEditPendingOrderStopLoss(TEA &ea);
    static void CheckTrailWithMBs(TEA &ea);
    static void CheckPartial(TEA &ea);

    // =========================================================================
    // Check Ticket
    // =========================================================================
    static void CheckTicket(TEA &ea);

    // =========================================================================
    // Record Data
    // =========================================================================
    static void RecordPreOrderOpenData(TEA &ea);
    static void RecordPostOrderOpenData(TEA &ea);
    static void RecordOrderCloseData(TEA &ea);

    // =========================================================================
    // Reset
    // =========================================================================
    static void ResetSingleMBSetup(TEA &ea);
    static void ResetDoubleMBSetup(TEA &ea);
};
/*

   _____ _ _ _ _               ____  _             _                     __  __             _        _   _                 _
  |  ___(_) | (_)_ __   __ _  / ___|| |_ _ __ __ _| |_ ___  __ _ _   _  |  \/  | __ _  __ _(_) ___  | \ | |_   _ _ __ ___ | |__   ___ _ __ ___
  | |_  | | | | | '_ \ / _` | \___ \| __| '__/ _` | __/ _ \/ _` | | | | | |\/| |/ _` |/ _` | |/ __| |  \| | | | | '_ ` _ \| '_ \ / _ \ '__/ __|
  |  _| | | | | | | | | (_| |  ___) | |_| | | (_| | ||  __/ (_| | |_| | | |  | | (_| | (_| | | (__  | |\  | |_| | | | | | | |_) |  __/ |  \__ \
  |_|   |_|_|_|_|_| |_|\__, | |____/ \__|_|  \__,_|\__\___|\__, |\__, | |_|  |_|\__,_|\__, |_|\___| |_| \_|\__,_|_| |_| |_|_.__/ \___|_|  |___/
                       |___/                               |___/ |___/                |___/

*/
static void EAHelper::FillSunriseShatterMagicNumbers(TEA &ea)
{
    ArrayFree(ea.mStrategyMagicNumbers);
    ArrayResize(ea.mStrategyMagicNumbers, 3);

    ea.mStrategyMagicNumbers[0] = TheSunriseShatterSingleMB::MagicNumber;
    ea.mStrategyMagicNumbers[1] = TheSunriseShatterDoubleMB::MagicNumber;
    ea.mStrategyMagicNumbers[2] = TheSunriseShatterLiquidationMB::MagicNumber;
}

static void EAHelper::FillBullishKataraMagicNumbers(TEA &ea)
{
    // TDOD
}

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
static void EAHelper::SetSingleActiveTicket(TEA &ea)
{
    int tickets[];
    int findTicketsError = OrderHelper::FindActiveTicketsByMagicNumber(true, ea::MagicNumber, tickets);
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
static void EAHelper::RunDrawMBTAndMRFTS(TEA &ea)
{
    ea.mMBT.DrawNMostRecentMBs(1);
    ea.mMBT.DrawZonesForNMostRecentMBs(1);
    ea.mMRFTS.Draw();

    ea.CheckTicket();
    ea.Manage();
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
/*

      _    _ _                       _   _____       _____              _
     / \  | | | _____      _____  __| | |_   _|__   |_   _| __ __ _  __| | ___
    / _ \ | | |/ _ \ \ /\ / / _ \/ _` |   | |/ _ \    | || '__/ _` |/ _` |/ _ \
   / ___ \| | | (_) \ V  V /  __/ (_| |   | | (_) |   | || | | (_| | (_| |  __/
  /_/   \_\_|_|\___/ \_/\_/ \___|\__,_|   |_|\___/    |_||_|  \__,_|\__,_|\___|


*/
static bool EAHelper::BelowSpread(TEA &ea)
{
    return MarketInfo(Symbol(), MODE_SPREAD) / 10) <= ea.mMaxSpreadPips;
}
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
static bool EAHelper::SetFirstMBInSetup(TEA &ea)
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
static bool EAHelper::SetSecondMBInSetup(TEA &ea)
{
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
static void EAHelper::SetLiquidationMBInSetup(TEA &ea)
{
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
static bool EAHelper::CheckBreakAfterMinROC(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_FOR_BREAK_AFTER_MIN_ROC;

    bool isTrue = false;
    int setupError = SetupHelper::BreakAfterMinROC(ea.mMRFTS, ea.mMBT, isTrue);
    if (TerminalErrors::IsTerminalError(setupError))
    {
        ea.StopTrading(false, setupError);
        return;
    }

    return isTrue;
}
static bool EAHelper::CheckSetSingleMBAfterMinROCBreak(TEA &ea)
{
    if (CheckBreakAfterMinROC(ea))
    {
        if (SetFirstMBInSetup(ea))
        {
            return true;
        }
    }

    return false;
}
static void EAHelper::CheckSetDoubleMBAfterMinROCBreak(TEA &ea)
{
    if (ea.mFirstMBInSetupNumber == EMPTY)
    {
        CheckSetSingleMBAfterMinROCBreak(ea);
    }
    else if (ea.mSecondMBInSetupNumber == EMPTY)
    {
        if (SetSecondMBInSetup(ea))
        {
            return true;
        }
    }

    return false;
}
static void EAHelper::CheckSetLiquidationMBAfterMinROCBreak(TEA &ea)
{
    if (ea.mFirstMBInSetupNumber == EMPTY || ea.mSecondMBInSetupNumber == EMPTY)
    {
        CheckSetDoubleMBAfterMinROCBreak(ea);
    }
    else
    {
        if (SetLiquidationMBInSetup(ea))
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
static void CheckBrokeSingleMBRangeStart(TEA &ea)
{
}
static void CheckBrokeSingleMBRangeEnd(TEA &ea)
{
}
static void CheckBrokeDoubleMBRangeStart(TEA &ea)
{
}
static void CheckBrokeDoubleMBRangeEnd(TEA &ea)
{
}
static void CheckBrokeLiquidationRangeEnd(TEA &ea)
{
}
static void CheckCrossedOpenPriceAfterMinROC(TEA &ea)
{
}

template <typename TEA>
void EAHelper::CheckTicket(TEA &ea)
{
    ea.LastState = EAStates::CHECKING_TICKET;

    if (ea.mTicket.Number() == EMPTY)
    {
        return;
    }

    ea.LastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool activated;
    int activatedError = ea.mTicket.WasActivated(activated);
    if (TerminalErrors::IsTerminalError(activatedError))
    {
        ea.StopTrading(false, activatedError);
        return;
    }

    if (activated)
    {
        ea.RecordPostOrderOpenData();
    }

    ea.LastState = EAStates::CHECKING_IF_TICKET_IS_CLOSED;

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
        // CSVRecordWriter<DefaultTradeRecord>::Write();

        ea.StopTrading(false, 1);
        ea.mTicket.SetNewTicket(EMPTY);
    }
}