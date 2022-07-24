//+------------------------------------------------------------------+
//|                                                     Template.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#property show_inputs

// Make sure path is correct
#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>
#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 7;
input double RiskPercent = 0.25;

// -- MBTracker Inputs
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

// --- EA Globals ---
UnitTest *UT;
MBTracker *MBT;

bool FirstTick = true;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);
    UT = new UnitTest();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
}

void OnTick()
{
    if (FirstTick)
    {
        BrokeMBRangeStart_BullishMBFalse();
        BrokeMBRangeStart_BearishMBFalse();

        BreakAfterMinROC_DifferentSymbolsError();
        BreakAfterMinROC_DifferentTimeFramesError();
        BreakAfterMinROC_NoMinROCIsTrueEqualsFalse();

        FirstTick = false;
    }
    else
    {
        BrokeMBRangeStart_BullishMBTrue();
        BrokeMBRangeStart_BearishMBTrue();

        BrokeDoubleMBPlusLiquidationEnd_BullishSetupTrue();
        BrokeDoubleMBPlusLiquidationEnd_BearishSetupTrue();
        BrokeDoubleMBPlusLiquidationEnd_BullishSetupFalse();
        BrokeDoubleMBPlusLiquidationEnd_BearishSetupFalse();
        BrokeDoubleMBPlusLiquidationEnd_EqualBullishTypesError();
        BrokeDoubleMBPlusLiquidationEnd_EqualBearishTypesError();

        MostRecentMBPlusHoldingZone_MostRecentError();
        MostRecentMBPlusHoldingZone_True();
        MostRecentMBPlusHoldingZone_False();

        FirstMBAfterLiquidationOfSecondPlusHoldingZone_BullishTrue();
        FirstMBAfterLiquidationOfSecondPlusHoldingZone_BearishTrue();

        BreakAfterMinROC_NotOppositeMBIsTrueEqualsFalse();
        BreakAfterMinROC_BullishSetupTrue();
        BreakAfterMinROC_BearishSetupTrue();
    }
}

void BrokeMBRangeStart_BullishMBTrue()
{
    static int mbNumber = -1;

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return;
    }

    if (mbNumber == -1)
    {
        mbNumber = tempMBState.Number();
    }

    if (MBT.MBIsMostRecent(mbNumber))
    {
        return;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetMB(mbNumber + 1, tempMBStateTwo))
    {
        return;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        mbNumber = -1;
        return;
    }

    bool expected = true;
    bool actual;
    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        mbNumber = -1;
        return;
    }

    UT.addTest(__FUNCTION__);
    UT.assertEquals(__FUNCTION__, "Broke MB Start Range on Bullish MB", expected, actual);
}

void BrokeMBRangeStart_BearishMBTrue()
{
    static int mbNumber = -1;

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return;
    }

    if (mbNumber == -1)
    {
        mbNumber = tempMBState.Number();
    }

    if (MBT.MBIsMostRecent(mbNumber))
    {
        return;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetMB(mbNumber + 1, tempMBStateTwo))
    {
        return;
    }

    if (tempMBState.Type() == OP_SELL)
    {
        mbNumber = -1;
        return;
    }

    bool expected = true;
    bool actual;
    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        mbNumber = -1;
        return;
    }

    UT.addTest(__FUNCTION__);
    UT.assertEquals(__FUNCTION__, "Broke MB Start Range on Bearish MB", expected, actual);
}

void BrokeMBRangeStart_BullishMBFalse()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return;
    }

    bool expected = false;
    bool actual;
    int brokeRangeError = SetupHelper::BrokeMBRangeStart(tempMBState.Number(), MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        return;
    }

    UT.addTest(__FUNCTION__);
    UT.assertEquals(__FUNCTION__, "Did Not Brake MB Start Range on Bullish MB", expected, actual);
}

void BrokeMBRangeStart_BearishMBFalse()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return;
    }

    bool expected = false;
    bool actual;
    int brokeRangeError = SetupHelper::BrokeMBRangeStart(tempMBState.Number(), MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        return;
    }

    UT.addTest(__FUNCTION__);
    UT.assertEquals(__FUNCTION__, "Did Not Brake MB Start Range on Bullish MB", expected, actual);
}

void BrokeDoubleMBPlusLiquidationEnd_BullishSetupTrue()
{
    static int secondMBNumber = -1;
    static int thirdMBNumber = -1;
    static int setupType = -1;

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        secondMBNumber = -1;
        thirdMBNumber = -1;
        setupType = -1;
        return;
    }

    if (secondMBNumber != -1)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }
    }

    if (secondMBNumber == -1)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(2) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != OP_BUY)
            {
                return;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == -1)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            return;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }
    else
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        double price = iHigh(Symbol(), Period(), 0);
        double end = iHigh(Symbol(), Period(), thirdTempMBState.StartIndex());

        if (price > end)
        {
            bool expected = true;
            bool actual = false;
            int error = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
            if (error != ERR_NO_ERROR)
            {
                UT.addTest(__FUNCTION__);
                UT.assertEquals(__FUNCTION__, "Broke Double MB Plus Liquidation Bullish Setup True", expected, actual);
            }
        }
    }
}

void BrokeDoubleMBPlusLiquidationEnd_BearishSetupTrue()
{
    static int secondMBNumber = -1;
    static int thirdMBNumber = -1;
    static int setupType = -1;

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        secondMBNumber = -1;
        thirdMBNumber = -1;
        setupType = -1;
        return;
    }

    if (secondMBNumber != -1)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }
    }

    if (secondMBNumber == -1)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(2) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != OP_SELL)
            {
                return;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == -1)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            return;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }
    else
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        double price = iLow(Symbol(), Period(), 0);
        double end = iLow(Symbol(), Period(), thirdTempMBState.StartIndex());

        if (price < end)
        {
            bool expected = true;
            bool actual = false;
            int error = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
            if (error != ERR_NO_ERROR)
            {
                UT.addTest(__FUNCTION__);
                UT.assertEquals(__FUNCTION__, "Broke Double MB Plus Liquidation Bearish Setup True", expected, actual);
            }
        }
    }
}

void BrokeDoubleMBPlusLiquidationEnd_BullishSetupFalse()
{
    static int secondMBNumber = -1;
    static int thirdMBNumber = -1;
    static int setupType = -1;

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        secondMBNumber = -1;
        thirdMBNumber = -1;
        setupType = -1;
        return;
    }

    if (secondMBNumber != -1)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }
    }

    if (secondMBNumber == -1)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(2) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != OP_BUY)
            {
                return;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == -1)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            return;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }
    else
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        double price = iHigh(Symbol(), Period(), 0);
        double end = iHigh(Symbol(), Period(), thirdTempMBState.StartIndex());

        if (price <= end)
        {
            bool expected = false;
            bool actual = true;
            int error = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
            if (error != ERR_NO_ERROR)
            {
                UT.addTest(__FUNCTION__);
                UT.assertEquals(__FUNCTION__, "Did Not Break Double MB Plus Liquidation Bullish Setup", expected, actual);
            }
        }
    }
}

void BrokeDoubleMBPlusLiquidationEnd_BearishSetupFalse()
{
    static int secondMBNumber = -1;
    static int thirdMBNumber = -1;
    static int setupType = -1;

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        secondMBNumber = -1;
        thirdMBNumber = -1;
        setupType = -1;
        return;
    }

    if (secondMBNumber != -1)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }
    }

    if (secondMBNumber == -1)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(2) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != OP_SELL)
            {
                return;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == -1)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            return;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }
    else
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        double price = iLow(Symbol(), Period(), 0);
        double end = iLow(Symbol(), Period(), thirdTempMBState.StartIndex());

        if (price >= end)
        {
            bool expected = false;
            bool actual = true;
            int error = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
            if (error != ERR_NO_ERROR)
            {
                UT.addTest(__FUNCTION__);
                UT.assertEquals(__FUNCTION__, "Did Not Break Double MB Plus Liquidation Bearish Setup", expected, actual);
            }
        }
    }
}

void BrokeDoubleMBPlusLiquidationEnd_EqualBullishTypesError()
{
    if (!MBT.HasNMostRecentConsecutiveMBs(3))
    {
        return;
    }

    MBState *secondTempMBState;
    if (!MBT.GetNthMostRecentMB(1, secondTempMBState))
    {
        return;
    }

    if (secondTempMBState.Type() != OP_BUY)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    bool isTrue = false;
    int expected = Errors::ERR_EQUAL_MB_TYPES;
    int actual = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondTempMBState.Number(), secondTempMBState.Type(), MBT, isTrue);

    UT.assertEquals(__FUNCTION__, "Broke Double MB Plus Liquidation Equal Bullish Types Error", expected, actual);
}

void BrokeDoubleMBPlusLiquidationEnd_EqualBearishTypesError()
{
    if (!MBT.HasNMostRecentConsecutiveMBs(3))
    {
        return;
    }

    MBState *secondTempMBState;
    if (!MBT.GetNthMostRecentMB(1, secondTempMBState))
    {
        return;
    }

    if (secondTempMBState.Type() != OP_SELL)
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    bool isTrue = false;
    int expected = Errors::ERR_EQUAL_MB_TYPES;
    int actual = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondTempMBState.Number(), secondTempMBState.Type(), MBT, isTrue);

    UT.assertEquals(__FUNCTION__, "Broke Double MB Plus Liquidation Equal Bearish Types Error", expected, actual);
}

void MostRecentMBPlusHoldingZone_MostRecentError()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(1, tempMBState))
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    bool isTrue = false;
    int expected = Errors::ERR_MB_IS_NOT_MOST_RECENT;
    int actual = SetupHelper::MostRecentMBPlusHoldingZone(tempMBState.Number(), MBT, isTrue);

    UT.assertEquals(__FUNCTION__, "Most Recent Pending MB Plus Zone Is Holding Most Recent Error", expected, actual);
}

void MostRecentMBPlusHoldingZone_True()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (!tempMBState.ClosestValidZoneIsHolding(-1))
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    bool expected = true;
    bool actual = false;
    SetupHelper::MostRecentMBPlusHoldingZone(tempMBState.Number(), MBT, actual);

    UT.assertEquals(__FUNCTION__, "Most Recent Pending MB Plus Zone Is Holding True", expected, actual);
}

void MostRecentMBPlusHoldingZone_False()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return;
    }

    if (tempMBState.ClosestValidZoneIsHolding(-1))
    {
        return;
    }

    UT.addTest(__FUNCTION__);

    bool expected = false;
    bool actual = true;
    SetupHelper::MostRecentMBPlusHoldingZone(tempMBState.Number(), MBT, actual);

    UT.assertEquals(__FUNCTION__, "Most Recent Pending MB Plus Zone Is Holding False", expected, actual);
}

void FirstMBAfterLiquidationOfSecondPlusHoldingZone_BullishTrue()
{
    static int secondMBNumber = -1;
    static int thirdMBNumber = -1;
    static int setupType = -1;

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        secondMBNumber = -1;
        thirdMBNumber = -1;
        setupType = -1;
        return;
    }

    if (secondMBNumber != -1)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }
    }

    if (secondMBNumber == -1)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(2) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != OP_BUY)
            {
                return;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == -1)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            return;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }
    else
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        MBState *firstTempMBState;
        if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
        {
            return;
        }

        if (!firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
        {
            return;
        }

        bool expected = true;
        bool actual = false;

        int error = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
        if (error != ERR_NO_ERROR)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        UT.addTest(__FUNCTION__);
        UT.assertEquals(__FUNCTION__, "First MB After Liquidation Of Second Plush Holding Zone Bullish Setup True", expected, actual);
    }
}

void FirstMBAfterLiquidationOfSecondPlusHoldingZone_BearishTrue()
{
    static int secondMBNumber = -1;
    static int thirdMBNumber = -1;
    static int setupType = -1;

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        secondMBNumber = -1;
        thirdMBNumber = -1;
        setupType = -1;
        return;
    }

    if (secondMBNumber != -1)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }
    }

    if (secondMBNumber == -1)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(2) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != OP_SELL)
            {
                return;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == -1)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            return;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }
    else
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        MBState *firstTempMBState;
        if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
        {
            return;
        }

        if (!firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
        {
            return;
        }

        bool expected = true;
        bool actual = false;

        int error = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
        if (error != ERR_NO_ERROR)
        {
            secondMBNumber = -1;
            thirdMBNumber = -1;
            setupType = -1;
            return;
        }

        UT.addTest(__FUNCTION__);
        UT.assertEquals(__FUNCTION__, "First MB After Liquidation Of Second Plush Holding Zone Bearish Setup True", expected, actual);
    }
}

void BreakAfterMinROC_DifferentSymbolsError()
{
    string symbol = MBT.Symbol() != "US100.cash" ? "US100.cash" : "EURUSD";

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(symbol, Period(), 10, 10, 10, 10, 0.25);

    UT.addTest(__FUNCTION__);

    bool isTrue = false;
    int expected = Errors::ERR_NOT_EQUAL_SYMBOLS;
    int actual = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    UT.assertEquals(__FUNCTION__, "Break After Min ROC Different Symbols Error", expected, actual);
}

void BreakAfterMinROC_DifferentTimeFramesError()
{
    string timeFrame = MBT.TimeFrame() != "1h" ? "1h" : "4h";

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), timeFrame, 10, 10, 10, 10, 0.25);

    UT.addTest(__FUNCTION__);

    bool isTrue = false;
    int expected = Errors::ERR_NOT_EQUAL_TIMEFRAMES;
    int actual = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    UT.assertEquals(__FUNCTION__, "Break After Min ROC Different TimeFrames Error", expected, actual);
}

void BreakAfterMinROC_NoMinROCIsTrueEqualsFalse()
{
    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.5);

    if (tempMRFTS.HadMinROC())
    {
        return;
    }

    bool expected = false;
    bool actual = true;
    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
    if (error != ERR_NO_ERROR)
    {
        return;
    }

    UT.addTest(__FUNCTION__);
    UT.assertEquals(__FUNCTION__, "Break After Min ROC. No Min ROC isTrue returns false", expected, actual);
}

void BreakAfterMinROC_NotOppositeMBIsTrueEqualsFalse()
{
    if (MBT.NthMostRecentMBIsOpposite(0))
    {
        return;
    }

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.5);

    bool expected = false;
    bool actual = true;
    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
    if (error != ERR_NO_ERROR)
    {
        return;
    }

    UT.addTest(__FUNCTION__);
    UT.assertEquals(__FUNCTION__, "Break After Min ROC. Not Opposite MB isTrue returns false", expected, actual);
}

void BreakAfterMinROC_BullishSetupTrue()
{
    static MinROCFromTimeStamp *tempMRFTS;

    if (CheckPointer(tempMRFTS) == POINTER_INVALID)
    {
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.05);
    }

    if (!tempMRFTS.HadMinROC())
    {
        return;
    }

    if (!MBT.NthMostRecentMBIsOpposite(0))
    {
        return;
    }

    MBState *tempMBStates[];

    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return;
    }

    bool bothBelow = iHigh(Symbol(), Period(), tempMBStates[1].HighIndex()) < tempMRFTS.OpenPrice() && iHigh(Symbol(), Period(), tempMBStates[0].HighIndex()) < tempMRFTS.OpenPrice();
    bool breakingUp = bothBelow && tempMBStates[0].Type() == OP_BUY;

    if (breakingUp)
    {
        bool expected = true;
        bool actual = false;
        SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);

        UT.addTest(__FUNCTION__);
        UT.assertEquals(__FUNCTION__, "Break After Min. ROC Bullish Setup True", expected, actual);
    }
}

void BreakAfterMinROC_BearishSetupTrue()
{
    static MinROCFromTimeStamp *tempMRFTS;

    if (CheckPointer(tempMRFTS) == POINTER_INVALID)
    {
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.05);
    }

    if (!tempMRFTS.HadMinROC())
    {
        return;
    }

    if (!MBT.NthMostRecentMBIsOpposite(0))
    {
        return;
    }

    MBState *tempMBStates[];

    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return;
    }

    bool bothAbove = iLow(Symbol(), Period(), tempMBStates[1].LowIndex()) > tempMRFTS.OpenPrice() && iLow(Symbol(), Period(), tempMBStates[0].LowIndex()) > tempMRFTS.OpenPrice();
    bool breakingDown = bothAbove && tempMBStates[0].Type() == OP_SELL;

    if (breakingDown)
    {
        bool expected = true;
        bool actual = false;
        SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);

        UT.addTest(__FUNCTION__);
        UT.assertEquals(__FUNCTION__, "Break After Min. ROC Bearish Setup True", expected, actual);
    }
}