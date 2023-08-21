//+------------------------------------------------------------------+
//|                                                     EASetupHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\Helpers\EAErrorHelper.mqh>
#include <Wantanites\Framework\Utilities\PipConverter.mqh>
#include <Wantanites\Framework\Constants\ConstantValues.mqh>
#include <Wantanites\Framework\Helpers\CandleStickHelper.mqh>
#include <Wantanites\Framework\MQLVersionSpecific\Extensions\String\String.mqh>
#include <Wantanites\Framework\Helpers\ObjectHelpers\EconomicCalendarHelper.mqh>
#include <Wantanites\Framework\Objects\Indicators\MB\LiquidationSetupTracker.mqh>

class EASetupHelper
{
public:
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

    template <typename TEA>
    static bool TradeWillWin(TEA &ea, datetime entryTime, double stopLoss, double takeProfit);

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
    static bool CandleIsInZone(TEA &ea, ZoneState &zone, int candleIndex, bool furthest = false);
    template <typename TEA>
    static bool CandleIsInZone(TEA &ea, MBTracker *&mbt, int mbNumber, int candleIndex, bool furthest);
    template <typename TEA>
    static bool CandleIsInPendingZone(TEA &ea, MBTracker *&mbt, SignalType mbType, int candleIndex, bool furthest);
};
/*

    ____ _               _      ____       _     ____       _
   / ___| |__   ___  ___| | __ / ___|  ___| |_  / ___|  ___| |_ _   _ _ __
  | |   | '_ \ / _ \/ __| |/ / \___ \ / _ \ __| \___ \ / _ \ __| | | | '_ \
  | |___| | | |  __/ (__|   <   ___) |  __/ |_   ___) |  __/ |_| |_| | |_) |
   \____|_| |_|\___|\___|_|\_\ |____/ \___|\__| |____/ \___|\__|\__,_| .__/
                                                                     |_|

*/
template <typename TEA>
static bool EASetupHelper::CheckSetFirstMB(TEA &ea, MBTracker *&mbt, int &mbNumber, int forcedType = -1, int nthMB = 0)
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
static bool EASetupHelper::CheckSetSecondMB(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber)
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
static bool EASetupHelper::CheckSetLiquidationMB(TEA &ea, MBTracker *&mbt, int &secondMBNumber, int &liquidationMBNumber)
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
static bool EASetupHelper::CheckBreakAfterMinROC(TEA &ea, MBTracker *&mbt)
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
static bool EASetupHelper::CheckSetFirstMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber)
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
static bool EASetupHelper::CheckSetDoubleMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber)
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
static bool EASetupHelper::CheckSetLiquidationMBAfterMinROCBreak(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber)
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
static bool EASetupHelper::CheckSetSingleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int forcedType = -1, int nthMB = 0)
{
    ea.mLastState = EAStates::CHECKING_FOR_SINGLE_MB_SETUP;

    if (firstMBNumber == ConstantValues::EmptyInt)
    {
        CheckSetFirstMB(ea, mbt, firstMBNumber, forcedType, nthMB);
    }

    return firstMBNumber != ConstantValues::EmptyInt;
}

template <typename TEA>
static bool EASetupHelper::CheckSetDoubleMBSetup(TEA &ea, MBTracker *&mbt, int &firstMBNumber, int &secondMBNumber, int forcedType = -1)
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
static bool EASetupHelper::CheckSetLiquidationMBSetup(TEA &ea, LiquidationSetupTracker *&lst, int &firstMBNumber, int &secondMBNumber, int &liquidationMBNumber)
{
    ea.mLastState = EAStates::CHECKING_FOR_LIQUIDATION_MB_SETUP;
    return lst.HasSetup(firstMBNumber, secondMBNumber, liquidationMBNumber);
}

template <typename TEA>
static bool EASetupHelper::SetupZoneIsValidForConfirmation(TEA &ea, int setupMBNumber, int nthConfirmationMB, string &additionalInformation)
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
static bool EASetupHelper::CheckSetFirstMBBreakAfterConsecutiveMBs(TEA &ea, MBTracker *&mbt, int conseuctiveMBs, int &firstMBNumber)
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
static bool EASetupHelper::CandleIsAfterTime(TEA &ea, string symbol, int timeFrame, int hour, int minute, int index)
{
    string startTimeString = hour + ":" + minute;
    datetime startTime = StringToTime(startTimeString);

    return iTime(symbol, timeFrame, index) >= startTime;
}

template <typename TEA>
static bool EASetupHelper::CandleIsWithinSession(TEA &ea, string symbol, int timeFrame, int index)
{
    return CandleIsAfterTime(ea, symbol, timeFrame, ea.mTradingSessions[0].HourStart(), ea.mTradingSessions[0].MinuteStart(), index);
}

template <typename TEA>
static bool EASetupHelper::MBWasCreatedAfterSessionStart(TEA &ea, MBTracker *&mbt, int mbNumber)
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
static bool EASetupHelper::CheckBrokeMBRangeStart(TEA &ea, MBTracker *&mbt, int mbNumber)
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
static bool EASetupHelper::CheckBrokeMBRangeEnd(TEA &ea, MBTracker *&mbt, int mbNumber)
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
static bool EASetupHelper::CheckCrossedOpenPriceAfterMinROC(TEA &ea)
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
static void EASetupHelper::InvalidateSetup(TEA &ea, bool deletePendingOrder, bool stopTrading, int error = 0)
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
static bool EASetupHelper::MostRecentMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int mbNumber)
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
static int EASetupHelper::LiquidationMBZoneIsHolding(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber, bool &hasConfirmation)
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
static bool EASetupHelper::DojiInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, int dojiCandleIndex = 1)
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
static int EASetupHelper::DojiBreakInsideMostRecentMBsHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation)
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
static bool EASetupHelper::DojiInsideLiquidationSetupMBsHoldingZone(TEA &ea, MBTracker *&mbt, int firstMBNumber, int secondMBNumber)
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
static int EASetupHelper::ImbalanceDojiInZone(TEA &ea, MBTracker *&mbt, int mbNumber, int numberOfCandlesBackForPossibleImbalance, double minPercentROC, bool &hasConfirmation)
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
static int EASetupHelper::EngulfingCandleInZone(TEA &ea, MBTracker *&mbt, int mbNumber, bool &hasConfirmation)
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
static int EASetupHelper::DojiConsecutiveCandles(TEA &ea, MBTracker *&mbt, int mbNumber, int consecutiveCandlesAfter, bool &hasConfirmation)
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
static bool EASetupHelper::CandleIsBigDipper(TEA &ea, int bigDipperIndex = 1)
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
static bool EASetupHelper::RunningBigDipperSetup(TEA &ea, datetime startTime)
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
static bool EASetupHelper::MostRecentCandleBrokeTimeRange(TEA &ea)
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
static bool EASetupHelper::HasTimeRangeBreakoutReversal(TEA &ea)
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
static bool EASetupHelper::MostRecentCandleBrokeDateRange(TEA &ea)
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
static void EASetupHelper::GetEconomicEventsForDate(TEA &ea, string calendar, datetime utcDate, bool ignoreDuplicateTimes = true)
{
    MqlDateTime mqlUtcDateTime = DateTimeHelper::ToMQLDateTime(utcDate);

    // strip away hour and minute
    datetime startTime = DateTimeHelper::DayMonthYearToDateTime(mqlUtcDateTime.day, mqlUtcDateTime.mon, mqlUtcDateTime.year);
    datetime endTime = startTime + (60 * 60 * 24);

    EconomicCalendarHelper::GetEventsBetween<TRecord>(calendar, startTime, endTime, ea.mEconomicEvents, ea.mEconomicEventTitles, ea.mEconomicEventSymbols,
                                                      ea.mEconomicEventImpacts, ignoreDuplicateTimes);
}

template <typename TEA>
static bool EASetupHelper::CandleIsDuringEconomicEvent(TEA &ea, int candleIndex = 0)
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
static bool EASetupHelper::GetCandleHighForEconomicEvent(TEA &ea, double &high, int candleIndex = 0)
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
static bool EASetupHelper::GetCandleLowForEconomicEvent(TEA &ea, double &low, int candleIndex = 0)
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
static bool EASetupHelper::TradeWillWin(TEA &ea, datetime entryTime, double stopLoss, double takeProfit)
{
    MqlDateTime requestedDate = DateTimeHelper::ToMQLDateTime(entryTime);
    return ea.mCST.PriceReachesXBeforeY(requestedDate, ea.SetupType(), takeProfit, stopLoss);
}

template <typename TEA>
static bool EASetupHelper::MBWithinWidth(TEA &ea, MBTracker *mbt, int mbNumber, int minWidth = 0, int maxWidth = 0)
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
static bool EASetupHelper::MBWithinHeight(TEA &ea, MBTracker *mbt, int mbNumber, double minHeightPips = 0.0, double maxHeightPips = 0.0)
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
static bool EASetupHelper::MBWithinPipsPerCandle(TEA &ea, MBTracker *mbt, int mbNumber, double minPipsPerCandle, double maxPipsPerCandle)
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
static bool EASetupHelper::PriceIsFurtherThanPercentIntoMB(TEA &ea, MBTracker *mbt, int mbNumber, double price, double percentAsDecimal)
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
static bool EASetupHelper::PriceIsFurtherThanPercentIntoHoldingZone(TEA &ea, MBTracker *&mbt, int mbNumber, double price, double percentAsDecimal)
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
static bool EASetupHelper::CandleIsInZone(TEA &ea, MBTracker *&mbt, int mbNumber, int candleIndex, bool furthest = false)
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

    return CandleIsInZone(ea, tempZoneState, candleIndex, furthest);
}

template <typename TEA>
static bool EASetupHelper::CandleIsInZone(TEA &ea, ZoneState &zone, int candleIndex, bool furthest = false)
{
    int zoneStart = zone.StartIndex() - zone.EntryOffset() - 1;

    // don't count the candle if it is the zone or before it
    if (candleIndex >= zoneStart)
    {
        return false;
    }

    bool isTrue = false;
    if (ea.SetupType() == SignalType::Bullish)
    {
        isTrue = zone.CandleIsInZone(candleIndex);

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
    else if (ea.SetupType() == SignalType::Bearish)
    {
        isTrue = zone.CandleIsInZone(candleIndex);

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
static bool EASetupHelper::CandleIsInPendingZone(TEA &ea, MBTracker *&mbt, SignalType mbType, int candleIndex, bool furthest = false)
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
