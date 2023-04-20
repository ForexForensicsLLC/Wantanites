//+------------------------------------------------------------------+
//|                                                  SetupHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\Indicators\MB\MBTracker.mqh>
#include <Wantanites\Framework\Objects\Indicators\Time\MinROCFromTimeStamp.mqh>
#include <Wantanites\Framework\Constants\Index.mqh>

class SetupHelper
{
public:
    // ==========================================================================
    // Range Broke Methods
    // ==========================================================================
    static int BrokeDoubleMBPlusLiquidationSetupRangeEnd(int secondMBInSetup, int setupType, MBTracker *&mbt, out bool &isTrue);

    // ==========================================================================
    // MB Setup Methods
    // ==========================================================================
    static int MostRecentMBPlusHoldingZone(int mostRecentMBNumber, MBTracker *&mbt, out bool &isTrue);
    static int FirstMBAfterLiquidationOfSecondPlusHoldingZone(int mbOneNumber, int mbTwoNumber, MBTracker *&mbt, out bool &isTrue);
    static int SameTypeSubsequentMB(int mbNumber, MBTracker *&mbt, out bool isTrue);

private:
    static int GetEarlierSetupZoneMitigationIndexForLowerTimeFrame(ZoneState *setupZone, MBTracker *confirmationMBT);
    static int MBPushedFurtherIntoDeepestHoldingSetupZone(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &pushedFurtherIntoZone,
                                                          string &additionaInformation);
    static int MBRetappedDeepestHoldingSetupZone(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &retappedZone,
                                                 string &additionalInformation);

public:
    static int SetupZoneIsValidForConfirmation(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &isTrue, string &additionalInformation);

    // ==========================================================================
    // Min ROC. From Time Stamp Setup Methods
    // ==========================================================================
    static int BreakAfterMinROC(MinROCFromTimeStamp *&mrfts, MBTracker *&mbt, out bool &isTrue);

    static bool HammerCandleStickPattern(string symbol, int timeFrame, int startingCandle);
    static bool HammerCandleStickPatternBreak(string symbol, int timeFrame, bool useBody);

    static bool ShootingStarCandleStickPattern(string symbol, int timeFrame, int startingCandle);
    static bool ShootingStarCandleStickPatternBreak(string symbol, int timeFrame, bool useBody);

    static bool BullishEngulfing(string symbol, int timeFrame, int startingCandle);
    static bool BearishEngulfing(string symbol, int timeFrame, int startingCandle);
};
/*

   ____                          ____            _          __  __      _   _               _
  |  _ \ __ _ _ __   __ _  ___  | __ ) _ __ ___ | | _____  |  \/  | ___| |_| |__   ___   __| |___
  | |_) / _` | '_ \ / _` |/ _ \ |  _ \| '__/ _ \| |/ / _ \ | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  |  _ < (_| | | | | (_| |  __/ | |_) | | | (_) |   <  __/ | |  | |  __/ |_| | | | (_) | (_| \__ \
  |_| \_\__,_|_| |_|\__, |\___| |____/|_|  \___/|_|\_\___| |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
                    |___/

*/
/**
 * @brief Checks if price broke the second MB, held the first, and then continued past the second
 *
 * @param secondMBInSetup
 * @param setupType
 * @param mbt
 * @param isTrue
 * @return int
 */
static int SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(int secondMBInSetup, int setupType, MBTracker *&mbt, out bool &isTrue)
{
    isTrue = false;

    MBState *thirdTempMBState;

    // Return false if we can't find the subsequent MB for whatever reason
    if (!mbt.GetSubsequentMB(secondMBInSetup, thirdTempMBState))
    {
        return ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST;
    }

    // Types can't be equal if we are looking for a liquidation of the second MB
    if (thirdTempMBState.Type() == setupType)
    {
        return ExecutionErrors::EQUAL_MB_TYPES;
    }

    // The end of our setup is the same as the start of the MB that liquidated the second MB
    isTrue = thirdTempMBState.GlobalStartIsBroken();
    return Errors::NO_ERROR;
}
/*

   __  __ ____    ____       _                 __  __      _   _               _
  |  \/  | __ )  / ___|  ___| |_ _   _ _ __   |  \/  | ___| |_| |__   ___   __| |___
  | |\/| |  _ \  \___ \ / _ \ __| | | | '_ \  | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  | |  | | |_) |  ___) |  __/ |_| |_| | |_) | | |  | |  __/ |_| | | | (_) | (_| \__ \
  |_|  |_|____/  |____/ \___|\__|\__,_| .__/  |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
                                      |_|

*/
static int SetupHelper::MostRecentMBPlusHoldingZone(int mostRecentMBNumber, MBTracker *&mbt, out bool &isTrue)
{
    isTrue = false;

    if (!mbt.MBIsMostRecent(mostRecentMBNumber))
    {
        return ExecutionErrors::MB_IS_NOT_MOST_RECENT;
    }

    isTrue = mbt.MBsClosestValidZoneIsHolding(mostRecentMBNumber);
    return Errors::NO_ERROR;
}

static int SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(int mbOneNumber, int mbTwoNumber, MBTracker *&mbt, out bool &isTrue)
{
    isTrue = false;

    MBState *secondMBTempMBState;
    MBState *thirdMBTempState;

    if (!mbt.GetMB(mbTwoNumber, secondMBTempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (secondMBTempMBState.Type() == OP_BUY)
    {
        if (!mbt.GetSubsequentMB(mbTwoNumber, thirdMBTempState))
        {
            return ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST;
        }

        // add one so that this can return true if the endindex is also tapping into a zone
        // should be safe to do since the mb has already been calculated and printed
        isTrue = mbt.MBsClosestValidZoneIsHolding(mbOneNumber, thirdMBTempState.EndIndex() + 1);
    }
    else if (secondMBTempMBState.Type() == OP_SELL)
    {
        if (!mbt.GetSubsequentMB(mbTwoNumber, thirdMBTempState))
        {
            return ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST;
        }

        // add one so that this can return true if the endindex is also tapping into a zone
        // should be safe to do since the mb has already been calculated and printed
        isTrue = mbt.MBsClosestValidZoneIsHolding(mbOneNumber, thirdMBTempState.EndIndex() + 1);
    }

    return Errors::NO_ERROR;
}

static int SetupHelper::SameTypeSubsequentMB(int mbNumber, MBTracker *&mbt, out bool isTrue)
{
    isTrue = mbt.MBIsMostRecent(mbNumber + 1) && mbt.HasNMostRecentConsecutiveMBs(2);
    return Errors::NO_ERROR;
}

static int SetupHelper::GetEarlierSetupZoneMitigationIndexForLowerTimeFrame(ZoneState *setupZone, MBTracker *confirmationMBT)
{
    // check from zoneState.StartIndex() - EntryOffset - 2 to get us 2 candles past the imbalance, aka the first candle that can mitigate the zone.
    datetime earliestZoneMitigationTime = iTime(setupZone.Symbol(), setupZone.TimeFrame(), setupZone.StartIndex() - setupZone.EntryOffset() - 2);

    if (earliestZoneMitigationTime > TimeCurrent())
    {
        return EMPTY;
    }

    return iBarShift(confirmationMBT.Symbol(), confirmationMBT.TimeFrame(), earliestZoneMitigationTime);
}

static int SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &pushedFurtherIntoZone,
                                                                   string &additionaInformation)
{
    pushedFurtherIntoZone = false;

    MBState *tempSetupMB;
    if (!setupMBT.GetMB(setupMBNumber, tempSetupMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempSetupZone;
    if (!tempSetupMB.GetDeepestHoldingZone(tempSetupZone))
    {
        return ExecutionErrors::NO_ZONES;
    }

    additionaInformation += " Zone Entry: " + tempSetupZone.EntryPrice();

    int lowerEarliestSetupZoneMitigationIndex = GetEarlierSetupZoneMitigationIndexForLowerTimeFrame(tempSetupZone, confirmationMBT);
    if (lowerEarliestSetupZoneMitigationIndex == EMPTY)
    {
        return ExecutionErrors::LOWER_EARLIEST_SETUP_ZONE_MITIGATION_NOT_FOUND;
    }

    MBState *mostRecentMB;
    if (!confirmationMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    int startIndex = 0;
    for (int i = 0; i < confirmationMBT.CurrentMBs(); i++)
    {
        MBState *tempMBState;
        if (!confirmationMBT.GetNthMostRecentMB(i, tempMBState))
        {
            return TerminalErrors::MB_DOES_NOT_EXIST;
        }

        if (tempMBState.mInsideSetupZone == Status::IS_FALSE || tempMBState.mInsideSetupZone == Status::NOT_CHECKED)
        {
            startIndex = i;
            break;
        }
    }

    additionaInformation += " Furthest Point Was Set: " + tempSetupZone.mFurthestPointWasSet + " Lowest Low: " + tempSetupZone.mLowestConfirmationMBLowWithin;
    // if our most recent mb is updated, then all are updated
    if (tempSetupZone.mFurthestPointWasSet && mostRecentMB.mPushedFurtherIntoSetupZone == 0)
    {
        // update all mbs that haven't been checked yet
        // need to go from left to right so that they are updated correctly in the order that they were created
        for (int i = startIndex; i >= 0; i--)
        {
            MBState *tempConfirmationMB;
            if (!confirmationMBT.GetNthMostRecentMB(i, tempConfirmationMB))
            {
                return TerminalErrors::MB_DOES_NOT_EXIST;
            }

            // Already updated this MB, can continue to next
            if (tempConfirmationMB.mPushedFurtherIntoSetupZone > 0)
            {
                continue;
            }

            // Don't need to worry about MBs before possible mitigation of setup zone
            // Setting them to IS_FALSE will lead to false positives and negatives. Just leave them as NOT_CHECKED
            if (tempConfirmationMB.StartIndex() > lowerEarliestSetupZoneMitigationIndex)
            {
                continue;
            }

            if (tempSetupMB.Type() == OP_BUY)
            {
                double currentMBLow = iLow(tempConfirmationMB.Symbol(), tempConfirmationMB.TimeFrame(), tempConfirmationMB.LowIndex());
                if (currentMBLow > tempSetupZone.EntryPrice())
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                    continue;
                }

                if (currentMBLow < tempSetupZone.mLowestConfirmationMBLowWithin)
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_TRUE;
                    additionaInformation += " This MB Low: " + currentMBLow +
                                            " Furthest MB low: " + tempSetupZone.mLowestConfirmationMBLowWithin;
                    // need to update furthest so that subsequent MBs are calculated correctly
                    tempSetupZone.mLowestConfirmationMBLowWithin = currentMBLow;
                }
                else
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                }
            }
            else if (tempSetupMB.Type() == OP_SELL)
            {
                double currentMBHigh = iHigh(tempConfirmationMB.Symbol(), tempConfirmationMB.TimeFrame(), tempConfirmationMB.HighIndex());
                if (currentMBHigh < tempSetupZone.EntryPrice())
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                    continue;
                }

                if (currentMBHigh > tempSetupZone.mHighestConfirmationMBHighWithin)
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_TRUE;

                    // need to update furthest so that subsequent MBs are calculated correctly
                    tempSetupZone.mHighestConfirmationMBHighWithin = currentMBHigh;
                }
                else
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                }
            }
        }
    }
    // first MB In Zone
    else if (!tempSetupZone.mFurthestPointWasSet)
    {
        additionaInformation += " First MB In Zone: " + mostRecentMB.Number();

        if (tempSetupMB.Type() == OP_BUY)
        {
            double currentMBLow = iLow(mostRecentMB.Symbol(), mostRecentMB.TimeFrame(), mostRecentMB.LowIndex());
            if (currentMBLow > tempSetupZone.EntryPrice())
            {
                mostRecentMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                return ExecutionErrors::MB_NOT_IN_ZONE;
            }

            tempSetupZone.mLowestConfirmationMBLowWithin = currentMBLow;
        }
        else if (tempSetupMB.Type() == OP_SELL)
        {
            double currentMBHigh = iHigh(mostRecentMB.Symbol(), mostRecentMB.TimeFrame(), mostRecentMB.HighIndex());
            if (currentMBHigh < tempSetupZone.EntryPrice())
            {
                mostRecentMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                return ExecutionErrors::MB_NOT_IN_ZONE;
            }

            tempSetupZone.mHighestConfirmationMBHighWithin = currentMBHigh;
        }

        mostRecentMB.mPushedFurtherIntoSetupZone = Status::IS_TRUE;
        tempSetupZone.mFurthestPointWasSet = true;
    }

    // check to see if our nth mb was further
    MBState *nthMB;
    if (!confirmationMBT.GetNthMostRecentMB(nthConfirmationMB, nthMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    additionaInformation += " Nth MB is Further: " + nthMB.mPushedFurtherIntoSetupZone;
    pushedFurtherIntoZone = nthMB.mPushedFurtherIntoSetupZone == Status::IS_TRUE;
    return Errors::NO_ERROR;
}

static int SetupHelper::MBRetappedDeepestHoldingSetupZone(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &retappedZone,
                                                          string &additionalInformation)
{
    retappedZone = false;

    MBState *tempSetupMB;
    if (!setupMBT.GetMB(setupMBNumber, tempSetupMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempSetupZone;
    if (!tempSetupMB.GetDeepestHoldingZone(tempSetupZone))
    {
        return ExecutionErrors::NO_ZONES;
    }

    additionalInformation += " Zone Entry: " + tempSetupZone.EntryPrice();

    int lowerEarliestSetupZoneMitigationIndex = GetEarlierSetupZoneMitigationIndexForLowerTimeFrame(tempSetupZone, confirmationMBT);
    if (lowerEarliestSetupZoneMitigationIndex == EMPTY)
    {
        return ExecutionErrors::LOWER_EARLIEST_SETUP_ZONE_MITIGATION_NOT_FOUND;
    }

    MBState *mostRecentMB;
    if (!confirmationMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    // only update if our most recent mb hasn't been calcualted
    if (mostRecentMB.mInsideSetupZone == 0)
    {
        // Loop through all MBs that may not have been checked. Can happen when the current candle breaks the zone but doens't close below it. IsHolding() will return
        // false for the temporary time that the candle is below the zone but will return True when it comes back before it
        // don't have to go from oldest to newest since they don't depend on each other
        for (int i = 0; i < confirmationMBT.CurrentMBs(); i++)
        {
            MBState *tempConfirmationMBState;
            if (!confirmationMBT.GetNthMostRecentMB(i, tempConfirmationMBState))
            {
                return TerminalErrors::MB_DOES_NOT_EXIST;
            }

            // All MBs Are Updated
            if (tempConfirmationMBState.mInsideSetupZone > 0)
            {
                break;
            }

            // Don't need to worry about MBs before possible mitigation of setup zone
            // Setting them to IS_FALSE will lead to false positives and negatives. Just leave them as NOT_CHECKED
            if (tempConfirmationMBState.StartIndex() > lowerEarliestSetupZoneMitigationIndex)
            {
                break;
            }

            if (tempSetupMB.Type() == OP_BUY)
            {
                bool isInZone = iLow(confirmationMBT.Symbol(), confirmationMBT.TimeFrame(), tempConfirmationMBState.LowIndex()) <= tempSetupZone.EntryPrice();
                if (isInZone)
                {
                    tempConfirmationMBState.mInsideSetupZone = Status::IS_TRUE;
                }
                else
                {
                    tempSetupZone.mFurthestPointWasSet = false;
                    tempConfirmationMBState.mInsideSetupZone = Status::IS_FALSE;
                }
            }
            else if (tempSetupMB.Type() == OP_SELL)
            {
                bool isInZone = iHigh(confirmationMBT.Symbol(), confirmationMBT.TimeFrame(), tempConfirmationMBState.HighIndex()) >= tempSetupZone.EntryPrice();
                if (isInZone)
                {
                    tempConfirmationMBState.mInsideSetupZone = Status::IS_TRUE;
                }
                else
                {
                    tempSetupZone.mFurthestPointWasSet = false;
                    tempConfirmationMBState.mInsideSetupZone = Status::IS_FALSE;
                }
            }

            tempConfirmationMBState.mSetupZoneNumber = tempSetupZone.Number();
        }
    }

    MBState *nthMB;
    if (!confirmationMBT.GetNthMostRecentMB(nthConfirmationMB, nthMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    MBState *previousMB;
    if (!confirmationMBT.GetPreviousMB(nthMB.Number(), previousMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    // First tap into a zone
    if (previousMB.mInsideSetupZone == Status::NOT_CHECKED || previousMB.mSetupZoneNumber != nthMB.mSetupZoneNumber)
    {
        retappedZone = nthMB.mInsideSetupZone == Status::IS_TRUE;
    }
    else
    {
        retappedZone = nthMB.mInsideSetupZone == Status::IS_TRUE && previousMB.mInsideSetupZone == Status::IS_FALSE;
    }

    return Errors::NO_ERROR;
}

static int SetupHelper::SetupZoneIsValidForConfirmation(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &isTrue, string &additionalInformation)
{
    isTrue = false;

    string info = "";
    // Have to call retapped zone first since it can reset pushed further
    bool retappedZone = false;
    int retappedError = MBRetappedDeepestHoldingSetupZone(setupMBNumber, nthConfirmationMB, setupMBT, confirmationMBT, retappedZone, info);

    additionalInformation += " Retapped Zone: " + retappedZone + " Error: " + retappedError + " Info: " + info;
    if (retappedError != Errors::NO_ERROR)
    {
        return retappedError;
    }

    info = "";
    bool pushedFurtherIntoZone = false;
    int pushedFurtherError = MBPushedFurtherIntoDeepestHoldingSetupZone(setupMBNumber, nthConfirmationMB, setupMBT, confirmationMBT, pushedFurtherIntoZone, info);

    additionalInformation += " Pushed Further: " + pushedFurtherIntoZone + " Error: " + pushedFurtherError + " Info: " + info;
    if (pushedFurtherError != Errors::NO_ERROR)
    {
        return pushedFurtherError;
    }

    isTrue = retappedZone || pushedFurtherIntoZone;
    return Errors::NO_ERROR;
}
/*

   __  __ _         ____   ___   ____     _____                      _____ _                  ____  _                          ____       _                 __  __      _   _               _
  |  \/  (_)_ __   |  _ \ / _ \ / ___|   |  ___| __ ___  _ __ ___   |_   _(_)_ __ ___   ___  / ___|| |_ __ _ _ __ ___  _ __   / ___|  ___| |_ _   _ _ __   |  \/  | ___| |_| |__   ___   __| |___
  | |\/| | | '_ \  | |_) | | | | |       | |_ | '__/ _ \| '_ ` _ \    | | | | '_ ` _ \ / _ \ \___ \| __/ _` | '_ ` _ \| '_ \  \___ \ / _ \ __| | | | '_ \  | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
  | |  | | | | | | |  _ <| |_| | |___ _  |  _|| | | (_) | | | | | |   | | | | | | | | |  __/  ___) | || (_| | | | | | | |_) |  ___) |  __/ |_| |_| | |_) | | |  | |  __/ |_| | | | (_) | (_| \__ \
  |_|  |_|_|_| |_| |_| \_\\___/ \____(_) |_|  |_|  \___/|_| |_| |_|   |_| |_|_| |_| |_|\___| |____/ \__\__,_|_| |_| |_| .__/  |____/ \___|\__|\__,_| .__/  |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
                                                                                                                      |_|                          |_|

*/
// ---------------- Min ROC From Time Stamp Setup Methods
// Will check if there is a break of structure after a Min ROC From Time Stamp has occured
// The First Time this is true ensures that the msot recent mb is the first opposite one
static int SetupHelper::BreakAfterMinROC(MinROCFromTimeStamp *&mrfts, MBTracker *&mbt, out bool &isTrue)
{
    isTrue = false;

    if (mrfts.Symbol() != mbt.Symbol())
    {
        return TerminalErrors::NOT_EQUAL_SYMBOLS;
    }

    if (mrfts.TimeFrame() != mbt.TimeFrame())
    {
        return TerminalErrors::NOT_EQUAL_TIMEFRAMES;
    }

    if (!mrfts.HadMinROC() || !mbt.NthMostRecentMBIsOpposite(0))
    {
        return Errors::NO_ERROR;
    }

    MBState *tempMBStates[];
    if (!mbt.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    // only use the mb if it broke after we have a min roc. This makes sure we don't use an mb that broke its previous mb and then we
    // had a min roc before another mb is created
    if (iTime(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].EndIndex()) <= mrfts.MinROCAchievedTime())
    {
        return Errors::NO_ERROR;
    }

    bool bothAbove = iLow(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[1].LowIndex()) > mrfts.OpenPrice() && iLow(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].LowIndex()) > mrfts.OpenPrice();
    bool bothBelow = iHigh(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[1].HighIndex()) < mrfts.OpenPrice() && iHigh(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].HighIndex()) < mrfts.OpenPrice();

    bool breakingUp = bothBelow && tempMBStates[0].Type() == OP_BUY;
    bool breakingDown = bothAbove && tempMBStates[0].Type() == OP_SELL;

    isTrue = breakingUp || breakingDown;
    return Errors::NO_ERROR;
}

// bullish candlestick pattern where a candle wick liquidates the candle low before it
// hopint to see price break up after
static bool SetupHelper::HammerCandleStickPattern(string symbol, int timeFrame, int startingCandle)
{
    // bool HighNotAbovePreviuos = iHigh(symbol, timeFrame, startingCandle) < iHigh(symbol, timeFrame, startingCandle + 1);
    bool bodyNotBelowPrevious = MathMin(iOpen(symbol, timeFrame, startingCandle), iClose(symbol, timeFrame, startingCandle)) >= iLow(symbol, timeFrame, startingCandle + 1);
    bool wickBelowPreviuos = iLow(symbol, timeFrame, startingCandle) < iLow(symbol, timeFrame, startingCandle + 1);

    return bodyNotBelowPrevious && wickBelowPreviuos;
}

static bool SetupHelper::HammerCandleStickPatternBreak(string symbol, int timeFrame, bool useBody = true)
{
    // bool HighNotAbovePreviuos = iHigh(symbol, timeFrame, 2) < iHigh(symbol, timeFrame, 3);
    bool bodyNotBelowPrevious = MathMin(iOpen(symbol, timeFrame, 2), iClose(symbol, timeFrame, 2)) > iLow(symbol, timeFrame, 3);
    bool wickBelowPreviuos = iLow(symbol, timeFrame, 2) < iLow(symbol, timeFrame, 3);
    bool breakHigher = (useBody && MathMax(iOpen(symbol, timeFrame, 1), iClose(symbol, timeFrame, 1)) > iHigh(symbol, timeFrame, 2)) ||
                       (!useBody && iHigh(symbol, timeFrame, 1) > iHigh(symbol, timeFrame, 2));

    return bodyNotBelowPrevious && wickBelowPreviuos && breakHigher;
}

// bearish candlestick pattern where a candle wick liqudiates the candle high before it
// hoping to see price break down after
static bool SetupHelper::ShootingStarCandleStickPattern(string symbol, int timeFrame, int startingCandle)
{
    // bool lowNotBelowPrevious = iLow(symbol, timeFrame, startingCandle) > iLow(symbol, timeFrame, startingCandle + 1);
    bool bodyNotAbovePrevious = MathMax(iOpen(symbol, timeFrame, startingCandle), iClose(symbol, timeFrame, startingCandle)) <= iHigh(symbol, timeFrame, startingCandle + 1);
    bool wickAbovePrevious = iHigh(symbol, timeFrame, startingCandle) > iHigh(symbol, timeFrame, startingCandle + 1);

    return bodyNotAbovePrevious && wickAbovePrevious;
}

static bool SetupHelper::ShootingStarCandleStickPatternBreak(string symbol, int timeFrame, bool useBody = true)
{
    // bool lowNotBelowPrevious = iLow(symbol, timeFrame, 2) > iLow(symbol, timeFrame, 3);
    bool bodyNotAbovePrevious = MathMax(iOpen(symbol, timeFrame, 2), iClose(symbol, timeFrame, 2)) < iHigh(symbol, timeFrame, 3);
    bool wickAbovePrevious = iHigh(symbol, timeFrame, 2) > iHigh(symbol, timeFrame, 3);
    bool breakLower = (useBody && MathMin(iOpen(symbol, timeFrame, 1), iClose(symbol, timeFrame, 1)) < iLow(symbol, timeFrame, 2)) ||
                      (!useBody && iLow(symbol, timeFrame, 1) < iLow(symbol, timeFrame, 2));

    return bodyNotAbovePrevious && wickAbovePrevious && breakLower;
}

static bool SetupHelper::BullishEngulfing(string symbol, int timeFrame, int startingCandle)
{
    bool isBullish = iOpen(symbol, timeFrame, startingCandle) < iClose(symbol, timeFrame, startingCandle);
    bool belowPreviousBody = MathMin(iOpen(symbol, timeFrame, startingCandle + 1), iClose(symbol, timeFrame, startingCandle + 1)) >= iOpen(symbol, timeFrame, startingCandle);
    bool bodyAbovePreviousHigh = iHigh(symbol, timeFrame, startingCandle + 1) < iClose(symbol, timeFrame, startingCandle);

    return isBullish && belowPreviousBody && bodyAbovePreviousHigh;
}

static bool SetupHelper::BearishEngulfing(string symbol, int timeFrame, int startingCandle)
{
    bool isBearish = iOpen(symbol, timeFrame, startingCandle) > iClose(symbol, timeFrame, startingCandle);
    bool abovePreviousBody = MathMax(iOpen(symbol, timeFrame, startingCandle + 1), iClose(symbol, timeFrame, startingCandle + 1)) <= iOpen(symbol, timeFrame, startingCandle);
    bool bodyBelowPreviousLow = iLow(symbol, timeFrame, startingCandle + 1) > iClose(symbol, timeFrame, startingCandle);

    return isBearish && abovePreviousBody && bodyBelowPreviousLow;
}