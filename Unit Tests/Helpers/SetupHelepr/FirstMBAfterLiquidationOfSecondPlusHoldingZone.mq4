//+------------------------------------------------------------------+
//|               FirstMBAfterLiquidationOfSecondPlusHoldingZone.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Errors.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/SetupHelper/FirstMBAfterLiquidationOfSecondPlusHoldingZone/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = true;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

BoolUnitTest<DefaultUnitTestRecord> *HasBullishSetupUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *HasBearishSetupUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    HasBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Bullish Setup", "Should Return True Indicating There Is A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, HasBullishSetup);

    HasBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Bearish Setup", "Should Return True Indicating There Is A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, HasBearishSetup);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete HasBullishSetupUnitTest;
    delete HasBearishSetupUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    HasBullishSetupUnitTest.Assert();
    HasBearishSetupUnitTest.Assert();
}

int SetSetupVariables(int type, int &secondMBNumber, int &thirdMBNumber, int &setupType, bool &reset)
{
    if (reset)
    {
        secondMBNumber = EMPTY;
        thirdMBNumber = EMPTY;
        setupType = EMPTY;
        reset = false;
    }

    if (MBT.HasNMostRecentConsecutiveMBs(3))
    {
        reset = true;
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (secondMBNumber != EMPTY)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            reset = true;
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }
    }

    if (secondMBNumber == EMPTY)
    {
        MBState *secondTempMBState;
        if (MBT.NthMostRecentMBIsOpposite(1) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != type)
            {
                return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
            }

            secondMBNumber = secondTempMBState.Number();
            setupType = secondTempMBState.Type();
        }
    }
    else if (thirdMBNumber == EMPTY)
    {
        MBState *thirdTempMBState;
        if (!MBT.GetMB(secondMBNumber + 1, thirdTempMBState))
        {
            reset = true;
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        if (thirdTempMBState.Type() == type)
        {
            reset = true;
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }

    return ERR_NO_ERROR;
}

int HasBullishSetup(bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(OP_BUY, secondMBNumber, thirdMBNumber, setupType, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    if (thirdMBNumber == EMPTY)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *thirdTempMBState;
    if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
    {
        reset = true;
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    MBState *firstTempMBState;
    if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
    {
        reset = true;
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    MBState *secondTempMBState;
    if (!MBT.GetMB(secondMBNumber, secondTempMBState))
    {
        reset = true;
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (!iLow(secondTempMBState.Symbol(), secondTempMBState.TimeFrame(), 0) < iLow(secondTempMBState.Symbol(), secondTempMBState.TimeFrame(), secondTempMBState.LowIndex()))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (!firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        reset = true;
        return setupError;
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}

int HasBearishSetup(bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(OP_SELL, secondMBNumber, thirdMBNumber, setupType, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    if (thirdMBNumber == EMPTY)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *thirdTempMBState;
    if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
    {
        reset = true;
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    MBState *firstTempMBState;
    if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
    {
        reset = true;
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    MBState *secondTempMBState;
    if (!MBT.GetMB(secondMBNumber, secondTempMBState))
    {
        reset = true;
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (!iHigh(secondTempMBState.Symbol(), secondTempMBState.TimeFrame(), 0) > iHigh(secondTempMBState.Symbol(), secondTempMBState.TimeFrame(), secondTempMBState.HighIndex()))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (!firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        reset = true;
        return setupError;
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}
