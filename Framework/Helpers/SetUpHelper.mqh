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

// HasUntestedMethods
class SetupHelper
{
private:
public:
    // ==========================================================================
    // Range Broke Methods
    // ==========================================================================
    // Tested
    static int BrokeMBRangeStart(int mbNumber, MBTracker *&mbt, out bool &isTrue);

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
static int SetupHelper::BrokeMBRangeStart(int mbNumber, MBTracker *&mbt, out bool &isTrue)
{
    isTrue = false;

    MBState *tempMBState;
    if (!mbt.GetMB(mbNumber, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    isTrue = tempMBState.IsBroken(tempMBState.EndIndex());
    return ERR_NO_ERROR;
}

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
    isTrue = thirdTempMBState.IsBroken(thirdTempMBState.StartIndex());
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
