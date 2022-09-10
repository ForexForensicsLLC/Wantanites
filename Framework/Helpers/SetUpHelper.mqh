//+------------------------------------------------------------------+
//|                                                  SetupHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Constants\Index.mqh>

class SetupHelper
{
public:
    // ==========================================================================
    // Range Broke Methods
    // ==========================================================================
    // Tested
    static int BrokeDoubleMBPlusLiquidationSetupRangeEnd(int secondMBInSetup, int setupType, MBTracker *&mbt, out bool &isTrue);

    // ==========================================================================
    // MB Setup Methods
    // ==========================================================================
    // Tested
    static int MostRecentMBPlusHoldingZone(int mostRecentMBNumber, MBTracker *&mbt, out bool &isTrue);

    // Tested
    static int FirstMBAfterLiquidationOfSecondPlusHoldingZone(int mbOneNumber, int mbTwoNumber, MBTracker *&mbt, out bool &isTrue);

    // !Tested
    static int SameTypeSubsequentMB(int mbNumber, MBTracker *&mbt, out bool isTrue);

private:
    static int GetSetupMBValidationOnLowerTimeFrame(MBState *setupMB, MBTracker *confirmationMBT);

public:
    // Tested
    static int MBPushedFurtherIntoDeepestHoldingSetupZone(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &pushedFurtherIntoZone,
                                                          string &additionaInformation);

private:
    static int GetEarlierSetupZoneMitigationIndexForLowerTimeFrame(ZoneState *setupZone, MBTracker *confirmationMBT);

public:
    // Tested
    static int MBRetappedDeepestHoldingSetupZone(int setupMBNumber, int nthConfirmationMB, MBTracker *&setupMBT, MBTracker *&confirmationMBT, bool &retappedZone,
                                                 string &additionalInformation);

    // ==========================================================================
    // Min ROC. From Time Stamp Setup Methods
    // ==========================================================================
    // Tested
    static int BreakAfterMinROC(MinROCFromTimeStamp *&mrfts, MBTracker *&mbt, out bool &isTrue);
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
    isTrue = thirdTempMBState.StartIsBroken();
    return ERR_NO_ERROR;
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
    return ERR_NO_ERROR;
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

        isTrue = mbt.MBsClosestValidZoneIsHolding(mbOneNumber, thirdMBTempState.EndIndex());
    }
    else if (secondMBTempMBState.Type() == OP_SELL)
    {
        if (!mbt.GetSubsequentMB(mbTwoNumber, thirdMBTempState))
        {
            return ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST;
        }

        isTrue = mbt.MBsClosestValidZoneIsHolding(mbOneNumber, thirdMBTempState.EndIndex());
    }

    return ERR_NO_ERROR;
}

static int SetupHelper::SameTypeSubsequentMB(int mbNumber, MBTracker *&mbt, out bool isTrue)
{
    isTrue = mbt.MBIsMostRecent(mbNumber + 1) && mbt.HasNMostRecentConsecutiveMBs(2);
    return ERR_NO_ERROR;
}

static int SetupHelper::GetSetupMBValidationOnLowerTimeFrame(MBState *setupMB, MBTracker *confirmationMBT)
{
    datetime mbEndIndexTime = iTime(setupMB.Symbol(), setupMB.TimeFrame(), setupMB.EndIndex());
    int lowerStartMBEndIndex = iBarShift(confirmationMBT.Symbol(), confirmationMBT.TimeFrame(), mbEndIndexTime);
    int lowerEndMBEndIndex = lowerStartMBEndIndex - (confirmationMBT.TimeFrame() * 60);

    if (setupMB.Type() == OP_BUY)
    {
        for (int i = lowerStartMBEndIndex; i >= lowerEndMBEndIndex; i--)
        {
            if (iHigh(confirmationMBT.Symbol(), confirmationMBT.TimeFrame(), i) > iHigh(setupMB.Symbol(), setupMB.TimeFrame(), setupMB.HighIndex()))
            {
                return i;
            }
        }
    }
    else if (setupMB.Type() == OP_SELL)
    {
        for (int i = lowerStartMBEndIndex; i >= lowerEndMBEndIndex; i--)
        {
            if (iLow(confirmationMBT.Symbol(), confirmationMBT.TimeFrame(), i) < iLow(setupMB.Symbol(), setupMB.TimeFrame(), setupMB.LowIndex()))
            {
                return i;
            }
        }
    }

    return EMPTY;
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

    MBState *furthestMB;
    bool foundFurthest = false;

    // find our most recent furthest mb to compare to subsequent mbs
    // start from 0 instead of nthConfirmationMB so that all mbs get updated correctly.
    // If we start from nthConfirmationMB then the foundFurthest check would be inconsistent as well as
    // if we don't happen to check the 0th, and it is the furthest, then that mb just wouldn't get checked and the next one would be considered the
    // furhest, even if it isn't
    for (int j = 0; j < confirmationMBT.CurrentMBs(); j++)
    {
        if (!confirmationMBT.GetNthMostRecentMB(j, furthestMB))
        {
            return TerminalErrors::MB_DOES_NOT_EXIST;
        }

        if (furthestMB.mPushedFurtherIntoSetupZone == Status::IS_TRUE)
        {
            foundFurthest = true;
            break;
        }
    }

    MBState *mostRecentMB;
    if (!confirmationMBT.GetNthMostRecentMB(0, mostRecentMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    // if our most recent mb is updated, then all are updated
    if (foundFurthest && mostRecentMB.mPushedFurtherIntoSetupZone == 0)
    {

        // update all mbs that haven't been checked yet
        // need to go from left to right so that they are updated correctly in the order that they were created
        for (int i = confirmationMBT.CurrentMBs() - 1; i >= 0; i--)
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
                if (iLow(tempConfirmationMB.Symbol(), tempConfirmationMB.TimeFrame(), tempConfirmationMB.LowIndex()) <
                    iLow(furthestMB.Symbol(), furthestMB.TimeFrame(), furthestMB.LowIndex()))
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_TRUE;

                    // need to update furthest so that subsequent MBs are calculated correctly
                    furthestMB = tempConfirmationMB;
                }
                else
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                }
            }
            else if (tempSetupMB.Type() == OP_SELL)
            {
                if (iHigh(tempConfirmationMB.Symbol(), tempConfirmationMB.TimeFrame(), tempConfirmationMB.HighIndex()) >
                    iHigh(furthestMB.Symbol(), furthestMB.TimeFrame(), furthestMB.HighIndex()))
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_TRUE;

                    // need to update furthest so that subsequent MBs are calculated correctly
                    furthestMB = tempConfirmationMB;
                }
                else
                {
                    tempConfirmationMB.mPushedFurtherIntoSetupZone = Status::IS_FALSE;
                }
            }
        }
    }
    // first MB In Zone
    else if (!foundFurthest)
    {
        if (mostRecentMB.mPushedFurtherIntoSetupZone == Status::NOT_CHECKED)
        {
            mostRecentMB.mPushedFurtherIntoSetupZone = Status::IS_TRUE;
        }
    }

    // check to see if our nth mb was further
    MBState *nthMB;
    if (!confirmationMBT.GetNthMostRecentMB(nthConfirmationMB, nthMB))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    pushedFurtherIntoZone = nthMB.mPushedFurtherIntoSetupZone == Status::IS_TRUE;
    return ERR_NO_ERROR;
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

    return ERR_NO_ERROR;
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
        return ERR_NO_ERROR;
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
        return ERR_NO_ERROR;
    }

    bool bothAbove = iLow(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[1].LowIndex()) > mrfts.OpenPrice() && iLow(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].LowIndex()) > mrfts.OpenPrice();
    bool bothBelow = iHigh(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[1].HighIndex()) < mrfts.OpenPrice() && iHigh(mrfts.Symbol(), mrfts.TimeFrame(), tempMBStates[0].HighIndex()) < mrfts.OpenPrice();

    bool breakingUp = bothBelow && tempMBStates[0].Type() == OP_BUY;
    bool breakingDown = bothAbove && tempMBStates[0].Type() == OP_SELL;

    isTrue = breakingUp || breakingDown;
    return ERR_NO_ERROR;
}
