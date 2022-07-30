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

    FirstMBAfterLiquidationOfSecondPlusHoldingZone_BullishTrue();
    FirstMBAfterLiquidationOfSecondPlusHoldingZone_BearishTrue();
}

void FirstMBAfterLiquidationOfSecondPlusHoldingZone_BullishTrue()
{
    static int tests = 0;
    static int maxTests = 10;

    if (tests >= maxTests)
    {
        return;
    }

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

        if (tests == 0)
        {
            UT.addTest(__FUNCTION__);
        }

        UT.assertEquals(__FUNCTION__, "First MB After Liquidation Of Second Plush Holding Zone Bullish Setup True", expected, actual);
        tests += 1;
    }
}

void FirstMBAfterLiquidationOfSecondPlusHoldingZone_BearishTrue()
{
    static int tests = 0;
    static int maxTests = 10;

    if (tests >= maxTests)
    {
        return;
    }

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

        if (tests == 0)
        {
            UT.addTest(__FUNCTION__);
        }

        UT.assertEquals(__FUNCTION__, "First MB After Liquidation Of Second Plush Holding Zone Bearish Setup True", expected, actual);
        tests += 1;
    }
}
