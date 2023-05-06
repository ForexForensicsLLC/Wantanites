//+------------------------------------------------------------------+
//|                                                     EAHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>

#include <Wantanites\Framework\Helpers\EAErrorHelper.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\TradeRecords\Index.mqh>
#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\ErrorRecords\Index.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\Helpers\ScreenShotHelper.mqh>
#include <Wantanites\Framework\Helpers\CandleStickHelper.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\IndicatorHelper\IndicatorHelper.mqh>

#include <Wantanites\Framework\Helpers\ObjectHelpers\EconomicCalendarHelper.mqh>

#include <Wantanites\Framework\Objects\Indicators\MB\LiquidationSetupTracker.mqh>

#include <Wantanites\Framework\MQLVersionSpecific\Extensions\String\String.mqh>

#include <Wantanites\Framework\Utilities\PipConverter.mqh>
#include <Wantanites\Framework\Utilities\LicenseManager.mqh>

#include <Wantanites\Framework\MQLVersionSpecific\Objects\Ticket\Ticket.mqh>

class EAHelper
{
public:
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
    static bool CandleIsAfterTime(TEA &ea, string symbol, int timeFrame, int hour, int minute, int index);
    template <typename TEA>
    static bool CandleIsWithinSession(TEA &ea, string symbol, int timeFrame, int index);
    template <typename TEA>
    static bool MBWasCreatedAfterSessionStart(TEA &ea, MBTracker *&mbt, int mbNumber);

    template <typename TEA>
    static bool RunningBigDipperSetup(TEA &ea, datetime startTime);

    template <typename TEA>
    static bool MostRecentCandleBrokeTimeRange(TEA &ea);
    template <typename TEA>
    static bool HasTimeRangeBreakoutReversal(TEA &ea);

    template <typename TEA>
    static bool MostRecentCandleBrokeDateRange(TEA &ea);

    template <typename TEA, typename TRecord>
    static void GetEconomicEventsForDate(TEA &ea, string calendar, datetime utcDate, bool ignoreDuplicateTimes);
    template <typename TEA>
    static bool CandleIsDuringEconomicEvent(TEA &ea, int candleIndex);
    template <typename TEA>
    static bool GetCandleHighForEconomicEvent(TEA &ea, double &high, int candleIndex);
    template <typename TEA>
    static bool GetCandleLowForEconomicEvent(TEA &ea, double &low, int candleIndex);

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
    template <typename TEA>
    static bool CandleIsInPendingZone(TEA &ea, MBTracker *&mbt, SignalType mbType, int candleIndex, bool furthest);
    // =========================================================================
    // Record Data
    // =========================================================================
private:
    template <typename TEA, typename TRecord>
    static void SetDefaultEntryTradeData(TEA &ea, TRecord &record, Ticket &ticket);
    template <typename TEA, typename TRecord>
    static void SetDefaultCloseTradeData(TEA &ea, TRecord &record, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame);

public:
    template <typename TEA>
    static void RecordDefaultEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordDefaultExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame);

    template <typename TEA>
    static void RecordSingleTimeFrameEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordSingleTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame);

    template <typename TEA>
    static void RecordMultiTimeFrameEntryTradeRecord(TEA &ea, ENUM_TIMEFRAMES higherTimeFrame);
    template <typename TEA>
    static void RecordMultiTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES lowerTimeFrame, ENUM_TIMEFRAMES higherTimeFrame);
    template <typename TEA>
    static void RecordEntryCandleExitTradeRecord(TEA &ea, Ticket &ticket);

    template <typename TEA>
    static void RecordMBEntryTradeRecord(TEA &ea, int mbNumber, MBTracker *&mbt, int mbCount, int zoneNumber);

    template <typename TEA>
    static void RecordPartialTradeRecord(TEA &ea, Ticket &partialedTicket, int newTicketNumber);

    template <typename TEA, typename TRecord>
    static void SetDefaultErrorRecordData(TEA &ea, TRecord &record, string methodName, int error, string additionalInformation);
    template <typename TEA>
    static void RecordDefaultErrorRecord(TEA &ea, string methodName, int error, string additionalInformation);
    template <typename TEA>
    static void RecordSingleTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation);
    template <typename TEA>
    static void RecordMultiTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation, ENUM_TIMEFRAMES lowerTimeFrame, ENUM_TIMEFRAMES highTimeFrame);

    template <typename TEA>
    static void RecordForexForensicsEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordForexForensicsExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame);

    template <typename TEA>
    static void RecordFeatureEngineeringEntryTradeRecord(TEA &ea, Ticket &ticket);
    template <typename TEA>
    static void RecordFeatureEngineeringExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame);

    template <typename TEA>
    static void RecordProfitTrackingExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFram);
};
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
    return (SymbolInfoInteger(ea.EntrySymbol(), SYMBOL_SPREAD) / 10) <= ea.mMaxSpreadPips;
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
static bool EAHelper::CheckSetFirstMB(TEA &ea, MBTracker *&mbt, int &mbNumber, int forcedType = -1, int nthMB = 0)
{
    ea.mLastState = EAStates::GETTING_FIRST_MB_IN_SETUP;

    MBState *mbOneTempState;
    if (!mbt.GetNthMostRecentMB(nthMB, mbOneTempState))
    {
        ea.InvalidateSetup(false, Errors::MB_DOES_NOT_EXIST);
        return false;
    }

    // don't allow any setups where the first mb is broken. This mainly affects liquidation setups
    if (mbOneTempState.GlobalStartIsBroken())
    {
        return false;
    }

    if (forcedType != ConstantValues::EmptyInt)
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

    if (mbTwoTempState.Type() != ea.SetupType())
    {
        firstMBNumber = ConstantValues::EmptyInt;
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

    if (mbThreeTempState.Type() == ea.SetupType())
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
    if (Errors::IsTerminalError(setupError))
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

    if (firstMBNumber == ConstantValues::EmptyInt)
    {
        if (CheckBreakAfterMinROC(ea, mbt))
        {
            return CheckSetFirstMB(ea, mbt, firstMBNumber);
        }
    }

    return firstMBNumber != ConstantValues::EmptyInt;
}

template <typename TEA>
static bool EAHelper::CheckSetDoubleMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == ConstantValues::EmptyInt)
    {
        CheckSetFirstMBAfterMinROCBreak(ea, mbt, firstMBNumber);
    }

    if (secondMBNumber == ConstantValues::EmptyInt)
    {
        return CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber);
    }

    return firstMBNumber != ConstantValues::EmptyInt && secondMBNumber != ConstantValues::EmptyInt;
}

template <typename TEA>
static bool EAHelper::CheckSetLiquidationMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_SETUP;

    if (firstMBNumber == ConstantValues::EmptyInt || secondMBNumber == ConstantValues::EmptyInt)
    {
        CheckSetDoubleMBAfterMinROCBreak(ea, mbt, firstMBNumber, secondMBNumber);
    }

    if (firstMBNumber != ConstantValues::EmptyInt && secondMBNumber != ConstantValues::EmptyInt && liquidationMBNumber == ConstantValues::EmptyInt)
    {
        return CheckSetLiquidationMB(ea, mbt, secondMBNumber, liquidationMBNumber);
    }

    return firstMBNumber != ConstantValues::EmptyInt && secondMBNumber != ConstantValues::EmptyInt && liquidationMBNumber != ConstantValues::EmptyInt;
}

template <typename TEA>
static bool EAHelper::CheckSetSingleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType = -1, int nthMB = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_SINGLE_MB_SETUP;

    if (firstMBNumber == ConstantValues::EmptyInt)
    {
        CheckSetFirstMB(ea, mbt, firstMBNumber, forcedType, nthMB);
    }

    return firstMBNumber != ConstantValues::EmptyInt;
}

template <typename TEA>
static bool EAHelper::CheckSetDoubleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType = -1)
{
    ea.mLastState = EAStates::CHECKING_FOR_DOUBLE_MB_SETUP;

    if (firstMBNumber == ConstantValues::EmptyInt)
    {
        CheckSetSingleMBSetup(ea, mbt, firstMBNumber, forcedType, 1);
    }

    if (secondMBNumber == ConstantValues::EmptyInt)
    {
        CheckSetSecondMB(ea, mbt, firstMBNumber, secondMBNumber);
    }

    return firstMBNumber != ConstantValues::EmptyInt && secondMBNumber != ConstantValues::EmptyInt;
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
    if (Errors::IsTerminalError(error))
    {
        ea.RecordError(__FUNCTION__, error);
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
static bool EAHelper::CandleIsAfterTime(TEA &ea, string symbol, int timeFrame, int hour, int minute, int index)
{
    string startTimeString = hour + ":" + minute;
    datetime startTime = StringToTime(startTimeString);

    return iTime(symbol, timeFrame, index) >= startTime;
}

template <typename TEA>
static bool EAHelper::CandleIsWithinSession(TEA &ea, string symbol, int timeFrame, int index)
{
    return CandleIsAfterTime(ea, symbol, timeFrame, ea.mTradingSessions[0].HourStart(), ea.mTradingSessions[0].MinuteStart(), index);
}

template <typename TEA>
static bool EAHelper::MBWasCreatedAfterSessionStart(TEA &ea, MBTracker *&mbt, int mbNumber)
{
    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
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

    if (mbNumber != ConstantValues::EmptyInt && mbt.MBExists(mbNumber))
    {
        bool brokeRangeStart;
        int brokeRangeStartError = mbt.MBStartIsBroken(mbNumber, brokeRangeStart);
        if (Errors::IsTerminalError(brokeRangeStartError))
        {
            ea.RecordError(__FUNCTION__, brokeRangeStartError);
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

    if (mbNumber != ConstantValues::EmptyInt && mbt.MBExists(mbNumber))
    {
        bool brokeRangeEnd = false;
        int brokeRangeEndError = mbt.MBEndIsBroken(mbNumber, brokeRangeEnd);
        if (Errors::IsTerminalError(brokeRangeEndError))
        {
            ea.RecordError(__FUNCTION__, brokeRangeEndError);
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
static void EAHelper::InvalidateSetup(TEA &ea, bool deletePendingOrder, bool stopTrading, int error = 0)
{
    ea.mHasSetup = false;
    ea.mStopTrading = stopTrading;

    if (error != Errors::NO_ERROR)
    {
        ea.RecordError(__FUNCTION__, error);
    }

    if (ea.mCurrentSetupTickets.IsEmpty())
    {
        return;
    }

    if (!deletePendingOrder)
    {
        return;
    }

    for (int i = ea.mCurrentSetupTickets.Size() - 1; i >= 0; i--)
    {
        bool wasActivated = false;
        int wasActivatedError = ea.mCurrentSetupTickets[i].WasActivated(wasActivated);

        // Only close the order if it is pending or else every active order would get closed
        // as soon as the setup is finished
        if (!wasActivated)
        {
            int closeError = ea.mCurrentSetupTickets[i].Close();
            if (Errors::IsTerminalError(closeError))
            {
                ea.RecordError(__FUNCTION__, closeError);
            }

            ea.mCurrentSetupTickets.Remove(i);
        }
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
    if (confirmationError != Errors::NO_ERROR)
    {
        ea.RecordError(__FUNCTION__, confirmationError);
    }

    return isHolding;
}

template <typename TEA>
static int EAHelper::LiquidationMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(firstMBNumber, secondMBNumber, mbt, hasConfirmation);
    if (confirmationError == Errors::MB_IS_NOT_MOST_RECENT)
    {
        return confirmationError;
    }

    return Errors::NO_ERROR;
}

template <typename TEA>
static bool EAHelper::DojiInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, int dojiCandleIndex = 1)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        EAErrorHelper::RecordFailedMBRetrievalError(ea, mbt, mbNumber, Errors::MB_IS_NOT_MOST_RECENT);
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
        return Errors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Errors::NO_ERROR;
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

    return Errors::NO_ERROR;
}

template <typename TEA>
static bool EAHelper::DojiInsideLiquidationSetupMBsHoldingZone(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool holdingZone = false;
    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(firstMBNumber, secondMBNumber, mbt, holdingZone);
    if (confirmationError == Errors::MB_IS_NOT_MOST_RECENT)
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
        return Errors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Errors::NO_ERROR;
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
        return Errors::NO_ERROR;
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
            return Errors::NO_ERROR;
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
            return Errors::NO_ERROR;
        }

        double previousHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), 1);
        hasConfirmation = SetupHelper::ShootingStarCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), 1) &&
                          (previousHigh >= tempZoneState.EntryPrice() && previousHigh <= tempZoneState.ExitPrice());
    }

    return Errors::NO_ERROR;
}

template <typename TEA>
static int EAHelper::EngulfingCandleInZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    hasConfirmation = false;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        return Errors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Errors::NO_ERROR;
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

    return Errors::NO_ERROR;
}

template <typename TEA>
static int EAHelper::DojiConsecutiveCandles(TEA &ea, MBTracker *&mbt, int mbNumber, int consecutiveCandlesAfter, bool &hasConfirmation)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    hasConfirmation = false;

    if (!mbt.MBIsMostRecent(mbNumber))
    {
        return Errors::MB_IS_NOT_MOST_RECENT;
    }

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return Errors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Errors::NO_ERROR;
    }

    int dojiIndex = consecutiveCandlesAfter + 1;
    if (tempMBState.Type() == OP_BUY)
    {
        for (int i = 1; i < dojiIndex; i++)
        {
            // return false if we have a bearish candle
            if (iOpen(tempMBState.Symbol(), tempMBState.TimeFrame(), i) > iClose(tempMBState.Symbol(), tempMBState.TimeFrame(), i))
            {
                return Errors::NO_ERROR;
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
                return Errors::NO_ERROR;
            }
        }

        double dojiHigh = iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiIndex);
        hasConfirmation = SetupHelper::ShootingStarCandleStickPattern(tempMBState.Symbol(), tempMBState.TimeFrame(), dojiIndex) &&
                          (dojiHigh >= tempZoneState.EntryPrice() && dojiHigh <= tempZoneState.ExitPrice());
    }

    return Errors::NO_ERROR;
}

// single big dipper candle
template <typename TEA>
static bool EAHelper::CandleIsBigDipper(TEA &ea, int bigDipperIndex = 1)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    bool hasConfirmation = false;

    if (ea.SetupType() == OP_BUY)
    {
        bool twoPreviousIsBullish = CandleStickHelper::IsBullish(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex + 1);
        bool previousIsBearish = CandleStickHelper::IsBearish(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex);
        bool previousDoesNotBreakBelowTwoPrevious = iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex) > iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, bigDipperIndex + 1);

        hasConfirmation = twoPreviousIsBullish && previousIsBearish && previousDoesNotBreakBelowTwoPrevious;
    }
    else if (ea.SetupType() == OP_SELL)
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
    int oppositeCandleIndex = ConstantValues::EmptyInt;

    if (ea.SetupType() == OP_BUY)
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
    else if (ea.SetupType() == OP_SELL)
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
static bool EAHelper::MostRecentCandleBrokeTimeRange(TEA &ea)
{
    if (ea.SetupType() == SignalType::Bullish)
    {
        return ea.mTRB.MostRecentCandleBrokeRangeHigh();
    }
    else if (ea.SetupType() == SignalType::Bearish)
    {
        return ea.mTRB.MostRecentCandleBrokeRangeLow();
    }

    return false;
}

template <typename TEA>
static bool EAHelper::HasTimeRangeBreakoutReversal(TEA &ea)
{
    if (ea.SetupType() == OP_BUY)
    {
        return ea.mTRB.BrokeRangeLow();
    }
    else if (ea.SetupType() == OP_SELL)
    {
        return ea.mTRB.BrokeRangeHigh();
    }

    return false;
}

template <typename TEA>
static bool EAHelper::MostRecentCandleBrokeDateRange(TEA &ea)
{
    if (ea.SetupType() == OP_BUY)
    {
        return ea.mDRB.MostRecentCandleBrokeRangeHigh();
    }
    else if (ea.SetupType() == OP_SELL)
    {
        return ea.mDRB.MostRecentCandleBrokeRangeLow();
    }

    return false;
}

template <typename TEA, typename TRecord>
static void EAHelper::GetEconomicEventsForDate(TEA &ea, string calendar, datetime utcDate, bool ignoreDuplicateTimes = true)
{
    MqlDateTime mqlUtcDateTime = DateTimeHelper::ToMQLDateTime(utcDate);

    // strip away hour and minute
    datetime startTime = DateTimeHelper::DayMonthYearToDateTime(mqlUtcDateTime.day, mqlUtcDateTime.mon, mqlUtcDateTime.year);
    datetime endTime = startTime + (60 * 60 * 24);

    EconomicCalendarHelper::GetEventsBetween<TRecord>(calendar, startTime, endTime, ea.mEconomicEvents, ea.mEconomicEventTitles, ea.mEconomicEventSymbols,
                                                      ea.mEconomicEventImpacts, ignoreDuplicateTimes);
}

template <typename TEA>
static bool EAHelper::CandleIsDuringEconomicEvent(TEA &ea, int candleIndex = 0)
{
    for (int i = 0; i < ea.mEconomicEvents.Size(); i++)
    {
        if (DateTimeHelper::DateIsDuringCandleIndex(ea.EntrySymbol(), ea.EntryTimeFrame(), ea.mEconomicEvents[i].Date(), candleIndex))
        {
            return true;
        }
    }

    return false;
}

template <typename TEA>
static bool EAHelper::GetCandleHighForEconomicEvent(TEA &ea, double &high, int candleIndex = 0)
{
    for (int i = 0; i < ea.mEconomicEvents.Size(); i++)
    {
        if (DateTimeHelper::DateIsDuringCandleIndex(ea.EntrySymbol(), ea.EntryTimeFrame(), ea.mEconomicEvents[i].Date(), candleIndex))
        {
            high = ea.mEconomicEvents[i].High();
            return true;
        }
    }

    high = ConstantValues::EmptyDouble;
    return false;
}

template <typename TEA>
static bool EAHelper::GetCandleLowForEconomicEvent(TEA &ea, double &low, int candleIndex = 0)
{
    for (int i = 0; i < ea.mEconomicEvents.Size(); i++)
    {
        if (DateTimeHelper::DateIsDuringCandleIndex(ea.EntrySymbol(), ea.EntryTimeFrame(), ea.mEconomicEvents[i].Date(), candleIndex))
        {
            low = ea.mEconomicEvents[i].Low();
            return true;
        }
    }

    low = ConstantValues::EmptyDouble;
    return false;
}

template <typename TEA>
static bool EAHelper::MBWithinWidth(TEA &ea, MBTracker *mbt, int mbNumber, int minWidth = 0, int maxWidth = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_CONFIRMATION;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
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
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
        return false;
    }

    bool greaterThanMin = true;
    bool lessThanMax = true;

    if (minHeightPips > 0.0)
    {
        greaterThanMin = tempMBState.Height() >= PipConverter::PipsToPoints(minHeightPips);
    }

    if (maxHeightPips > 0.0)
    {
        lessThanMax = tempMBState.Height() <= PipConverter::PipsToPoints(maxHeightPips);
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
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
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
        ea.RecordError(__FUNCTION__, Errors::MB_DOES_NOT_EXIST);
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
    if (tempMBState.Type() == SignalType::Bullish)
    {
        isTrue = tempZoneState.CandleIsInZone(candleIndex);

        if (furthest)
        {
            int lowestIndex = ConstantValues::EmptyInt;
            if (!MQLHelper::GetLowestIndexBetween(ea.EntrySymbol(), ea.EntryTimeFrame(), zoneStart, 0, true, lowestIndex))
            {
                ea.RecordError(__FUNCTION__, Errors::COULD_NOT_RETRIEVE_LOW);
                return false;
            }

            isTrue = isTrue && lowestIndex == candleIndex;
        }
    }
    else if (tempMBState.Type() == SignalType::Bearish)
    {
        isTrue = tempZoneState.CandleIsInZone(candleIndex);

        if (furthest)
        {
            int highestIndex = ConstantValues::EmptyInt;
            if (!MQLHelper::GetHighestIndexBetween(ea.EntrySymbol(), ea.EntryTimeFrame(), zoneStart, 0, true, highestIndex))
            {
                ea.RecordError(__FUNCTION__, Errors::COULD_NOT_RETRIEVE_HIGH);
                return false;
            }

            isTrue = isTrue && highestIndex == candleIndex;
        }
    }

    return isTrue;
}

template <typename TEA>
static bool EAHelper::CandleIsInPendingZone(TEA &ea, MBTracker *&mbt, SignalType mbType, int candleIndex, bool furthest = false)
{
    ZoneState *tempZoneState;
    int zoneStart = ConstantValues::EmptyInt;

    if (mbType == SignalType::Bullish && mbt.HasPendingBullishMB())
    {
        if (!mbt.GetBullishPendingMBsDeepestHoldingZone(tempZoneState))
        {
            return false;
        }

        zoneStart = tempZoneState.StartIndex() - tempZoneState.EntryOffset() - 1;

        if (furthest)
        {
            int lowestIndex = ConstantValues::EmptyInt;
            if (!MQLHelper::GetLowestIndexBetween(ea.EntrySymbol(), ea.EntryTimeFrame(), zoneStart, 0, true, lowestIndex))
            {
                ea.RecordError(__FUNCTION__, Errors::COULD_NOT_RETRIEVE_LOW);
                return false;
            }

            if (lowestIndex != candleIndex)
            {
                return false;
            }
        }
    }
    else if (mbType == SignalType::Bearish && mbt.HasPendingBearishMB())
    {
        if (!mbt.GetBearishPendingMBsDeepestHoldingZone(tempZoneState))
        {
            return false;
        }

        zoneStart = tempZoneState.StartIndex() - tempZoneState.EntryOffset() - 1;

        if (furthest)
        {
            int highestIndex = ConstantValues::EmptyInt;
            if (!MQLHelper::GetHighestIndexBetween(ea.EntrySymbol(), ea.EntryTimeFrame(), zoneStart, 0, true, highestIndex))
            {
                ea.RecordError(__FUNCTION__, Errors::COULD_NOT_RETRIEVE_HIGH);
                return false;
            }

            if (highestIndex != candleIndex)
            {
                return false;
            }
        }
    }
    else
    {
        return false;
    }

    // don't count the candle if it is the zone or before it
    if (candleIndex >= zoneStart)
    {
        return false;
    }

    return tempZoneState.CandleIsInZone(candleIndex);
}
/*

   ____                        _   ____        _
  |  _ \ ___  ___ ___  _ __ __| | |  _ \  __ _| |_ __ _
  | |_) / _ \/ __/ _ \| '__/ _` | | | | |/ _` | __/ _` |
  |  _ <  __/ (_| (_) | | | (_| | | |_| | (_| | || (_| |
  |_| \_\___|\___\___/|_|  \__,_| |____/ \__,_|\__\__,_|


*/
template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultEntryTradeData(TEA &ea, TRecord &record, Ticket &ticket)
{
    ea.mLastState = EAStates::RECORDING_ORDER_OPEN_DATA;

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ticket.Number();
    record.Symbol = Symbol();
    record.OrderDirection = ticket.Type() == TicketType::Buy ? "Buy" : "Sell";
    record.AccountBalanceBefore = ticket.AccountBalanceBefore();
    record.Lots = ticket.LotSize();
    record.EntryTime = ticket.OpenTime();
    record.EntryPrice = ticket.OpenPrice();
    record.EntrySlippage = MathAbs(ticket.OpenPrice() - ticket.ExpectedOpenPrice());
    record.OriginalStopLoss = ticket.OriginalStopLoss();
}

template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultCloseTradeData(TEA &ea, TRecord &record, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame)
{
    ea.mLastState = EAStates::RECORDING_ORDER_CLOSE_DATA;

    record.MagicNumber = ea.MagicNumber();
    record.TicketNumber = ticket.Number();

    // needed for computed properties
    record.Symbol = Symbol();
    record.EntryTimeFrame = entryTimeFrame;
    record.OrderDirection = ticket.Type() == TicketType::Buy ? "Buy" : "Sell";
    record.EntryPrice = ticket.OpenPrice();
    record.EntryTime = ticket.OpenTime();
    record.OriginalStopLoss = ticket.OriginalStopLoss();

    record.AccountBalanceAfter = AccountInfoDouble(ACCOUNT_BALANCE);
    record.ExitTime = ticket.CloseTime();
    record.ExitPrice = ticket.ClosePrice();

    if (!ticket.WasManuallyClosed() && ticket.CurrentStopLoss() > 0.0)
    {
        bool closedBySL = true;
        if (ticket.TakeProfit() > 0.0)
        {
            // we either closed from the TP or SL. We'll decide which one by seeing which one we are closer to
            closedBySL = MathAbs(ticket.ClosePrice() - ticket.CurrentStopLoss()) < MathAbs(ticket.ClosePrice() - ticket.TakeProfit());
        }

        if (closedBySL)
        {
            record.StopLossExitSlippage = ticket.CurrentStopLoss() - ticket.ClosePrice();
        }
        else
        {
            record.StopLossExitSlippage = 0.0;
        }
    }
    else
    {
        record.StopLossExitSlippage = 0.0;
    }

    if (ticket.DistanceRanFromOpen() > -1.0)
    {
        record.mTotalMovePips = PipConverter::PointsToPips(ticket.DistanceRanFromOpen());
    }
}

template <typename TEA>
static void EAHelper::RecordDefaultEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    DefaultEntryTradeRecord *record = new DefaultEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, DefaultEntryTradeRecord>(ea, record, ticket);

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordDefaultExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame)
{
    DefaultExitTradeRecord *record = new DefaultExitTradeRecord();
    SetDefaultCloseTradeData<TEA, DefaultExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    SingleTimeFrameEntryTradeRecord *record = new SingleTimeFrameEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, SingleTimeFrameEntryTradeRecord>(ea, record, ticket);

    record.EntryImage = ScreenShotHelper::TryTakeScreenShot(ea.mEntryCSVRecordWriter.Directory());
    ea.mEntryCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame)
{
    SingleTimeFrameExitTradeRecord *record = new SingleTimeFrameExitTradeRecord();
    SetDefaultCloseTradeData<TEA, SingleTimeFrameExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    record.ExitImage = ScreenShotHelper::TryTakeScreenShot(ea.mExitCSVRecordWriter.Directory());
    ea.mExitCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameEntryTradeRecord(TEA &ea, ENUM_TIMEFRAMES higherTimeFrame)
{
    MultiTimeFrameEntryTradeRecord *record = new MultiTimeFrameEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, MultiTimeFrameEntryTradeRecord>(ea, record);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mEntryCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != Errors::NO_ERROR)
    {
        // don't return here if we fail to take the screen shot. We still want to record the rest of the entry data
        ea.RecordError(__FUNCTION__, error);
    }

    record.LowerTimeFrameEntryImage = lowerTimeFrameImage;
    record.HigherTimeFrameEntryImage = higherTimeFrameImage;

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES lowerTimeFrame, ENUM_TIMEFRAMES higherTimeFrame)
{
    MultiTimeFrameExitTradeRecord *record = new MultiTimeFrameExitTradeRecord();
    SetDefaultCloseTradeData<TEA, MultiTimeFrameExitTradeRecord>(ea, record, ticket, lowerTimeFrame);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int error = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mExitCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (error != Errors::NO_ERROR)
    {
        // don't return here if we fail to take the screen shot. We still want to record the rest of the exit data
        ea.RecordError(__FUNCTION__, error);
    }

    record.LowerTimeFrameExitImage = lowerTimeFrameImage;
    record.HigherTimeFrameExitImage = higherTimeFrameImage;

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordEntryCandleExitTradeRecord(TEA &ea, Ticket &ticket)
{
    EntryCandleExitTradeRecord *record = new EntryCandleExitTradeRecord();
    SetDefaultCloseTradeData<TEA, EntryCandleExitTradeRecord>(ea, record, ticket, ea.mEntryTimeFrame);

    int entryCandle = iBarShift(ea.mEntrySymbol, ea.mEntryTimeFrame, ticket.OpenTime());
    record.CandleOpen = iOpen(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);
    record.CandleClose = iClose(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);
    record.CandleHigh = iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);
    record.CandleLow = iLow(ea.mEntrySymbol, ea.mEntryTimeFrame, entryCandle);

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

    int pendingMBStart = ConstantValues::EmptyInt;
    double furthestPoint = ConstantValues::EmptyInt;
    double pendingHeight = -1.0;
    double percentOfPendingMBInPrevious = -1.0;
    double rrToPendingMBVal = 0.0;

    if (ea.SetupType() == OP_BUY)
    {
        mbt.CurrentBullishRetracementIndexIsValid(pendingMBStart);
        MQLHelper::GetLowestLowBetween(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart, 0, true, furthestPoint);

        pendingHeight = iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart) - furthestPoint;
        percentOfPendingMBInPrevious = (iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, tempMBState.HighIndex()) - furthestPoint) / pendingHeight;
        rrToPendingMBVal = (iHigh(ea.mEntrySymbol, ea.mEntryTimeFrame, pendingMBStart) - OrderOpenPrice()) / (OrderOpenPrice() - OrderStopLoss());
    }
    else if (ea.SetupType() == OP_SELL)
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
    record.ActualPartialRR = partialedTicket.RRAcquired();

    ea.mPartialCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA, typename TRecord>
static void EAHelper::SetDefaultErrorRecordData(TEA &ea, TRecord &record, string methodName, int error, string additionalInformation)
{
    record.ErrorTime = TimeCurrent();
    record.MagicNumber = ea.MagicNumber();
    record.Symbol = Symbol();
    record.MethodName = methodName;
    record.Error = error;
    record.LastState = ea.mLastState;

    // set to unset string so when writing the value the framework doesn't think it failed because it didn't write anything
    if (additionalInformation == "")
    {
        additionalInformation = ConstantValues::UnsetString;
    }

    record.AdditionalInformation = additionalInformation;
}

template <typename TEA>
static void EAHelper::RecordDefaultErrorRecord(TEA &ea, string methodName, int error, string additionalInformation)
{
    DefaultErrorRecord *record = new DefaultErrorRecord();
    SetDefaultErrorRecordData<TEA, DefaultErrorRecord>(ea, record, methodName, error, additionalInformation);

    ea.mErrorCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordSingleTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation)
{
    SingleTimeFrameErrorRecord *record = new SingleTimeFrameErrorRecord();
    SetDefaultErrorRecordData<TEA, SingleTimeFrameErrorRecord>(ea, record, methodName, error, additionalInformation);

    record.ErrorImage = ScreenShotHelper::TryTakeScreenShot(ea.mErrorCSVRecordWriter.Directory(), "", 8000, 4400);
    ea.mErrorCSVRecordWriter.WriteRecord(record);

    delete record;
}

template <typename TEA>
static void EAHelper::RecordMultiTimeFrameErrorRecord(TEA &ea, string methodName, int error, string additionalInformation, ENUM_TIMEFRAMES lowerTimeFrame,
                                                      ENUM_TIMEFRAMES higherTimeFrame)
{
    MultiTimeFrameErrorRecord *record = new MultiTimeFrameErrorRecord();
    SetDefaultErrorRecordData<TEA, MultiTimeFrameErrorRecord>(ea, record, methodName, error, additionalInformation);

    string lowerTimeFrameImage = "";
    string higherTimeFrameImage = "";

    int screenShotError = ScreenShotHelper::TryTakeMultiTimeFrameScreenShot(ea.mExitCSVRecordWriter.Directory(), higherTimeFrame, lowerTimeFrameImage, higherTimeFrameImage);
    if (screenShotError != Errors::NO_ERROR)
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
static void EAHelper::RecordForexForensicsEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    ForexForensicsEntryTradeRecord *record = new ForexForensicsEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, ForexForensicsEntryTradeRecord>(ea, record, ticket);

    // override the magic number so that it matches the ticket that we copied the trade from
    record.MagicNumber = ticket.MagicNumber();
    record.ExpectedEntryPrice = ticket.ExpectedOpenPrice();
    record.DuringNews = CandleIsDuringEconomicEvent<TEA>(ea, iBarShift(ea.EntrySymbol(), ea.EntryTimeFrame(), ticket.OpenTime()));

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordForexForensicsExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame)
{
    ForexForensicsExitTradeRecord *record = new ForexForensicsExitTradeRecord();
    SetDefaultCloseTradeData<TEA, ForexForensicsExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    record.FurthestEquityDrawdownPercent = ea.mFurthestEquityDrawdownPercent;
    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordFeatureEngineeringEntryTradeRecord(TEA &ea, Ticket &ticket)
{
    FeatureEngineeringEntryTradeRecord *record = new FeatureEngineeringEntryTradeRecord();
    SetDefaultEntryTradeData<TEA, FeatureEngineeringEntryTradeRecord>(ea, record, ticket);

    int entryCandle = iBarShift(ea.EntrySymbol(), ea.EntryTimeFrame(), ticket.OpenTime());
    ObjectList<EconomicEvent> *events = new ObjectList<EconomicEvent>();
    if (GetEconomicEventsForCandle<TEA>(ea, events, entryCandle))
    {
        record.DuringNews = true;

        for (int i = 0; i < events.Size(); i++)
        {
            if (events[i].Impact() > record.NewsImpact)
            {
                record.NewsImpact = events[i].Impact();
            }
        }
    }
    else
    {
        record.DuringNews = false;
        record.NewsImpact = -1;
    }

    delete events;

    record.DayOfWeek = DateTimeHelper::CurrentDayOfWeek();

    record.PreviousCandleWasBullish = CandleStickHelper::IsBullish(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreviousCandleWasBullishEngulfing = SetupHelper::BullishEngulfing(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreviousCandleWasBearishEngulfing = SetupHelper::BearishEngulfing(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreviousCandleWasHammerPattern = SetupHelper::HammerCandleStickPattern(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);
    record.PreivousCandleWasShootingStarPattern = SetupHelper::ShootingStarCandleStickPattern(ea.EntrySymbol(), ea.EntryTimeFrame(), entryCandle + 1);

    record.EntryAboveFiveEMA = IndicatorHelper::MovingAverage(ea.EntrySymbol(), ea.EntryTimeFrame(), 5, 0, MODE_EMA, PRICE_CLOSE, entryCandle) > ticket.OpenPrice();
    record.EntryAboveFiftyEMA = IndicatorHelper::MovingAverage(ea.EntrySymbol(), ea.EntryTimeFrame(), 50, 0, MODE_EMA, PRICE_CLOSE, entryCandle) > ticket.OpenPrice();
    record.EntryAboveTwoHundreadEMA = IndicatorHelper::MovingAverage(ea.EntrySymbol(), ea.EntryTimeFrame(), 200, 0, MODE_EMA, PRICE_CLOSE, entryCandle) > ticket.OpenPrice();

    record.FivePeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 5);
    record.TenPeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 10);
    record.TwentyPeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 20);
    record.FourtyPeriodOBVAverageChange = IndicatorHelper::OnBalanceVolumnAverageChange(ea.EntrySymbol(), ea.EntryTimeFrame(), PRICE_CLOSE, 40);

    double rsi = IndicatorHelper::RSI(ea.EntrySymbol(), ea.EntryTimeFrame(), 14, PRICE_CLOSE, entryCandle);
    record.EntryDuringRSIAboveThirty = rsi > 30;
    record.EntryDuringRSIAboveFifty = rsi > 50;
    record.EntryDuringRSIAboveSeventy = rsi > 70;

    record.PreviousConsecutiveBullishHeikinAshiCandles = ea.mHAT.PreviousConsecutiveBullishCandles();
    record.PreviousConsecutiveBearishHeikinAshiCandles = ea.mHAT.PreviousConsecutiveBearishCandles();

    bool mostRecentStructureIsBullish = ea.mMBT.GetNthMostRecentMBsType(0) == SignalType::Bullish;
    bool inMostRecentStructureZone = CandleIsInZone<TEA>(ea, ea.mMBT, ea.mMBT.MBsCreated() - 1, entryCandle);

    record.CurrentStructureIsBullish = mostRecentStructureIsBullish;
    record.WithinDemandZone = mostRecentStructureIsBullish && inMostRecentStructureZone;
    record.WithinSupplyZone = !mostRecentStructureIsBullish && inMostRecentStructureZone;
    record.WithinPendingDemandZone = CandleIsInPendingZone<TEA>(ea, ea.mMBT, SignalType::Bullish, entryCandle);
    record.WithinPendingSupplyZone = CandleIsInPendingZone<TEA>(ea, ea.mMBT, SignalType::Bearish, entryCandle);

    ea.mEntryCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordFeatureEngineeringExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame)
{
    FeatureEngineeringExitTradeRecord *record = new FeatureEngineeringExitTradeRecord();
    SetDefaultCloseTradeData<TEA, FeatureEngineeringExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    record.FurthestEquityDrawdownPercent = ea.mFurthestEquityDrawdownPercent;
    record.Outcome = ticket.Profit() > 0 ? "Win" : "Lose";

    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}

template <typename TEA>
static void EAHelper::RecordProfitTrackingExitTradeRecord(TEA &ea, Ticket &ticket, ENUM_TIMEFRAMES entryTimeFrame)
{
    ProfitTrackingExitTradeRecord *record = new ProfitTrackingExitTradeRecord();
    SetDefaultCloseTradeData<TEA, ProfitTrackingExitTradeRecord>(ea, record, ticket, entryTimeFrame);

    record.FurthestEquityDrawdownPercent = ea.mFurthestEquityDrawdownPercent;
    ea.mExitCSVRecordWriter.WriteRecord(record);
    delete record;
}