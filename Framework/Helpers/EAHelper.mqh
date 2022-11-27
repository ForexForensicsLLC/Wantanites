//+------------------------------------------------------------------+
//|                                                     EAHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\EAErrorHelper.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\Index.mqh>
#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\Index.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\ScreenShotHelper.mqh>
#include <SummitCapital\Framework\Helpers\CandleStickHelper.mqh>

#include <SummitCapital\Framework\Trackers\LiquidationSetupTracker.mqh>

class EAHelper
{
public:
    // Initialize
    static bool CheckSymbolAndTimeFrame(string expectedSymbol, int expectedTimeFrame);
    // =========================================================================
    // Filling Strategy Magic Numbers
    // =========================================================================
    template <typename TEA>
    static void FillSunriseShatterBearishMagicNumbers(TEA &ea);
    template <typename TEA>
    static void FillSunriseShatterBullishMagicNumbers(TEA &ea);

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
    static void RunDrawMBT(TEA &ea, MBTracker *&mbt);
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
    template <typename TEA>
    static bool WithinTradingSession(TEA &ea);

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
    static bool CheckSetSingleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType, int nthMB);
    template <typename TEA>
    static bool CheckSetDoubleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType);
    template <typename TEA>
    static bool CheckSetLiquidationMBSetup(TEA &ea, LiquidationSetupTracker *&lst, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber);

    template <typename TEA>
    static bool SetupZoneIsValidForConfirmation(TEA &ea, int setupMBNumber, int nthConfirmationMB, string &additionalInformation);

    template <typename TEA>
    static bool CheckSetFirstMBBreakAfterConsecutiveMBs(TEA &ea, MBTracker *&mbt, int conseuctiveMBs, int &firstMBNumber);

    template <typename TEA>
    static bool CandleIsWithinSession(TEA &ea, string symbol, int timeFrame, int index);
    template <typename TEA>
    static bool MBWasCreatedAfterSessionStart(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static bool RunningBigDipperSetup(TEA &ea, datetime startTime);

    // =========================================================================
    // Check Invalidate Setup
    // =========================================================================
public:
    template <typename TEA>
    static bool CheckBrokeMBRangeStart(TEA &ea, MBTracker *&mbt, int mbNumber);
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
    static int LiquidationMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber, bool &hasConfirmation);

    template <typename TEA>
    static bool DojiInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, int dojiCandleIndex);
    template <typename TEA>
    static int DojiBreakInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation);
    template <typename TEA>
    static bool DojiInsideLiquidationSetupMBsHoldingZone(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber);
    template <typename TEA>
    static int ImbalanceDojiInZone(TEA &ea, MBTracker *&mbt, int mbNumber, int numberOfCandlesBackForPossibleImbalance, double minPercentROC, bool &hasConfirmation);
    template <typename TEA>
    static int EngulfingCandleInZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation);
    template <typename TEA>
    static int DojiConsecutiveCandles(TEA &ea, MBTracker *&mbt, int mbNumber, int consecutiveCandlesAfter, bool &hasConfirmation);
    template <typename TEA>
    static bool CandleIsBigDipper(TEA &ea, int bigDipperIndex);

    template <typename TEA>
    static bool MBWithinWidth(TEA &ea, MBTracker *mbt, int mbNumber, int minWidth, int maxWidth);
    template <typename TEA>
    static bool MBWithinHeight(TEA &ea, MBTracker *mbt, int mbNumber, double minHeight, double maxHeight);
    template <typename TEA>
    static bool MBWithinPipsPerCandle(TEA &ea, MBTracker *mbt, int mbNumber, double minPipsPerCandle, double maxPipsPerCandle);
    template <typename TEA>
    static bool PriceIsFurtherThanPercentIntoMB(TEA &ea, MBTracker *mbt, int mbNumber, double price, double percentAsDecimal);
    template <typename TEA>
    static bool PriceIsFurtherThanPercentIntoHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, double price, double percentAsDecimal);
    template <typename TEA>
    static bool CandleIsInZone(TEA &ea, MBTracker *mbt, int mbNumber, int candleIndex, bool furthest);
    // =========================================================================
    // Place Order
    // =========================================================================
    template <typename TEA>
    static double GetReducedRiskPerPercentLost(TEA &ea, double perPercentLost, double reduceBy);
    template <typename TEA>
    static bool PrePlaceOrderChecks(TEA &ea);
    template <typename TEA>
    static void PostPlaceOrderChecks(TEA &ea, int ticketNumber, int error);

    template <typename TEA>
    static void PlaceMarketOrder(TEA &ea, double entry, double stopLoss, double lots);
    template <typename TEA>
    static void PlaceStopOrder(TEA &ea, double entry, double stopLoss, double lots, bool fallbackMarketOrder, double maxMarketOrderSlippage);

    template <typename TEA>
    static void PlaceStopOrderForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static void PlaceStopOrderForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static void PlaceStopOrderForPendingLiquidationSetupValidation(TEA &ea, MBTracker *&mbt, int liquidationMBNumber);

    template <typename TEA>
    static void PlaceStopOrderForCandelBreak(TEA &ea, string symbol, int timeFrame, datetime entryCandleTime, datetime stopLossCandleTime);
    template <typename TEA>
    static void PlaceMarketOrderForCandleSetup(TEA &ea, string symbol, int timeFrame, datetime stopLossCandleTime);
    template <typename TEA>
    static void PlaceMarketOrderForMostRecentMB(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static void PlaceStopOrderForTheLittleDipper(TEA &ea);

    // =========================================================================
    // Manage Pending Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckEditStopLossForPendingMBValidation(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static void CheckEditStopLossForBreakOfMB(TEA &ea, MBTracker *&mbt, int mbNumber);
    template <typename TEA>
    static void CheckEditStopLossForLiquidationMBSetup(TEA &ea, MBTracker *&mbt, int liquidationMBNumber);
    template <typename TEA>
    static void CheckEditStopLossForTheLittleDipper(TEA &ea);

    template <typename TEA>
    static void CheckBrokePastCandle(TEA &ea, string symbol, int timeFrame, int type, datetime candleTime);
    // =========================================================================
    // Manage Active Ticket
    // =========================================================================
    template <typename TEA>
    static void CheckTrailStopLossWithMBs(TEA &ea, MBTracker *&mbt, int lastMBNumberInSetup);
    template <typename TEA>
    static void MoveToBreakEvenWithCandleFurtherThanEntry(TEA &ea, bool waitForCandleClose);
    template <typename TEA>
    static void MoveToBreakEvenAfterNextSameTypeMBValidation(TEA &ea, Ticket &ticket, MBTracker *&mbt, int entryMB);
    template <typename TEA>
    static void CheckPartialTicket(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void CloseIfPriceCrossedTicketOpen(TEA &ea, int candlesAfterBeforeChecking);
    template <typename TEA>
    static void MoveToBreakEvenAsSoonAsPossible(TEA &ea, double waitForAdditionalPips);
    template <typename TEA>
    static void MoveStopLossToCoverCommissions(TEA &ea);
    template <typename TEA>
    static bool CloseIfPercentIntoStopLoss(TEA &ea, Ticket &ticket, double percent);

    template <typename TEA>
    static bool TicketStopLossIsMovedToBreakEven(TEA &ea, Ticket &ticket);

    // =========================================================================
    // Checking Tickets
    // =========================================================================
    template <typename TEA>
    static void CheckCurrentSetupTicket(TEA &ea);
    template <typename TEA>
    static void CheckPreviousSetupTicket(TEA &ea, int ticketIndex);
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
    static void RecordMBEntryTradeRecord(TEA &ea, int mbNumber, MBTracker *&mbt, int mbCount, int zoneNumber);

    template <typename TEA>
    static void RecordPartialTradeRecord(TEA &ea, Ticket &partialedTicket, int newTicketNumber);

    template <typename TEA, typename TRecord>
    static void SetDefaultErrorRecordData(TEA &ea, TRecord &record, int error, string additionalInformation);
    template <typename TEA>
    static void RecordDefaultErrorRecord(TEA &ea, int error, string additionalInformation);
    template <typename TEA>
    static void RecordSingleTimeFrameErrorRecord(TEA &ea, int error, string additionalInformation);
    template <typename TEA>
    static void RecordMultiTimeFrameErrorRecord(TEA &ea, int error, string additionalInformation, int lowerTimeFrame, int highTimeFrame);

    template <typename TEA>
    static void CheckUpdateHowFarPriceRanFromOpen(TEA &ea, Ticket &ticket);
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

static bool EAHelper::CheckSymbolAndTimeFrame(string expectedSymbol, int expectedTimeFrame)
{
    if (StringFind(Symbol(), expectedSymbol) == -1)
    {
        Print("Incorrect Symbol: ", Symbol(), ". Expected: ", expectedSymbol);
        return false;
    }

    if (Period() != expectedTimeFrame)
    {
        Print("Incorrect Time Frame: ", Period(), ". Expected: ", expectedTimeFrame);
        return false;
    }

    return true;
}

/*

   _____ _ _ _ _               ____  _             _                     __  __             _        _   _                 _
  |  ___(_) | (_)_ __   __ _  / ___|| |_ _ __ __ _| |_ ___  __ _ _   _  |  \/  | __ _  __ _(_) ___  | \ | |_   _ _ __ ___ | |__   ___ _ __ ___
  | |_  | | | | | '_ \ / _` | \___ \| __| '__/ _` | __/ _ \/ _` | | | | | |\/| |/ _` |/ _` | |/ __| |  \| | | | | '_ ` _ \| '_ \ / _ \ '__/ __|
  |  _| | | | | | | | | (_| |  ___) | |_| | | (_| | ||  __/ (_| | |_| | | |  | | (_| | (_| | | (__  | |\  | |_| | | | | | | |_) |  __/ |  \__ \
  |_|   |_|_|_|_|_| |_|\__, | |____/ \__|_|  \__,_|\__\___|\__, |\__, | |_|  |_|\__,_|\__, |_|\___| |_| \_|\__,_|_| |_| |_|_.__/ \___|_|  |___/
                       |___/                               |___/ |___/                |___/

*/
template <typename TEA>
static void EAHelper::FillSunriseShatterBearishMagicNumbers(TEA &ea)
{
    ArrayFree(ea.mStrategyMagicNumbers);
    ArrayResize(ea.mStrategyMagicNumbers, 3);

    ea.mStrategyMagicNumbers[0] = MagicNumbers::TheSunriseShatterBearishSingleMB;
    ea.mStrategyMagicNumbers[1] = MagicNumbers::TheSunriseShatterBearishDoubleMB;
    ea.mStrategyMagicNumbers[2] = MagicNumbers::TheSunriseShatterBearishLiquidationMB;
}

template <typename TEA>
static void EAHelper::FillSunriseShatterBullishMagicNumbers(TEA &ea)
{
    ArrayFree(ea.mStrategyMagicNumbers);
    ArrayResize(ea.mStrategyMagicNumbers, 3);

    ea.mStrategyMagicNumbers[0] = MagicNumbers::TheSunriseShatterBullishSingleMB;
    ea.mStrategyMagicNumbers[1] = MagicNumbers::TheSunriseShatterBullishDoubleMB;
    ea.mStrategyMagicNumbers[2] = MagicNumbers::TheSunriseShatterBullishLiquidationMB;
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
                // ea.mPreviousSetupTickets[i].mPartials.RemovePartialRR(record.ExpectedPartialRR);
                ea.mPreviousSetupTickets[i].mPartials.RemoveWhere<TPartialRRLocator, double>(Partial::FindPartialByRR, record.ExpectedPartialRR);
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

    ea.mEntryCSVRecordWriter.SeekToStart();
    while (!FileIsEnding(ea.mEntryCSVRecordWriter.FileHandle()))
    {
        record.ReadRow(ea.mEntryCSVRecordWriter.FileHandle());

        // needed for dynamic risk calculations
        if (record.AccountBalanceBefore > ea.mLargestAccountBalance)
        {
            ea.mLargestAccountBalance = record.AccountBalanceBefore;
        }

        if (record.MagicNumber != ea.MagicNumber())
        {
            continue;
        }

        if (record.TicketNumber == ea.mCurrentSetupTicket.Number())
        {
            ea.mCurrentSetupTicket.OpenPrice(record.EntryPrice);
            ea.mCurrentSetupTicket.OpenTime(record.EntryTime);
            ea.mCurrentSetupTicket.Lots(record.Lots);
            ea.mCurrentSetupTicket.mOriginalStopLoss = record.OriginalStopLoss;
        }

        for (int i = 0; i < ea.mPreviousSetupTickets.Size(); i++)
        {
            if (record.TicketNumber == ea.mPreviousSetupTickets[i].Number())
            {
                ea.mPreviousSetupTickets[i].OpenPrice(record.EntryPrice);
                ea.mPreviousSetupTickets[i].OpenTime(record.EntryTime);
                ea.mPreviousSetupTickets[i].Lots(record.Lots);
                ea.mPreviousSetupTickets[i].mOriginalStopLoss = record.OriginalStopLoss;

                break;
            }
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
    for (int i = ea.mPreviousSetupTickets.Size() - 1; i >= 0; i--)
    {
        ea.CheckPreviousSetupTicket(i);
    }

    for (int i = ea.mPreviousSetupTickets.Size() - 1; i >= 0; i--)
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

    // Re check since the ticket could have closed between here and the last call.
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

    if (ea.mCurrentSetupTicket.Number() != EMPTY && ea.MoveToPreviousSetupTickets(ea.mCurrentSetupTicket))
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

    ea.mWasReset = false;

    if (!ea.mHasSetup)
    {
        ea.CheckSetSetup();
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

            bool wasActivated;
            int wasActivatedError = ea.mCurrentSetupTicket.WasActivated(wasActivated);
            if (TerminalErrors::IsTerminalError(wasActivatedError))
            {
                ea.InvalidateSetup(false, wasActivatedError);
                return;
            }

            if (!wasActivated && !ea.Confirmation())
            {
                ea.mCurrentSetupTicket.Close();
                ea.mCurrentSetupTicket.SetNewTicket(EMPTY);
            }
        }
    }
}

template <typename TEA>
static void EAHelper::RunDrawMBT(TEA &ea, MBTracker *&mbt)
{
    mbt.DrawNMostRecentMBs(-1);
    mbt.DrawZonesForNMostRecentMBs(-1);

    Run(ea);
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

template <typename TEA>
static bool EAHelper::WithinTradingSession(TEA &ea)
{
    for (int i = 0; i < ea.mTradingSessions.Size(); i++)
    {
        if (ea.mTradingSessions[i].CurrentlyWithinSession())
        {
            return true;
        }
    }

    return false;
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

    // don't allow any setups where the first mb is broken. This mainly affects liquidation setups
    if (mbOneTempState.GlobalStartIsBroken())
    {
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
        firstMBNumber = EMPTY;
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
    ea.mLastState = EAStates::CHECKING_FOR_SINGLE_MB_SETUP;

    if (firstMBNumber == EMPTY)
    {
        if (CheckBreakAfterMinROC(ea, mbt))
        {
            return CheckSetFirstMB(ea, mbt, firstMBNumber);
        }
    }

    return firstMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetDoubleMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY)
    {
        CheckSetFirstMBAfterMinROCBreak(ea, mbt, firstMBNumber);
    }

    if (secondMBNumber == EMPTY)
    {
        return CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber);
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == EMPTY || secondMBNumber == EMPTY)
    {
        CheckSetDoubleMBAfterMinROCBreak(ea, mbt, firstMBNumber, secondMBNumber);
    }

    if (firstMBNumber != EMPTY && secondMBNumber != EMPTY && liquidationMBNumber == EMPTY)
    {
        return CheckSetLiquidationMB(ea, mbt, secondMBNumber, liquidationMBNumber);
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY && liquidationMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetSingleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType = EMPTY, int nthMB = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_SINGLE_MB_SETUP;

    if (firstMBNumber == EMPTY)
    {
        CheckSetFirstMB(ea, mbt, firstMBNumber, forcedType, nthMB);
    }

    return firstMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetDoubleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType = EMPTY)
{
    ea.mLastState = EAStates::CHECKING_FOR_DOUBLE_MB_SETUP;

    if (firstMBNumber == EMPTY)
    {
        CheckSetSingleMBSetup(ea, mbt, firstMBNumber, forcedType, 1);
    }

    if (secondMBNumber == EMPTY)
    {
        CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber);
    }

    return firstMBNumber != EMPTY && secondMBNumber != EMPTY;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBSetup(TEA &ea, LiquidationSetupTracker *&lst, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_LIQUIDATION_MB_SETUP;
    return lst.HasSetup(firstMBNumber, secondMBNumber, liquidationMBNumber);
}

template <typename TEA>
static bool EAHelper::SetupZoneIsValidForConfirmation(TEA &ea, int setupMBNumber, int nthConfirmationMB, string &additionalInformation)
{
    ea.mLastState = EAStates::CHECKING_IF_SETUP_ZONE_IS_VALID_FOR_CONFIRMATION;

    bool isTrue = false;
    int error = SetupHelper::SetupZoneIsValidForConfirmation(setupMBNumber, nthConfirmationMB, ea.mSetupMBT, ea.mConfirmationMBT, isTrue, additionalInformation);
    if (TerminalErrors::IsTerminalError(error))
    {
        ea.RecordError(error);
    }

    return isTrue;
}

template <typename TEA>
static bool EAHelper::CheckSetFirstMBBreakAfterConsecutiveMBs(TEA &ea, MBTracker *&mbt, int conseuctiveMBs, int &firstMBNumber)
{
    if (mbt.NumberOfConsecutiveMBsBeforeNthMostRecent(0) < conseuctiveMBs)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mbt.NthMostRecentMBIsOpposite(0, tempMBState))
    {
        return false;
    }

    firstMBNumber = tempMBState.Number();
    return true;
}

template <typename TEA>
static bool EAHelper::CandleIsWithinSession(TEA &ea, string symbol, int timeFrame, int index)
{
    string startTimeString = ea.mTradingSessions[0].HourStart() + ":" + ea.mTradingSessions[0].MinuteStart();
    datetime startTime = StringToTime(startTimeString);

    return iTime(symbol, timeFrame, index) >= startTime;
}

template <typename TEA>
static bool EAHelper::MBWasCreatedAfterSessionStart(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    return CandleIsWithinSession(ea, tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.StartIndex());
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
static bool EAHelper::CheckBrokeMBRangeStart(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_START;

    if (mbNumber != EMPTY && mbt.MBExists(mbNumber))
    {
        bool brokeRangeStart;
        int brokeRangeStartError = mbt.MBStartIsBroken(mbNumber, brokeRangeStart);
        if (TerminalErrors::IsTerminalError(brokeRangeStartError))
        {
            ea.RecordError(brokeRangeStartError);
            return true;
        }

        if (brokeRangeStart)
        {
            return true;
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckBrokeMBRangeEnd(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::CHECKING_IF_BROKE_RANGE_END;

    if (mbNumber != EMPTY && mbt.MBExists(mbNumber))
    {
        bool brokeRangeEnd = false;
        int brokeRangeEndError = mbt.MBEndIsBroken(mbNumber, brokeRangeEnd);
        if (TerminalErrors::IsTerminalError(brokeRangeEndError))
        {
            ea.RecordError(brokeRangeEndError);
            return true;
        }

        if (brokeRangeEnd)
        {
            return true;
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CheckCrossedOpenPriceAfterMinROC(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC;

    if (ea.mMRFTS.CrossedOpenPriceAfterMinROC())
    {
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

    bool wasActivated = false;
    int wasActivatedError = ea.mCurrentSetupTicket.WasActivated(wasActivated);

    // Only close the order if it is pending or else every active order would get closed
    // as soon as the setup is finished
    if (!wasActivated)
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

    bool isHolding = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(mbNumber, mbt, isHolding);
    if (confirmationError != ERR_NO_ERROR)
    {
        ea.RecordError(confirmationError);
    }

    return isHolding;
}

template <typename TEA>
static int EAHelper::LiquidationMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(firstMBNumber, secondMBNumber, mbt, hasConfirmation);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return confirmationError;
    }

    return ERR_NO_ERROR;
}

template <typename TEA>
static bool EAHelper::DojiInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, int dojiCandleIndex = 1)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        EAErrorHelper::RecordFailedMBRetrievalError(ea, mbt, mbNumber, ExecutionErrors::MB_IS_NOT_MOST_RECENT);
        return false;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        EAErrorHelper::RecordFailedMBRetrievalError(ea, mbt, mbNumber);
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    bool dojiInZone = false;
    if (tempMBState.Type() == OP_BUY)
    {
        double low = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex);
        double bodyLow = MathMin(iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex), iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex));
        dojiInZone = SetupHelper::HammerCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex) &&
                     (low <= tempZoneState.EntryPrice() && bodyLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        double high = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex);
        double bodyHigh = MathMax(iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex), iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex));
        dojiInZone = SetupHelper::ShootingStarCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiCandleIndex) &&
                     (high >= tempZoneState.EntryPrice() && bodyHigh <= tempZoneState.ExitPrice());
    }

    return dojiInZone;
}

template <typename TEA>
static int EAHelper::DojiBreakInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    hasConfirmation = false;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return ERR_NO_ERROR;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        double dojiLow = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), 2);
        hasConfirmation = SetupHelper::HammerCandleStickPatternBreak(tempMBState.Symbol(), tempMBState.TimeFrame()) &&
                          (dojiLow <= tempZoneState.EntryPrice() && dojiLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        double dojiHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), 2);
        hasConfirmation = SetupHelper::ShootingStarCandleStickPatternBreak(tempMBState.Symbol(), tempMBState.TimeFrame()) &&
                          (dojiHigh >= tempZoneState.EntryPrice() && dojiHigh <= tempZoneState.ExitPrice());
    }

    return ERR_NO_ERROR;
}

template <typename TEA>
static bool EAHelper::DojiInsideLiquidationSetupMBsHoldingZone(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool holdingZone = false;
    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(firstMBNumber, secondMBNumber, mbt, holdingZone);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return false;
    }

    if (!holdingZone)
    {
        return false;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(firstMBNumber, tempMBState))
    {
        EAErrorHelper::RecordFailedMBRetrievalError(ea, mbt, firstMBNumber);
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    bool dojiInLiqudiationSetupZone = false;
    if (tempMBState.Type() == OP_BUY)
    {
        double dojiLow = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        double bodyLow = MathMin(iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 1), iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 1));

        dojiInLiqudiationSetupZone = SetupHelper::HammerCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                                     (dojiLow <= tempZoneState.EntryPrice() && bodyLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        double dojiHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        double bodyHigh = MathMax(iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 1), iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 1));

        dojiInLiqudiationSetupZone = SetupHelper::ShootingStarCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                                     (dojiHigh >= tempZoneState.EntryPrice() && bodyHigh <= tempZoneState.ExitPrice());
    }

    return dojiInLiqudiationSetupZone;
}

template <typename TEA>
static int EAHelper::ImbalanceDojiInZone(TEA &ea, MBTracker *&mbt, int mbNumber, int numberOfCandlesBackForPossibleImbalance, double minPercentROC, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    hasConfirmation = false;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return ERR_NO_ERROR;
    }

    int entryCandle = 1;
    bool hadMinPercentChange = false;

    // plus one since we are looking on candles before our entry. Do <= since we are calculating on the candles
    for (int i = entryCandle + 1; i <= entryCandle + numberOfCandlesBackForPossibleImbalance; i++)
    {
        double percentChanged = (iOpen(Symbol(), Period(), i) - iClose(Symbol(), Period(), i)) / iOpen(Symbol(), Period(), i);
        if (MathAbs(percentChanged) >= (minPercentROC / 100))
        {
            hadMinPercentChange = true;
            ea.mImbalanceCandlePercentChange = percentChanged;

            break;
        }
    }

    if (!hadMinPercentChange)
    {
        return ERR_NO_ERROR;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        bool hasImbalance = false;
        for (int i = entryCandle; i < entryCandle + numberOfCandlesBackForPossibleImbalance; i++)
        {
            if (iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, i + 2) > iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, i))
            {
                hasImbalance = true;
                break;
            }
        }

        if (!hasImbalance)
        {
            return ERR_NO_ERROR;
        }

        double previousLow = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        hasConfirmation = SetupHelper::HammerCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                          (previousLow <= tempZoneState.EntryPrice() && previousLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        bool hasImbalance = false;
        for (int i = entryCandle; i < entryCandle + numberOfCandlesBackForPossibleImbalance; i++)
        {
            if (iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), i + 2) < iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), i))
            {
                hasImbalance = true;
                break;
            }
        }

        if (!hasImbalance)
        {
            return ERR_NO_ERROR;
        }

        double previousHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        hasConfirmation = SetupHelper::ShootingStarCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                          (previousHigh >= tempZoneState.EntryPrice() && previousHigh <= tempZoneState.ExitPrice());
    }

    return ERR_NO_ERROR;
}

template <typename TEA>
static int EAHelper::EngulfingCandleInZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    hasConfirmation = false;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return ERR_NO_ERROR;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        double low = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        double bodyLow = MathMin(iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 1), iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 1));

        hasConfirmation = SetupHelper::BullishEngulfing(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                          (low <= tempZoneState.EntryPrice() && bodyLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        double high = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        double bodyHigh = MathMax(iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), 1), iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), 1));

        hasConfirmation = SetupHelper::BearishEngulfing(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                          (high >= tempZoneState.EntryPrice() && bodyHigh <= tempZoneState.ExitPrice());
    }

    return ERR_NO_ERROR;
}

template <typename TEA>
static int EAHelper::DojiConsecutiveCandles(TEA &ea, MBTracker *&mbt, int mbNumber, int consecutiveCandlesAfter, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    hasConfirmation = false;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return ERR_NO_ERROR;
    }

    int dojiIndex = consecutiveCandlesAfter + 1;
    if (tempMBState.Type() == OP_BUY)
    {
        for (int i = 1; i < dojiIndex; i++)
        {
            // return false if we have a bearish candle
            if (iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), i) > iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), i))
            {
                return ERR_NO_ERROR;
            }
        }

        double dojiLow = iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiIndex);
        hasConfirmation = SetupHelper::HammerCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiIndex) &&
                          (dojiLow <= tempZoneState.EntryPrice() && dojiLow >= tempZoneState.ExitPrice());
    }
    else if (tempZoneState.Type() == OP_SELL)
    {
        for (int i = 1; i < dojiIndex; i++)
        {
            // return false if we have a bullish candle
            if (iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), i) < iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), i))
            {
                return ERR_NO_ERROR;
            }
        }

        double dojiHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiIndex);
        hasConfirmation = SetupHelper::ShootingStarCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiIndex) &&
                          (dojiHigh >= tempZoneState.EntryPrice() && dojiHigh <= tempZoneState.ExitPrice());
    }

    return ERR_NO_ERROR;
}

// single big dipper candle
template <typename TEA>
static bool EAHelper::CandleIsBigDipper(TEA &ea, int bigDipperIndex = 1)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool hasConfirmation = false;

    if (ea.mSetupType == OP_BUY)
    {
        bool twoPreviousIsBullish = CandleStickHelper::IsBullish(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex + 1);
        bool previousIsBearish = CandleStickHelper::IsBearish(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex);
        bool previousDoesNotBreakBelowTwoPrevious = iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex) > iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex + 1);

        hasConfirmation = twoPreviousIsBullish && previousIsBearish && previousDoesNotBreakBelowTwoPrevious;
    }
    else if (ea.mSetupType == OP_SELL)
    {
        bool twoPreviousIsBearish = CandleStickHelper::IsBearish(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex + 1);
        bool previousIsBullish = CandleStickHelper::IsBullish(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex);
        bool previousDoesNotBreakAboveTwoPrevious = iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex) < iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex + 1);

        hasConfirmation = twoPreviousIsBearish && previousIsBullish && previousDoesNotBreakAboveTwoPrevious;
    }

    return hasConfirmation;
}

// can be multiple candels as long as they keep retracing
template <typename TEA>
static bool EAHelper::RunningBigDipperSetup(TEA &ea, datetime startTime)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    int startIndex = iBarShift(ea.mEntrySymbol, ea.mEntryTimeFrame, startTime);
    bool brokeFurtherThanCandle = false;
    int oppositeCandleIndex = EMPTY;

    if (ea.mSetupType == OP_BUY)
    {
        for (int i = startIndex; i > 0; i--)
        {
            if (!brokeFurtherThanCandle &&
                iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, i) > iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, i + 1))
            {
                brokeFurtherThanCandle = true;
                continue;
            }

            if (brokeFurtherThanCandle && CandleStickHelper::IsBearish(ea.mEntrySymbol, ea.mEntryTimeFrame, i))
            {
                ea.mFirstOppositeCandleTime = iTime(ea.mEntrySymbol, ea.mEntryTimeFrame, i);
                return true;
            }
        }
    }
    else if (ea.mSetupType == OP_SELL)
    {
        for (int i = startIndex; i > 0; i--)
        {
            if (!brokeFurtherThanCandle &&
                iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, i) < iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, i + 1))
            {
                brokeFurtherThanCandle = true;
                continue;
            }

            if (brokeFurtherThanCandle && CandleStickHelper::IsBullish(ea.mEntrySymbol, ea.mEntryTimeFrame, i))
            {
                ea.mFirstOppositeCandleTime = iTime(ea.mEntrySymbol, ea.mEntryTimeFrame, i);
                return true;
            }
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::MBWithinWidth(TEA &ea, MBTracker *mbt, int mbNumber, int minWidth = 0, int maxWidth = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    bool greaterThanMin = true;
    bool lessThanMax = true;

    if (minWidth > 0)
    {
        greaterThanMin = tempMBState.Width() >= minWidth;
    }

    if (maxWidth > 0)
    {
        lessThanMax = tempMBState.Width() <= maxWidth;
    }

    return greaterThanMin && lessThanMax;
}

template <typename TEA>
static bool EAHelper::MBWithinHeight(TEA &ea, MBTracker *mbt, int mbNumber, double minHeightPips = 0.0, double maxHeightPips = 0.0)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    bool greaterThanMin = true;
    bool lessThanMax = true;

    if (minHeightPips > 0.0)
    {
        greaterThanMin = tempMBState.Height() >= OrderHelper::PipsToRange(minHeightPips);
    }

    if (maxHeightPips > 0.0)
    {
        lessThanMax = tempMBState.Height() <= OrderHelper::PipsToRange(maxHeightPips);
    }

    return greaterThanMin && lessThanMax;
}

template <typename TEA>
static bool EAHelper::MBWithinPipsPerCandle(TEA &ea, MBTracker *mbt, int mbNumber, double minPipsPerCandle, double maxPipsPerCandle)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    return tempMBState.PipsPerCandle() >= minPipsPerCandle && tempMBState.PipsPerCandle() <= maxPipsPerCandle;
}

template <typename TEA>
static bool EAHelper::PriceIsFurtherThanPercentIntoMB(TEA &ea, MBTracker *mbt, int mbNumber, double price, double percentAsDecimal)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        EAErrorHelper::RecordFailedMBRetrievalError(ea, mbt, mbNumber);
        return false;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        return price <= tempMBState.PercentOfMBPrice(percentAsDecimal);
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        return price >= tempMBState.PercentOfMBPrice(percentAsDecimal);
    }

    return false;
}

template <typename TEA>
static bool EAHelper::PriceIsFurtherThanPercentIntoHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, double price, double percentAsDecimal)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        EAErrorHelper::RecordFailedMBRetrievalError(ea, mbt, mbNumber);
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        return price <= tempZoneState.PercentOfZonePrice(percentAsDecimal);
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        return price >= tempZoneState.PercentOfZonePrice(percentAsDecimal);
    }

    return false;
}

template <typename TEA>
static bool EAHelper::CandleIsInZone(TEA &ea, MBTracker *mbt, int mbNumber, int candleIndex, bool furthest = false)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(TerminalErrors::MB_DOES_NOT_EXIST);
        return false;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return false;
    }

    int zoneStart = tempZoneState.StartIndex() - tempZoneState.EntryOffset() - 1;

    // don't count the candle if it is the zone or before it
    if (candleIndex >= zoneStart)
    {
        return false;
    }

    bool isTrue = false;
    if (tempMBState.Type() == OP_BUY)
    {
        isTrue = tempZoneState.CandleIsInZone(candleIndex);

        if (furthest)
        {
            int lowestIndex = EMPTY;
            if (!MQLHelper::GetLowestIndexBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, zoneStart, 0, true, lowestIndex))
            {
                ea.RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_LOW);
                return false;
            }

            isTrue = isTrue && lowestIndex == candleIndex;
        }
    }
    else if (tempMBState.Type() == OP_SELL)
    {
        isTrue = tempZoneState.CandleIsInZone(candleIndex);

        if (furthest)
        {
            int highestIndex = EMPTY;
            if (!MQLHelper::GetHighestIndexBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, zoneStart, 0, true, highestIndex))
            {
                ea.RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_HIGH);
                return false;
            }

            isTrue = isTrue && highestIndex == candleIndex;
        }
    }

    return isTrue;
}
/*

   ____  _                   ___          _
  |  _ \| | __ _  ___ ___   / _ \ _ __ __| | ___ _ __
  | |_) | |/ _` |/ __/ _ \ | | | | '__/ _` |/ _ \ '__|
  |  __/| | (_| | (_|  __/ | |_| | | | (_| |  __/ |
  |_|   |_|\__,_|\___\___|  \___/|_|  \__,_|\___|_|


*/
template <typename TEA>
static double EAHelper::GetReducedRiskPerPercentLost(TEA &ea, double perPercentLost, double reduceBy)
{
    double calculatedRiskPercent = ea.mRiskPercent;
    double totalPercentLost = (AccountBalance() - ea.mLargestAccountBalance) / ea.mLargestAccountBalance * 100;

    while (totalPercentLost >= perPercentLost)
    {
        calculatedRiskPercent -= reduceBy;
        totalPercentLost -= perPercentLost;
    }

    return calculatedRiskPercent;
}

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

    if (orders >= ea.mMaxCurrentSetupTradesAtOnce)
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
        ea.InvalidateSetup(false, error);
        return;
    }

    ea.mCurrentSetupTicket.SetNewTicket(ticketNumber);
    ea.mCurrentSetupTicket.SetPartials(ea.mPartialRRs, ea.mPartialPercents);
}

template <typename TEA>
static void EAHelper::PlaceMarketOrder(TEA &ea, double entry, double stopLoss, double lotSize = 0.0)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    if (lotSize == 0.0)
    {
        lotSize = OrderHelper::GetLotSize(OrderHelper::RangeToPips(MathAbs(entry - stopLoss)), ea.RiskPercent());
    }

    int ticket = EMPTY;
    int orderPlaceError = OrderHelper::PlaceMarketOrder(ea.mSetupType, lotSize, entry, stopLoss, 0, ea.MagicNumber(), ticket);

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError);
}

template <typename TEA>
static void EAHelper::PlaceStopOrder(TEA &ea, double entry, double stopLoss, double lots = 0.0, bool fallbackMarketOrder = false, double maxMarketOrderSlippage = 0.0)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return;
    }

    if (lots == 0.0)
    {
        lots = OrderHelper::GetLotSize(OrderHelper::RangeToPips(MathAbs(entry - stopLoss)), ea.RiskPercent());
    }

    int ticket = EMPTY;
    int orderPlaceError = EMPTY;
    int stopType = ea.mSetupType + 4;

    if (ea.mSetupType == OP_BUY)
    {
        if (fallbackMarketOrder && entry <= currentTick.ask && currentTick.ask - entry <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = OrderHelper::PlaceMarketOrder(ea.mSetupType, lots, currentTick.ask, stopLoss, 0, ea.MagicNumber(), ticket);
        }
        else if (entry > currentTick.ask)
        {
            orderPlaceError = OrderHelper::PlaceStopOrder(stopType, lots, entry, stopLoss, 0, ea.MagicNumber(), ticket);
        }
    }
    else if (ea.mSetupType == OP_SELL)
    {
        if (fallbackMarketOrder && entry >= currentTick.bid && entry - currentTick.bid <= OrderHelper::PipsToRange(maxMarketOrderSlippage))
        {
            orderPlaceError = OrderHelper::PlaceMarketOrder(ea.mSetupType, lots, currentTick.bid, stopLoss, 0, ea.MagicNumber(), ticket);
        }
        else if (entry < currentTick.bid)
        {
            orderPlaceError = OrderHelper::PlaceStopOrder(stopType, lots, entry, stopLoss, 0, ea.MagicNumber(), ticket);
        }
    }

    PostPlaceOrderChecks<TEA>(ea, ticket, orderPlaceError);
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

template <typename TEA>
static void EAHelper::PlaceStopOrderForPendingLiquidationSetupValidation(TEA &ea, MBTracker *&mbt, int liquidationMBNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForPendingLiquidationSetupValidation(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                                          liquidationMBNumber, mbt, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAHelper::PlaceStopOrderForCandelBreak(TEA &ea, string symbol, int timeFrame, datetime entryCandleTime, datetime stopLossCandleTime)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int entryCandleIndex = iBarShift(symbol, timeFrame, entryCandleTime);
    int stopLossCandleIndex = iBarShift(symbol, timeFrame, stopLossCandleTime);

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForCandleBreak(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                    ea.mSetupType, symbol, timeFrame, entryCandleIndex, stopLossCandleIndex, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAHelper::PlaceMarketOrderForCandleSetup(TEA &ea, string symbol, int timeFrame, datetime stopLossCandleTime)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int stopLossCandleIndex = iBarShift(symbol, timeFrame, stopLossCandleTime);

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceMarketOrderForCandleSetup(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                      ea.mSetupType, symbol, timeFrame, stopLossCandleIndex, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAHelper::PlaceMarketOrderForMostRecentMB(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceMarketOrderForMostRecentMB(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(), ea.mSetupType,
                                                                       mbNumber, mbt, ticketNumber);

    PostPlaceOrderChecks<TEA>(ea, ticketNumber, orderPlaceError);
}

template <typename TEA>
static void EAHelper::PlaceStopOrderForTheLittleDipper(TEA &ea)
{
    ea.mLastState = EAStates::PLACING_ORDER;

    if (ea.mCurrentSetupTicket.Number() != EMPTY)
    {
        return;
    }

    int ticketNumber = EMPTY;
    int orderPlaceError = OrderHelper::PlaceStopOrderForTheLittleDipper(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, ea.MagicNumber(),
                                                                        ea.mSetupType, ea.mEntrySymbol, ea.mEntryTimeFrame, ticketNumber);

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

template <typename TEA>
static void EAHelper::CheckEditStopLossForLiquidationMBSetup(TEA &ea, MBTracker *&mbt, int liquidationMBNumber)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    // also check if the mb number exist. If we invalidate the setup before our stop order gets hit, we would throw an error below
    // due to spread. Its safe to return since the MB was validated so the SL should be correct
    if (ea.mCurrentSetupTicket.Number() == EMPTY || !mbt.MBExists(liquidationMBNumber))
    {
        return;
    }

    ea.mLastState = EAStates::CHECKING_TO_EDIT_STOP_LOSS;

    int editStopLossError = OrderHelper::CheckEditStopLossForLiquidationMBSetup(
        ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mRiskPercent, liquidationMBNumber, mbt, ea.mCurrentSetupTicket);

    if (TerminalErrors::IsTerminalError(editStopLossError))
    {
        ea.InvalidateSetup(true, editStopLossError);
        return;
    }
}

template <typename TEA>
static void EAHelper::CheckBrokePastCandle(TEA &ea, string symbol, int timeFrame, int type, datetime candleTime)
{
    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int candleIndex = iBarShift(symbol, timeFrame, candleTime);
    if (type == OP_BUY)
    {
        double lowestLow;
        if (!MQLHelper::GetLowestLowBetween(symbol, timeFrame, candleIndex, 0, false, lowestLow))
        {
            ea.RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_LOW);
            return;
        }

        if (lowestLow < iLow(symbol, timeFrame, candleIndex))
        {
            ea.InvalidateSetup(true);
        }
    }
    else if (type == OP_SELL)
    {
        double highestHigh;
        if (!MQLHelper::GetHighestHighBetween(symbol, timeFrame, candleIndex, 0, false, highestHigh))
        {
            ea.RecordError(ExecutionErrors::COULD_NOT_RETRIEVE_HIGH);
            return;
        }

        if (highestHigh > iHigh(symbol, timeFrame, candleIndex))
        {
            ea.InvalidateSetup(true);
        }
    }
}

template <typename TEA>
static void EAHelper::CheckEditStopLossForTheLittleDipper(TEA &ea)
{
    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int error = OrderHelper::CheckEditStopLossForTheLittleDipper(ea.mStopLossPaddingPips, ea.mMaxSpreadPips, ea.mEntrySymbol, ea.mEntryTimeFrame, ea.mCurrentSetupTicket);
    if (error != ERR_NO_ERROR)
    {
        ea.RecordError(error);
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
    }
}

template <typename TEA>
static void EAHelper::MoveToBreakEvenAfterNextSameTypeMBValidation(TEA &ea, Ticket &ticket, MBTracker *&mbt, int entryMB)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    if (ticket.Number() == EMPTY)
    {
        return;
    }

    bool isActive = false;
    int isActiveError = ticket.IsActive(isActive);
    if (TerminalErrors::IsTerminalError(isActiveError))
    {
        ea.RecordError(isActiveError);
        return;
    }

    if (!isActive)
    {
        return;
    }

    bool stopLossIsMovedBreakEven;
    int stopLossIsMovedToBreakEvenError = ticket.StopLossIsMovedToBreakEven(stopLossIsMovedBreakEven);
    if (TerminalErrors::IsTerminalError(stopLossIsMovedToBreakEvenError))
    {
        ea.RecordError(stopLossIsMovedToBreakEvenError);
        return;
    }

    if (stopLossIsMovedBreakEven)
    {
        return;
    }

    MBState *mostRecentMB;
    if (!mbt.GetNthMostRecentMB(0, mostRecentMB))
    {
        return;
    }

    if (mostRecentMB.Number() == entryMB)
    {
        return;
    }

    MBState *entryMBState;
    if (!mbt.GetMB(entryMB, entryMBState))
    {
        return;
    }

    if (mostRecentMB.Type() != entryMBState.Type())
    {
        return;
    }

    int breakEvenError = OrderHelper::MoveTicketToBreakEven(ticket);
    if (TerminalErrors::IsTerminalError(breakEvenError))
    {
        ea.RecordError(breakEvenError);
    }
}

template <typename TEA>
static void EAHelper::MoveToBreakEvenWithCandleFurtherThanEntry(TEA &ea, bool waitForCandleClose)
{
    ea.mLastState = EAStates::ATTEMPTING_TO_MANAGE_ORDER;

    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    // should at least wait for the next candle
    int entryIndex = iBarShift(ea.mEntrySymbol, ea.mEntryTimeFrame, ea.mEntryCandleTime);
    if (entryIndex == 0)
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
    int trailError = OrderHelper::MoveToBreakEvenWithCandleFurtherThanEntry(Symbol(), ea.mEntryTimeFrame, waitForCandleClose, ea.mCurrentSetupTicket);
    if (TerminalErrors::IsTerminalError(trailError))
    {
        ea.InvalidateSetup(false, trailError);
    }
}

/**
 * @brief Checks / partials a ticket. Should only be called if an EA has at least one partial set via EA.SetPartial() in a Startegy.mqh
 * Will break if the last partial is not set to 100%
 * @tparam TEA
 * @param ea
 * @param ticketIndex
 */
template <typename TEA>
static void EAHelper::CheckPartialTicket(TEA &ea, Ticket &ticket)
{
    ea.mLastState = EAStates::CHECKING_TO_PARTIAL;

    int selectError = ticket.SelectIfOpen("Trying To Partial");
    if (selectError != ERR_NO_ERROR)
    {
        return;
    }

    RefreshRates();
    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return;
    }

    // if we are in a buy, we look to sell which occurs at the bid. If we are in a sell, we look to buy which occurs at the ask
    double currentPrice = ea.mSetupType == OP_BUY ? currentTick.bid : currentTick.ask;
    double rr = MathAbs(currentPrice - ticket.OpenPrice()) / MathAbs(ticket.OpenPrice() - ticket.mOriginalStopLoss);

    if (rr < ticket.mPartials[0].mRR)
    {
        return;
    }

    // store lots since I don't think i'll be able to access it once I partial the ticket
    double currentTicketLots = OrderLots();
    double lotsToPartial = 0.0;

    // if we are planning on closing the ticket we need to make sure we do or else this will break
    // aka don't risk a potential rounding issue and just use the current lots
    if (ticket.mPartials[0].PercentAsDecimal() >= 1)
    {
        lotsToPartial = currentTicketLots;
    }
    else
    {
        lotsToPartial = OrderHelper::CleanLotSize(currentTicketLots * ticket.mPartials[0].PercentAsDecimal());
    }

    int partialError = OrderHelper::PartialTicket(ticket.Number(), currentPrice, lotsToPartial);
    if (partialError != ERR_NO_ERROR)
    {
        ea.RecordError(partialError);
        return;
    }

    ticket.mRRAcquired = rr * ticket.mPartials[0].PercentAsDecimal();
    int newTicket = 0;

    // this is probably the safest way of checking if the order was closed
    // can't use partial percent since closing less than 100% could still result in the whole ticket being closed due to min lot size
    // can't check to see if the ticket is opened since we don't know what ticket it is anymore
    // can't rely on not being able to find it because something else could go wrong
    if (lotsToPartial != currentTicketLots)
    {
        int searchError = OrderHelper::FindNewTicketAfterPartial(ea.MagicNumber(), ticket.OpenPrice(), ticket.OpenTime(), newTicket);
        if (searchError != ERR_NO_ERROR)
        {
            ea.RecordError(searchError);
        }

        // record before setting the new ticket or altering the old tickets partials
        ea.RecordTicketPartialData(ticket, newTicket);

        if (newTicket == EMPTY)
        {
            ea.RecordError(TerminalErrors::UNABLE_TO_FIND_PARTIALED_TICKET);
        }
        else
        {
            ticket.UpdateTicketNumber(newTicket);
        }

        ticket.mPartials.Remove(0);
    }
    else
    {
        ea.RecordTicketPartialData(ticket, newTicket);
    }
}

template <typename TEA>
static void EAHelper::CloseIfPriceCrossedTicketOpen(TEA &ea, int candlesAfterBeforeChecking)
{
    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    int entryIndex = iBarShift(ea.mEntrySymbol, ea.mEntryTimeFrame, ea.mEntryCandleTime);
    if (entryIndex < candlesAfterBeforeChecking)
    {
        return;
    }

    int selectError = ea.mCurrentSetupTicket.SelectIfOpen("Managing");
    if (selectError != ERR_NO_ERROR)
    {
        // ticket is closed, well record data on it soon
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return;
    }

    // close as soon as the respective spread point hits the open so we lose the smallest about possible
    if (OrderType() == OP_BUY && currentTick.bid < OrderOpenPrice())
    {
        ea.mCurrentSetupTicket.Close();
    }
    else if (OrderType() == OP_SELL && currentTick.ask > OrderOpenPrice())
    {
        ea.mCurrentSetupTicket.Close();
    }
}

template <typename TEA>
static void EAHelper::MoveToBreakEvenAsSoonAsPossible(TEA &ea, double waitForAdditionalPips = 0.0)
{
    ea.mLastState = EAStates::CHECKING_IF_MOVED_TO_BREAK_EVEN;

    if (ea.mCurrentSetupTicket.Number() == EMPTY)
    {
        return;
    }

    bool stopLossIsMovedToBreakEven = false;
    int error = ea.mCurrentSetupTicket.StopLossIsMovedToBreakEven(stopLossIsMovedToBreakEven);
    if (TerminalErrors::IsTerminalError(error))
    {
        ea.RecordError(error);
        return;
    }

    if (stopLossIsMovedToBreakEven)
    {
        return;
    }

    ea.mLastState = EAStates::MOVING_TO_BREAK_EVEN;

    int selectError = ea.mCurrentSetupTicket.SelectIfOpen("Managing");
    if (selectError != ERR_NO_ERROR)
    {
        // ticket is closed, well record data on it soon
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return;
    }

    bool furtherThanEntry = (OrderType() == OP_BUY && currentTick.bid > OrderOpenPrice() + OrderHelper::PipsToRange(waitForAdditionalPips)) ||
                            (OrderType() == OP_SELL && currentTick.ask < OrderOpenPrice() - OrderHelper::PipsToRange(waitForAdditionalPips));

    if (furtherThanEntry)
    {
        int breakEvenError = OrderHelper::MoveTicketToBreakEven(ea.mCurrentSetupTicket, waitForAdditionalPips);
        if (TerminalErrors::IsTerminalError(breakEvenError))
        {
            ea.RecordError(breakEvenError);
        }
    }
}

template <typename TEA>
void EAHelper::MoveStopLossToCoverCommissions(TEA &ea)
{
    ea.mLastState = EAStates::CHECKING_COVERING_COMMISSIONS;
    int costPerLot = 6.00;
    double totalCost = OrderLots() * costPerLot;
    double profitPerTick = MarketInfo(Symbol(), MODE_LOTSIZE) * MarketInfo(Symbol(), MODE_TICKSIZE);

    bool aboveCommissionCosts = false;
    double coveredCommisssionsPrice = 0.0;

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return;
    }

    if (OrderType() == OP_BUY)
    {
        double profit = ((currentTick.bid - OrderOpenPrice()) / MarketInfo(Symbol(), MODE_TICKSIZE)) * profitPerTick;
        if (profit >= totalCost)
        {
            aboveCommissionCosts = true;
            coveredCommisssionsPrice = (MarketInfo(Symbol(), MODE_TICKSIZE) * (totalCost / profitPerTick)) + OrderOpenPrice();
        }
    }
    else if (OrderType() == OP_SELL)
    {
        double profit = ((OrderOpenPrice() - currentTick.ask) / MarketInfo(Symbol(), MODE_TICKSIZE)) * profitPerTick;
        if (profit >= totalCost)
        {
            aboveCommissionCosts = true;
            coveredCommisssionsPrice = OrderOpenPrice() - (MarketInfo(Symbol(), MODE_TICKSIZE) * (totalCost / profitPerTick));
        }
    }

    if (NormalizeDouble(coveredCommisssionsPrice, Digits) == NormalizeDouble(OrderStopLoss(), Digits))
    {
        return;
    }

    if (aboveCommissionCosts)
    {
        if (!OrderModify(OrderTicket(), OrderOpenPrice(), coveredCommisssionsPrice, OrderTakeProfit(), OrderExpiration(), clrGreen))
        {
            ea.RecordError(GetLastError());
        }
    }
}

template <typename TEA>
static bool EAHelper::CloseIfPercentIntoStopLoss(TEA &ea, Ticket &ticket, double percentAsDecimal)
{
    int selectError = ticket.SelectIfOpen("Checking percent into stoplos");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        ea.RecordError(selectError);
        return false;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return false;
    }

    bool isPercentIntoStopLoss = false;
    if (OrderType() == OP_BUY)
    {
        isPercentIntoStopLoss = (OrderOpenPrice() - currentTick.bid) / (OrderOpenPrice() - OrderStopLoss()) >= percentAsDecimal;
    }
    else if (OrderType() == OP_SELL)
    {
        isPercentIntoStopLoss = (currentTick.ask - OrderOpenPrice()) / (OrderStopLoss() - OrderOpenPrice()) >= percentAsDecimal;
    }

    if (isPercentIntoStopLoss)
    {
        ticket.Close();
        return true;
    }

    return false;
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
        if (AccountBalance() > ea.mLargestAccountBalance)
        {
            ea.mLargestAccountBalance = AccountBalance();
        }

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
        if (AccountBalance() > ea.mLargestAccountBalance)
        {
            ea.mLargestAccountBalance = AccountBalance();
        }

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
    if (TerminalErrors::IsTerminalError(error))
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
    record.OriginalStopLoss = OrderStopLoss();
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
    record.OriginalStopLoss = ticket.mOriginalStopLoss;

    record.AccountBalanceAfter = AccountBalance();
    record.ExitTime = OrderCloseTime();
    record.ExitPrice = OrderClosePrice();

    if (ticket.mDistanceRanFromOpen > -1.0)
    {
        record.mTotalMovePips = OrderHelper::RangeToPips(ticket.mDistanceRanFromOpen);
    }
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
static void EAHelper::RecordMBEntryTradeRecord(TEA &ea, int mbNumber, MBTracker *&mbt, int mbCount, int zoneNumber)
{
    MBEntryTradeRecord *record = new MBEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, MBEntryTradeRecord>(ea, record);

    MBState *tempMBState;
    mbt.GetMB(mbNumber, tempMBState);

    ea.mCurrentSetupTicket.SelectIfOpen("Recording Open");

    int pendingMBStart = EMPTY;
    double furthestPoint = EMPTY;
    double pendingHeight = -1.0;
    double percentOfPendingMBInPrevious = -1.0;
    double rrToPendingMBVal = 0.0;

    if (ea.mSetupType == OP_BUY)
    {
        mbt.CurrentBullishRetracementIndexIsValid(pendingMBStart);
        MQLHelper::GetLowestLowBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint);

        pendingHeight = iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart) - furthestPoint;
        percentOfPendingMBInPrevious = (iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, tempMBState.HighIndex()) - furthestPoint) / pendingHeight;
        rrToPendingMBVal = (iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart) - OrderOpenPrice()) / (OrderOpenPrice() - OrderStopLoss());
    }
    else if (ea.mSetupType == OP_SELL)
    {
        mbt.CurrentBearishRetracementIndexIsValid(pendingMBStart);
        MQLHelper::GetHighestHighBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint);

        pendingHeight = furthestPoint - iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart);
        percentOfPendingMBInPrevious = (furthestPoint - iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, tempMBState.LowIndex())) / pendingHeight;
        rrToPendingMBVal = (OrderOpenPrice() - iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart)) / (OrderStopLoss() - OrderOpenPrice());
    }

    record.EntryImage = ScreenShotHelper::TryTakeScreenShot(ea.mEntryCSVRecordWriter.Directory());
    record.RRToMBValidation = rrToPendingMBVal;
    record.MBHeight = tempMBState.Height();
    record.MBWidth = tempMBState.Width();
    record.PendingMBHeight = pendingHeight;
    record.PendingMBWidth = pendingMBStart;
    record.PercentOfPendingMBInPrevious = percentOfPendingMBInPrevious;
    record.MBCount = mbCount;
    record.ZoneNumber = zoneNumber;

    ea.mEntryCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordPartialTradeRecord(TEA &ea, Ticket &partialedTicket, int newTicketNumber)
{
    ea.mLastState = EAStates::RECORDING_PARTIAL_DATA;

    PartialTradeRecord *record = new PartialTradeRecord();

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = partialedTicket.Number();
    record.NewTicketNumber = newTicketNumber;
    record.ExpectedPartialRR = partialedTicket.mPartials[0].mRR;
    record.ActualPartialRR = partialedTicket.mRRAcquired;

    ea.mPartialCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultErrorRecordData(TEA &ea, TRecord &record, int error, string additionalInformation)
{
    record.ErrorTime = TimeCurrent();
    record.MagicNumber = ea.MagicNumber();
    record.Symbol = Symbol();
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

    record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(ea.mErrorCSVRecordWriter.Directory(), "", 8000, 4400);
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

template <typename TEA>
static void EAHelper::CheckUpdateHowFarPriceRanFromOpen(TEA &ea, Ticket &ticket)
{
    if (ticket.Number() == EMPTY)
    {
        return;
    }

    int selectError = ticket.SelectIfOpen("Checking How Far Price Ran");
    if (TerminalErrors::IsTerminalError(selectError))
    {
        ea.RecordError(selectError);
    }

    if (selectError != ERR_NO_ERROR)
    {
        return;
    }

    MqlTick currentTick;
    if (!SymbolInfoTick(Symbol(), currentTick))
    {
        ea.RecordError(GetLastError());
        return;
    }

    double distanceRan;
    if (ea.mSetupType == OP_BUY)
    {
        distanceRan = currentTick.bid - OrderOpenPrice();
    }
    else if (ea.mSetupType == OP_SELL)
    {
        distanceRan = OrderOpenPrice() - currentTick.ask;
    }

    if (distanceRan > ticket.mDistanceRanFromOpen)
    {
        ticket.mDistanceRanFromOpen = distanceRan;
    }
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
