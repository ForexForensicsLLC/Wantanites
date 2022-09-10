//+------------------------------------------------------------------+
//|                                                     EAHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\Index.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\Index.mqh>

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
    static void FindSetPreviousAndCurrentSetupTickets(TEA &ea);
    template <typename TEA, typename TRecord>
    static void UpdatePreviousSetupTicketsRRAcquried(TEA &ea);
    template <typename TEA, typename TRecord>
    static void SetPreviousSetupTicketsOpenData(TEA &ea);

    // =========================================================================
    // Run
    // =========================================================================
private:
    template <typename TEA>
    static void ManagePreviousSetupTickets(TEA &ea);
    template <typename TEA>
    static void ManageCurrentSetupTicket(TEA &ea);

public:
    template <typename TEA>
    static void Run(TEA &ea);
    template <typename TEA>
    static void RunDrawMBTs(TEA &ea, MBTracker *&mbtOne, MBTracker *&mbtTwo);
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
    static bool CheckSetFirstMB(TEA &ea, MBTracker *&mbt, int &mbNumber, int forcedType, int nthMB);
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
    static bool CheckSetSingleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType, bool calculateOnTick, int nthMB);
    template <typename TEA>
    static bool CheckSetDoubleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType, bool calculateOnTick, int nthMB);
    template <typename TEA>
    static bool CheckSetLiquidationMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber, int forcedType,
                                           bool calculateOnTick);

    template <typename TEA>
    static bool MBPushedFurtherIntoDeepestHoldingSetupZone(TEA &ea, int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, string &additionalInformation);
    template <typename TEA>
    static bool MBRetappedDeepestHoldingSetupZone(TEA &ea, int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, string &additionalInformation);

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
    static void CheckPartialPreviousSetupTicket(TEA &ea, int ticketIndex);

    // =========================================================================
    // Checking Tickets
    // =========================================================================
    template <typename TEA>
    static void CheckCurrentSetupTicket(TEA &ea);
    template <typename TEA>
    static void CheckPreviousSetupTicket(TEA &ea, int ticketIndex);

    template <typename TEA>
    static bool TicketStopLossIsMovedToBreakEven(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void SetOpenDataOnTicket(TEA &ea, Ticket *&ticket);

    // =========================================================================
    // Record Data
    // =========================================================================
private:
    template <typename TEA, typename TRecord>
    static void SetDefaultEntryTradeData(TEA &ea, TRecord &record);
    template <typename TEA, typename TRecord>
    static void SetDefaultCloseTradeData(TEA &ea, TRecord &record, Ticket &ticket, int entryTimeFrame);

public:
    template <typename TEA>
    static void RecordDefaultEntryTradeRecord(TEA &ea);
    template <typename TEA>
    static void RecordDefaultExitTradeRecord(TEA &ea, Ticket &ticket, int entryTimeFrame);

    template <typename TEA>
    static void RecordSingleTimeFrameEntryTradeRecord(TEA &ea);
    template <typename TEA>
    static void RecordSingleTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, int entryTimeFrame);

    template <typename TEA>
    static void RecordMultiTimeFrameEntryTradeRecord(TEA &ea, int higherTimeFrame);
    template <typename TEA>
    static void RecordMultiTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, int lowerTimeFrame, int higherTimeFrame);

    template <typename TEA>
    static void RecordPartialTradeRecord(TEA &ea, int oldTicketIndex, int newTicketNumber);

    template <typename TEA, typename TRecord>
    static void SetDefaultErrorRecordData(TEA &ea, TRecord &record, int error, string additionalInformation);
    template <typename TEA>
    static void RecordDefaultErrorRecord(TEA &ea, int error, string additionalInformation);
    template <typename TEA>
    static void RecordSingleTimeFrameErrorRecord(TEA &ea, int error, string additionalInformation);
    template <typename TEA>
    static void RecordMultiTimeFrameErrorRecord(TEA &ea, int error, string additionalInformation, int lowerTimeFrame, int highTimeFrame);
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
    ArrayFree(ea.mStrategyMagicNumbers);
    ArrayResize(ea.mStrategyMagicNumbers, 3);

    ea.mStrategyMagicNumbers[0] = MagicNumbers::BullishKataraSingleMB;
    ea.mStrategyMagicNumbers[1] = MagicNumbers::BullishKataraDoubleMB;
    ea.mStrategyMagicNumbers[2] = MagicNumbers::BullishKataraLiquidationMB;
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
static void EAHelper::FindSetPreviousAndCurrentSetupTickets(TEA &ea)
{
    ea.mLastState = EAStates::SETTING_ACTIVE_TICKETS;

    int tickets[];
    int findTicketsError = OrderHelper::FindActiveTicketsByMagicNumber(false, ea.MagicNumber(), tickets);
    if (findTicketsError != ERR_NO_ERROR)
    {
        ea.RecordError(findTicketsError);
    }

    for (int i = 0; i < ArraySize(tickets); i++)
    {
        Ticket *ticket = new Ticket(tickets[i]);
        ticket.SetPartials(ea.mPartialRRs, ea.mPartialPercents);

        if (ea.MoveToPreviousSetupTickets(ticket))
        {
            ea.mPreviousSetupTickets.Add(ticket);
        }
        else if (CheckPointer(ea.mCurrentSetupTicket) == POINTER_INVALID)
        {
            ea.mCurrentSetupTicket = ticket;
        }
        // we should only ever have 1 ticket at most that needs to be managed. If we have more, the EA isn't following its trading constraints
        else
        {
            ea.RecordError(TerminalErrors::MORE_THAN_ONE_UNMANAGED_TICKET);
            SendMail("Move than 1 unfinished managed ticket",
                     "Ticket 1: " + IntegerToString(ea.mCurrentSetupTicket.Number()) + "\n" +
                         "Ticket 2: " + IntegerToString(ticket.Number()) + "\n" +
                         "Check error records to make sure MoveToPreviousSetupTickets() didn't fail.");
        }
    }
}

template <typename TEA, typename TRecord>
static void EAHelper::UpdatePreviousSetupTicketsRRAcquried(TEA &ea)
{
    if (ea.mPreviousSetupTickets.Size() == 0)
    {
        return;
    }

    TRecord *record = new TRecord();

    ea.mPartialCSVRecordWriter.SeekToStart();
    while (!FileIsEnding(ea.mPartialCSVRecordWriter.FileHandle()))
    {
        record.ReadRow(ea.mPartialCSVRecordWriter.FileHandle());
        if (record.MagicNumber != ea.MagicNumber())
        {
            continue;
        }

        for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
        {
            // check for both in case the ticket was partialed more than once
            // only works with up to 2 partials
            if (record.TicketNumber == ea.mPreviousSetupTickets[i].Number() || record.NewTicketNumber == ea.mPreviousSetupTickets[i].Number())
            {
                ea.mPreviousSetupTickets[i].mPartials.RemovePartialRR(record.ExpectedPartialRR);
                break;
            }
        }
    }

    delete record;
}

template <typename TEA, typename TRecord>
static void EAHelper::SetPreviousSetupTicketsOpenData(TEA &ea)
{
    if (ea.mPreviousSetupTickets.Size() == 0 && ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    TRecord *record = new TRecord();
    bool foundCurrent = false;
    int previousTicketsFound = 0;

    ea.mEntryCSVRecordWriter.SeekToStart();
    while (!FileIsEnding(ea.mEntryCSVRecordWriter.FileHandle()))
    {
        record.ReadRow(ea.mEntryCSVRecordWriter.FileHandle());
        if (record.MagicNumber != ea.MagicNumber())
        {
            continue;
        }

        if (record.TicketNumber == ea.mCurrentSetupTicket.Number())
        {
            ea.mCurrentSetupTicket.OpenPrice(record.EntryPrice);
            ea.mCurrentSetupTicket.OpenTime(record.EntryTime);
            ea.mCurrentSetupTicket.Lots(record.Lots);
            ea.mCurrentSetupTicket.mOriginalStopLoss = record.EntryStopLoss;
        }

        for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
        {
            if (record.TicketNumber == ea.mPreviousSetupTickets[i].Number())
            {
                ea.mPreviousSetupTickets[i].OpenPrice(record.EntryPrice);
                ea.mPreviousSetupTickets[i].OpenTime(record.EntryTime);
                ea.mPreviousSetupTickets[i].Lots(record.Lots);
                ea.mPreviousSetupTickets[i].mOriginalStopLoss = record.EntryStopLoss;

                previousTicketsFound += 1;
                break;
            }
        }

        // found all possible tickets
        if ((ea.mCurrentSetupTicket.Number() == EMPTY || foundCurrent) && (previousTicketsFound == ea.mPreviousSetupTickets.Size()))
        {
            break;
        }
    }

    delete record;
}
/*

   ____
  |  _ \ _   _ _ __
  | |_) | | | | '_ \
  |  _ <| |_| | | | |
  |_| \_\\__,_|_| |_|


*/
template <typename TEA>
static void EAHelper::ManagePreviousSetupTickets(TEA &ea)
{
    // do 2 different loops since tickets can be clsoed and deleted in CheckPreviousSetupTickets.
    // can't manage tickets that were just closed and deleted
    for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
    {
        ea.CheckPreviousSetupTicket(i);
    }

    for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
    {
        ea.ManagePreviousSetupTicket(i);
    }
}

template <typename TEA>
static void EAHelper::ManageCurrentSetupTicket(TEA &ea)
{
    if (ea.mCurrentSetupTicket.Number() != EMPTY)
    {
        ea.CheckCurrentSetupTicket();
    }

    // Re check since the ticket could have closed between the here and the last call.
    if (ea.mCurrentSetupTicket.Number() != EMPTY)
    {
        bool isActive;
        int isActiveError = ea.mCurrentSetupTicket.IsActive(isActive);
        if (TerminalErrors::IsTerminalError(isActiveError))
        {
            ea.InvalidateSetup(false, isActiveError);
            return;
        }

        if (isActive)
        {
            ea.ManageCurrentActiveSetupTicket();
        }
        else
        {
            ea.ManageCurrentPendingSetupTicket();
        }
    }
}

template <typename TEA>
static void EAHelper::Run(TEA &ea)
{
    // This needs to be done first since the proceeding logic can depend on the ticket being activated or closed
    ManageCurrentSetupTicket(ea);

    if (ea.MoveToPreviousSetupTickets(ea.mCurrentSetupTicket))
    {
        Ticket *ticket = new Ticket(ea.mCurrentSetupTicket);

        ea.mPreviousSetupTickets.Add(ticket);
        ea.mCurrentSetupTicket.SetNewTicket(EMPTY);
    }

    ManagePreviousSetupTickets(ea);
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
        if (ea.mCurrentSetupTicket.Number() == EMPTY)
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
            int isActiveError = ea.mCurrentSetupTicket.IsActive(isActive);
            if (TerminalErrors::IsTerminalError(isActiveError))
            {
                ea.InvalidateSetup(false, isActiveError);
                return;
            }

            if (!isActive && !ea.Confirmation())
            {
                ea.mCurrentSetupTicket.Close();
                ea.mCurrentSetupTicket.SetNewTicket(EMPTY);
            }
        }
    }
    else
    {
        ea.CheckSetSetup();
    }
}

template <typename TEA>
static void EAHelper::RunDrawMBTs(TEA &ea, MBTracker *&mbtOne, MBTracker *&mbtTwo)
{
    mbtOne.DrawNMostRecentMBs(-1);
    mbtOne.DrawZonesForNMostRecentMBs(-1);

    mbtTwo.DrawNMostRecentMBs(-1);
    mbtTwo.DrawZonesForNMostRecentMBs(-1);

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
static bool EAHelper::CheckSetFirstMB(TEA &ea, MBTracker *&mbt, int &mbNumber, int forcedType = EMPTY, int nthMB = 0)
{
    ea.mLastState = EAStates::GETTING_FIRST_MB_IN_SETUP;

    MBState *mbOneTempState;
    if (!mbt.GetNthMostRecentMB(nthMB, mbOneTempState))
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
static bool EAHelper::CheckSetSingleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType = EMPTY, bool calculateOnTick = true, int nthMB = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (!calculateOnTick && !mbt.HasNewData())
    {
        return firstMBNumber != EMPTY;
    }

    if (firstMBNumber == EMPTY)
    {
        CheckSetFirstMB(ea, mbt, firstMBNumber, forcedType, nthMB);
    }

    return firstMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetDoubleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType = EMPTY, bool calculateOnTick = true,
                                            int nthMB = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (!calculateOnTick && !mbt.HasNewData())
    {
        return firstMBNumber != EMPTY && secondMBNumber != EMPTY;
    }

    if (firstMBNumber == EMPTY)
    {
        CheckSetSingleMBSetup(ea, mbt, firstMBNumber, forcedType, true, nthMB + 1);
    }

    if (secondMBNumber == EMPTY)
    {
        CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber);
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber, int forcedType = EMPTY,
                                                 bool calculateOnTick = true)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (!calculateOnTick && !mbt.HasNewData())
    {
        return firstMBNumber != EMPTY && secondMBNumber != EMPTY && liquidationMBNumber != EMPTY;
    }

    if (firstMBNumber == EMPTY || secondMBNumber == EMPTY)
    {
        CheckSetDoubleMBSetup(ea, mbt, firstMBNumber, secondMBNumber, forcedType, true, 1);
    }

    if (liquidationMBNumber == EMPTY)
    {
        CheckSetLiquidationMB(ea, mbt, secondMBNumber, liquidationMBNumber);
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY && liquidationMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(TEA &ea, int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, string &additionalInformation)
{
    ea.mLastState = EAStates::CHECKING_IF_PUSHED_FURTHER_INTO_ZONE;

    bool pushedFurtherIntoZone = false;
    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(setupMBNumber, nthConfirmationMB, setupMBT, confirmationMBT, pushedFurtherIntoZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        ea.InvalidateSetup(true, error);
    }

    if (pushedFurtherIntoZone)
    {
        additionalInformation += " MBs: " + confirmationMBT.MBsCreated() + " Pushed Further: " + pushedFurtherIntoZone;
        for (int i = 0; i < 5; i++)
        {
            MBState *tempMBState;
            confirmationMBT.GetNthMostRecentMB(i, tempMBState);

            additionalInformation += " MB: " + tempMBState.Number() + " Zone #: " + tempMBState.mSetupZoneNumber + " Pushed Further: " + tempMBState.mPushedFurtherIntoSetupZone;
        }
    }

    return pushedFurtherIntoZone;
}

template <typename TEA>
static bool EAHelper::MBRetappedDeepestHoldingSetupZone(TEA &ea, int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, string &additionalInformation)
{
    ea.mLastState = EAStates::CHECKING_IF_RETAPPED_ZONE;

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedDeepestHoldingSetupZone(setupMBNumber, nthConfirmationMB, setupMBT, confirmationMBT, retappedZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        ea.InvalidateSetup(true, error);
    }

    if (retappedZone)
    {
        additionalInformation += " MBs: " + confirmationMBT.MBsCreated() + " Retapped: " + retappedZone;
        for (int i = 0; i < 5; i++)
        {
            MBState *tempMBState;
            confirmationMBT.GetNthMostRecentMB(i, tempMBState);

            additionalInformation += " MB: " + tempMBState.Number() + " Zone #: " + tempMBState.mSetupZoneNumber + " In Setup Zone: " + tempMBState.mInsideSetupZone;
        }
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

    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    if (!deletePendingOrder)
    {
        return;
    }

    bool isActive = false;
    int isActiveError = ea.mCurrentSetupTicket.IsActive(isActive);

    // Only close the order if it is pending or else every active order would get closed
    // as soon as the setup is finished
    if (!isActive)
    {
        int closeError = ea.mCurrentSetupTicket.Close();
        if (TerminalErrors::IsTerminalError(closeError))
        {
            ea.RecordError(closeError);
        }

        ea.mCurrentSetupTicket.SetNewTicket(EMPTY);
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

    if (ea.mCurrentSetupTicket.Number() != EMPTY)
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

    ea.mCurrentSetupTicket.SetNewTicket(ticketNumber);
    ea.mCurrentSetupTicket.SetPartials(ea.mPartialRRs, ea.mPartialPercents);
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

    // also check if the mb number exist. If we invalidate the setup before our stop order gets hit, we would throw an error below
    // due to spread. Its safe to return since the MB was validated so the SL should be correct
    if (ea.mCurrentSetupTicket.Number() == EMPTY || !mbt.MBExists(mbNumber))
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, mbNumber, mbt, ea.mCurrentSetupTicket);

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

    // also check if the mb number exist. If we invalidate the setup before our stop order gets hit, we would throw an error below
    // due to spread. Its safe to return since the MB was validated so the SL should be correct
    if (ea.mCurrentSetupTicket.Number() == EMPTY || !mbt.MBExists(mbNumber))
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnBreakOfMB(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, mbNumber, mbt, ea.mCurrentSetupTicket);

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

    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    bool stopLossIsMovedBreakEven;
    int error = ea.mCurrentSetupTicket.StopLossIsMovedToBreakEven(stopLossIsMovedBreakEven);
    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(error);
        return;
    }

    if (stopLossIsMovedBreakEven)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_TRAIL_STOP_LOSS;

    bool succeeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, lastMBNumberInSetup, ea.mSetupType, mbt, ea.mCurrentSetupTicket, succeeeded);

    if (TerminalErrors::IsTerminalError(trailError))
    {
        ea.InvalidateSetup(false, trailError);
        return;
    }
}

/**
 * @brief Checks / partials a ticket. Should only be called if an EA has at least one partial set via EA.SetPartial() in a Startegy.mqh
 *
 * @tparam TEA
 * @param ea
 * @param ticketIndex
 */
template <typename TEA>
static void EAHelper::CheckPartialPreviousSetupTicket(TEA &ea, int ticketIndex)
{
    Ticket *tempTicket = ea.mPreviousSetupTickets[ticketIndex];

    // if we are in a buy, we look to sell which occurs at the bid. If we are in a sell, we look to buy which occurs at the ask
    double currentPrice = ea.mSetupType == OP_BUY ? Bid : Ask;
    double rr = MathAbs(currentPrice - tempTicket.OpenPrice()) / MathAbs(tempTicket.OpenPrice() - tempTicket.mOriginalStopLoss);

    if (rr < tempTicket.mPartials[0].mRR)
    {
        return;
    }

    int partialError = OrderHelper::PartialTicket(tempTicket.Number(), currentPrice, OrderLots(), tempTicket.mPartials[0].PercentAsDecimal());
    if (partialError != ERR_NO_ERROR)
    {
        ea.RecordError(partialError);
        return;
    }

    int newTicket = EMPTY;
    int searchError = OrderHelper::FindNewTicketAfterPartial(ea.MagicNumber(), tempTicket.OpenPrice(), tempTicket.OpenTime(), newTicket);
    if (searchError != ERR_NO_ERROR)
    {
        ea.RecordError(searchError);
    }

    if (newTicket == EMPTY)
    {
        ea.RecordError(TerminalErrors::UNABLE_TO_FIND_PARTIALED_TICKET);
        tempTicket.mPartials.Remove(0);

        return;
    }

    tempTicket.mRRAcquired = rr;
    ea.RecordTicketPartialData(ticketIndex, newTicket);
    tempTicket.mPartials.Remove(0);

    tempTicket.UpdateTicketNumber(newTicket);
}
/*

    ____ _               _      _____ _      _        _
   / ___| |__   ___  ___| | __ |_   _(_) ___| | _____| |_
  | |   | '_ \ / _ \/ __| |/ /   | | | |/ __| |/ / _ \ __|
  | |___| | | |  __/ (__|   <    | | | | (__|   <  __/ |_
   \____|_| |_|\___|\___|_|\_\   |_| |_|\___|_|\_\___|\__|


*/
template <typename TEA>
void EAHelper::CheckCurrentSetupTicket(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_TICKET;

    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_ACTIVE;

    bool activated;
    int activatedError = ea.mCurrentSetupTicket.WasActivatedSinceLastCheck(activated);
    if (TerminalErrors::IsTerminalError(activatedError))
    {
        ea.InvalidateSetup(false, activatedError);
        return;
    }

    if (activated)
    {
        SetOpenDataOnTicket(ea, ea.mCurrentSetupTicket);
        ea.RecordTicketOpenData();
    }

    ea.mLastState = EAStates::CHECKING_IF_TICKET_IS_CLOSED;

    bool closed;
    int closeError = ea.mCurrentSetupTicket.WasClosedSinceLastCheck(closed);
    if (TerminalErrors::IsTerminalError(closeError))
    {
        ea.InvalidateSetup(false, closeError);
        return;
    }

    if (closed)
    {
        ea.RecordTicketCloseData(ea.mCurrentSetupTicket);
        ea.InvalidateSetup(false);
        ea.mCurrentSetupTicket.SetNewTicket(EMPTY);
    }
}

template <typename TEA>
static void EAHelper::CheckPreviousSetupTicket(TEA &ea, int ticketIndex)
{
    ea.mLastState = EAStates::CHECKING_PREVIOUS_SETUP_TICKET;
    bool closed = false;
    int closeError = ea.mPreviousSetupTickets[ticketIndex].WasClosedSinceLastCheck(closed);
    if (TerminalErrors::IsTerminalError(closeError))
    {
        ea.RecordError(closeError);
        return;
    }

    if (closed)
    {
        ea.RecordTicketCloseData(ea.mPreviousSetupTickets[ticketIndex]);
        ea.mPreviousSetupTickets.Remove(ticketIndex);
    }
}

template <typename TEA>
static bool EAHelper::TicketStopLossIsMovedToBreakEven(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_IF_MOVED_TO_BREAK_EVEN;
    if (ticket.Number() == EMPTY)
    {
        return false;
    }

    bool stopLossIsMovedToBreakEven = false;
    int error = ticket.StopLossIsMovedToBreakEven(stopLossIsMovedToBreakEven);
    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(error);
    }

    return stopLossIsMovedToBreakEven;
}

template <typename TEA>
static void EAHelper::SetOpenDataOnTicket(TEA &ea, Ticket *&ticket)
{
    ea.mLastState = EAStates::SETTING_OPEN_DATA_ON_TICKET;

    int selectError = ticket.SelectIfOpen("Setting Open Data");
    if (selectError != ERR_NO_ERROR)
    {
        ea.RecordError(selectError);
        return;
    }

    ticket.OpenPrice(OrderOpenPrice());
    ticket.OpenTime(OrderOpenTime());
    ticket.Lots(OrderLots());
    ticket.mOriginalStopLoss = OrderStopLoss();
}
/*

   ____                        _   ____        _
  |  _ \ ___  ___ ___  _ __ __| | |  _ \  __ _| |_ __ _
  | |_) / _ \/ __/ _ \| '__/ _` | | | | |/ _` | __/ _` |
  |  _ <  __/ (_| (_) | | | (_| | | |_| | (_| | || (_| |
  |_| \_\___|\___\___/|_|  \__,_| |____/ \__,_|\__\__,_|


*/
template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultEntryTradeData(TEA &ea, TRecord &record)
{
    ea.mLastState = EAStates::RECORDING_ORDER_OPEN_DATA;

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ea.mCurrentSetupTicket.Number();
    record.Symbol = Symbol();
    record.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    record.AccountBalanceBefore = AccountBalance();
    record.Lots = OrderLots();
    record.EntryTime = OrderOpenTime();
    record.EntryPrice = OrderOpenPrice();
    record.EntryStopLoss = OrderStopLoss();
}

template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultCloseTradeData(TEA &ea, TRecord &record, Ticket &ticket, int entryTimeFrame)
{
    ea.mLastState = EAStates::RECORDING_ORDER_CLOSE_DATA;

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ticket.Number();

    // needed for computed properties
    record.Symbol = Symbol();
    record.EntryTimeFrame = entryTimeFrame;
    record.OrderType = OrderType() == 0 ? "Buy" : "Sell";
    record.EntryPrice = ticket.OpenPrice();
    record.EntryTime = ticket.OpenTime();
    record.EntryStopLoss = ticket.mOriginalStopLoss;

    record.AccountBalanceAfter = AccountBalance();
    record.ExitTime = OrderCloseTime();
    record.ExitPrice = OrderClosePrice();
    record.ExitStopLoss = OrderStopLoss();
}

template <typename TEA>
static void EAHelper::RecordDefaultEntryTradeRecord(TEA &ea)
{
    DefaultEntryTradeRecord *record = new DefaultEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, DefaultEntryTradeRecord>(ea, record);

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordDefaultExitTradeRecord(TEA &ea, Ticket &ticket, int entryTimeFrame)
{
    DefaultExitTradeRecord *record = new DefaultExitTradeRecord();
    SetDefaultCloseTradeData<TEA, DefaultExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameEntryTradeRecord(TEA &ea)
{
    SingleTimeFrameEntryTradeRecord *record = new SingleTimeFrameEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, SingleTimeFrameEntryTradeRecord>(ea, record);

    record.EntryImage = ScreenShotHelper::TryTakeScreenShot(ea.mEntryCSVRecordWriter.Directory());
    ea.mEntryCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, int entryTimeFrame)
{
    SingleTimeFrameExitTradeRecord *record = new SingleTimeFrameExitTradeRecord();
    SetDefaultCloseTradeData<TEA, SingleTimeFrameExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    record.ExitImage = ScreenShotHelper::TryTakeScreenShot(ea.mExitCSVRecordWriter.Directory());
    ea.mExitCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameEntryTradeRecord(TEA &ea, int higherTimeFrame)
{
    ea.RecordError(-100);

    MultiTimeFrameEntryTradeRecord *record = new MultiTimeFrameEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, MultiTimeFrameEntryTradeRecord>(ea, record);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mEntryCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != ERR_NO_ERROR)
    {
        // don't return here if we fail to take the screen shot. We still want to record the rest of the entry data
        ea.RecordError(error);
    }

    record.LowerTimeFrameEntryImage = lowerTimeFrameImage;
    record.HigherTimeFrameEntryImage = higherTimeFrameImage;

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, int lowerTimeFrame, int higherTimeFrame)
{
    ea.RecordError(-200);

    MultiTimeFrameExitTradeRecord *record = new MultiTimeFrameExitTradeRecord();
    SetDefaultCloseTradeData<TEA, MultiTimeFrameExitTradeRecord>(ea, record, ticket, lowerTimeFrame);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mExitCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != ERR_NO_ERROR)
    {
        // don't return here if we fail to take the screen shot. We still want to record the rest of the exit data
        ea.RecordError(error);
    }

    record.LowerTimeFrameExitImage = lowerTimeFrameImage;
    record.HigherTimeFrameExitImage = higherTimeFrameImage;

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordPartialTradeRecord(TEA &ea, int oldTicketIndex, int newTicketNumber)
{
    ea.mLastState = EAStates::RECORDING_PARTIAL_DATA;

    PartialTradeRecord *record = new PartialTradeRecord();

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ea.mPreviousSetupTickets[oldTicketIndex].Number();
    record.NewTicketNumber = newTicketNumber;
    record.ExpectedPartialRR = ea.mPreviousSetupTickets[oldTicketIndex].mPartials[0].mRR;
    record.ActualPartialRR = ea.mPreviousSetupTickets[oldTicketIndex].mRRAcquired;

    ea.mPartialCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultErrorRecordData(TEA &ea, TRecord &record, int error, string additionalInformation)
{
    record.MagicNumber = ea.MagicNumber();
    record.ErrorTime = TimeCurrent();
    record.Error = error;
    record.LastState = ea.mLastState;
    record.AdditionalInformation = additionalInformation;
}

template <typename TEA>
static void EAHelper::RecordDefaultErrorRecord(TEA &ea, int error, string additionalInformation)
{
    DefaultErrorRecord *record = new DefaultErrorRecord();
    SetDefaultErrorRecordData<TEA, DefaultErrorRecord>(ea, record, error, additionalInformation);

    ea.mErrorCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameErrorRecord(TEA &ea, int error, string additionalInformation)
{
    SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();
    SetDefaultErrorRecordData<TEA, SingleTimeFrameErrorRecord>(ea, record, error, additionalInformation);

    record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(ea.mErrorCSVRecordWriter.Directory());
    ea.mErrorCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameErrorRecord(TEA &ea, int error, string additionalInformation, int lowerTimeFrame, int higherTimeFrame)
{
    MultiTimeFrameErrorRecord *record = new MultiTimeFrameErrorRecord();
    SetDefaultErrorRecordData<TEA, MultiTimeFrameErrorRecord>(ea, record, error, additionalInformation);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int screenShotError = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mExitCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (screenShotError != ERR_NO_ERROR)
    {
        // don't record the error or else we could get stuck in an infinte loop
        lowerTimeFrameImage = "Error: " + IntegerToString(screenShotError);
        higherTimeFrameImage = "Error: " + IntegerToString(screenShotError);
    }

    record.LowerTimeFrameErrorImage = lowerTimeFrameImage;
    record.HigherTimeFrameErrorImage = higherTimeFrameImage;

    ea.mErrorCSVRecordWriter.WriteRecord(record);
    delete record;
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
