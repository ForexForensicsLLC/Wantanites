//+------------------------------------------------------------------+
//|               FirstMBAfterLiquidationOfSecondPlusHoldingZone.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/SetupHelper/FirstMBAfterLiquidationOfSecondPlusHoldingZone/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

input int MBsToTrack = 5;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/drive/folders/1r5hjIZHRG6PzFuPMX_Os9q-_ChVk-Leg?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasBullishSetupUnitTest;

// https://drive.google.com/drive/folders/1kLCjJVBldI9FwpMbphxzk8UeCpeDfGyp?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasBearishSetupUnitTest;

// https://drive.google.com/drive/folders/1-KKdrjAYhGKhM-p0Aw2luM20e2Ex64QA?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoesNotHaveBullishSetupUnitTest;

// https://drive.google.com/drive/folders/1BJMKNW0ArwUEqTZJmtf3DP9WBB_5cYx3?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoesNotHaveBearishSetupUnitTest;

const int MinCooldDown = 1;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    HasBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Bullish Setup", "Should Return True Indicating There Is A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasBullishSetup);

    HasBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Bearish Setup", "Should Return True Indicating There Is A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasBearishSetup);

    DoesNotHaveBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Does Not Have Bullish Setup", "Should Return False Indicating There Is Not A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, DoesNotHaveBullishSetup);

    DoesNotHaveBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Does Not Have Bearish Setup", "Should Return False Indicating There Is Not A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, DoesNotHaveBearishSetup);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete HasBullishSetupUnitTest;
    delete HasBearishSetupUnitTest;

    delete DoesNotHaveBullishSetupUnitTest;
    delete DoesNotHaveBearishSetupUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    HasBullishSetupUnitTest.Assert();
    HasBearishSetupUnitTest.Assert();

    DoesNotHaveBearishSetupUnitTest.Assert();
    DoesNotHaveBullishSetupUnitTest.Assert();
}

int SetSetupVariables(int type, int &secondMBNumber, int &thirdMBNumber, int &setupType, bool &reset, datetime &cooldown, int &count)
{
    if (reset)
    {
        secondMBNumber = EMPTY;
        thirdMBNumber = EMPTY;
        setupType = EMPTY;
        reset = false;
        cooldown = TimeCurrent();
        count = 0;
    }

    if (!PastCooldown(cooldown))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (secondMBNumber != EMPTY)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }
    }

    if (thirdMBNumber != EMPTY)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BrokeMBRangeStart(thirdMBNumber, MBT, isTrue);
        if (setupError != ERR_NO_ERROR || isTrue)
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }
    }

    if (secondMBNumber == EMPTY)
    {
        MBState *secondTempMBState;
        if (MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
        {
            if (secondTempMBState.Type() != type)
            {
                return Results::UNIT_TEST_DID_NOT_RUN;
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
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if (thirdTempMBState.Type() == type)
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        thirdMBNumber = thirdTempMBState.Number();
    }

    return ERR_NO_ERROR;
}

bool PastCooldown(datetime cooldown)
{
    if (cooldown == 0)
    {
        return true;
    }

    if (Hour() == TimeHour(cooldown) && (Minute() - TimeMinute(cooldown) >= MinCooldDown))
    {
        return true;
    }

    if (Hour() > TimeHour(cooldown))
    {
        int minutes = (59 - TimeMinute(cooldown)) + Minute();
        return minutes >= MinCooldDown;
    }

    return false;
}

int HasBullishSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;
    static datetime cooldown = 0;
    static int count = 0;

    int setVariablesError = SetSetupVariables(OP_BUY, secondMBNumber, thirdMBNumber, setupType, reset, cooldown, count);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    if (thirdMBNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *thirdTempMBState;
    if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    MBState *firstTempMBState;
    if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    int setupError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        reset = true;
        return setupError;
    }

    count += 1;
    return Results::UNIT_TEST_RAN;
}

int HasBearishSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;
    static datetime cooldown = 0;
    static int count = 0;

    int setVariablesError = SetSetupVariables(OP_SELL, secondMBNumber, thirdMBNumber, setupType, reset, cooldown, count);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    if (thirdMBNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *thirdTempMBState;
    if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    MBState *firstTempMBState;
    if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    int setupError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        reset = true;
        return setupError;
    }

    count += 1;
    return Results::UNIT_TEST_RAN;
}

int DoesNotHaveBullishSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;
    static datetime cooldown = 0;
    static int count = 0;

    int setVariablesError = SetSetupVariables(OP_BUY, secondMBNumber, thirdMBNumber, setupType, reset, cooldown, count);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    if (thirdMBNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *thirdTempMBState;
    if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    MBState *firstTempMBState;
    if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    int setupError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        reset = true;
        return setupError;
    }

    count += 1;
    return Results::UNIT_TEST_RAN;
}

int DoesNotHaveBearishSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;
    static datetime cooldown = 0;
    static int count = 0;

    int setVariablesError = SetSetupVariables(OP_SELL, secondMBNumber, thirdMBNumber, setupType, reset, cooldown, count);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    if (thirdMBNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *thirdTempMBState;
    if (!MBT.GetMB(thirdMBNumber, thirdTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    MBState *firstTempMBState;
    if (!MBT.GetMB(secondMBNumber - 1, firstTempMBState))
    {
        reset = true;
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (firstTempMBState.ClosestValidZoneIsHolding(thirdTempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    int setupError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(secondMBNumber - 1, secondMBNumber, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        reset = true;
        return setupError;
    }

    count += 1;
    return Results::UNIT_TEST_RAN;
}