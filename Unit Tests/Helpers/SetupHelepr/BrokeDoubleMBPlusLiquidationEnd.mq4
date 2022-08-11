//+------------------------------------------------------------------+
//|                              BrokeDoubleMBPlusLiquidationEnd.mq4 |
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

const string Directory = "/UnitTests/Helpers/SetupHelper/BrokeDoubleMBPlusLiquidationEnd/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordErrors = true;

input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/drive/folders/1xCYcFy0KB6WJycE3tjIV4fhPNFLZ6dhg?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasBullishSetupUnitTest;

// https://drive.google.com/drive/folders/1vEBfawzFgpJEs0zEpYEgQAXo6Hna7zq6?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasBearishSetupUnitTest;

// https://drive.google.com/drive/folders/1CFbEtKNu120ZkYd2S_-Nhq7bgEQQkLEM?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakLiquidationMBInBullishSetupUnitTest;

// https://drive.google.com/drive/folders/1Eg6AWnMERbwLAMBa-YZP8GjyuBsnd1dU?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakLiquidationMBInBearishSetupUnitTest;

// https://drive.google.com/drive/folders/1L1Ul379Tf8YIbDRe5_RWHcIK_OljZUt_?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ThreeConsecutiveBullishMBErrorUnitTest;

// https://drive.google.com/drive/folders/10iWn3iaXQKiCLvHlEz4BsChwvKKz9KyZ?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ThreeConsecutiveBearishMBErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    HasBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Liq Has Bullish Setup", "Should Return True Indicating that there Is A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasBullishSetup);

    HasBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Liq Has Bearish Setup", "Should Return True Indicating that there Is A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasBearishSetup);

    DidNotBreakLiquidationMBInBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Liq Does Not Have Bullish Setup", "Should Return False Indicating that the MB That Liquidated The Second In A Bullish Setup Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, DidNotBreakLiquidationMBInBullishSetup);

    DidNotBreakLiquidationMBInBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Liq Does Not Have Bearish Setup", "Should Return False Indicating that the MB That Liquidated The Second In A Bearish Setup Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, DidNotBreakLiquidationMBInBearishSetup);

    ThreeConsecutiveBullishMBErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Liq Three Consecutive Bullish MBs Error", "Should Return Equal MB Types Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        ExecutionErrors::EQUAL_MB_TYPES, ThreeConsecutiveBullishMBError);

    ThreeConsecutiveBearishMBErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Liq Three Consecutive Bearish MBs Error", "Should Return Equal MB Types Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        ExecutionErrors::EQUAL_MB_TYPES, ThreeConsecutiveBearishMBError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete HasBullishSetupUnitTest;
    delete HasBearishSetupUnitTest;

    delete DidNotBreakLiquidationMBInBullishSetupUnitTest;
    delete DidNotBreakLiquidationMBInBearishSetupUnitTest;

    delete ThreeConsecutiveBullishMBErrorUnitTest;
    delete ThreeConsecutiveBearishMBErrorUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    HasBullishSetupUnitTest.Assert();
    HasBearishSetupUnitTest.Assert();

    /*
    DidNotBreakLiquidationMBInBullishSetupUnitTest.Assert();
    DidNotBreakLiquidationMBInBearishSetupUnitTest.Assert();

    ThreeConsecutiveBullishMBErrorUnitTest.Assert();
    ThreeConsecutiveBearishMBErrorUnitTest.Assert();
    */
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

    if (secondMBNumber != EMPTY)
    {
        bool isTrue = false;
        // Broke the first mb in the double mb setup
        int setupError = SetupHelper::BrokeMBRangeStart(secondMBNumber - 1, MBT, isTrue);
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

int HasBullishSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;

    int error = SetSetupVariables(OP_BUY, secondMBNumber, thirdMBNumber, setupType, reset);
    if (error != ERR_NO_ERROR)
    {
        return error;
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

    if (!thirdTempMBState.IsBroken(thirdTempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = false;
    int setupError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int HasBearishSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;

    int error = SetSetupVariables(OP_SELL, secondMBNumber, thirdMBNumber, setupType, reset);
    if (error != ERR_NO_ERROR)
    {
        return error;
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

    if (!thirdTempMBState.IsBroken(thirdTempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = false;
    int setupError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int DidNotBreakLiquidationMBInBullishSetup(bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;

    int error = SetSetupVariables(OP_BUY, secondMBNumber, thirdMBNumber, setupType, reset);
    if (error != ERR_NO_ERROR)
    {
        return error;
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

    double price = iHigh(Symbol(), Period(), 0);
    double end = iHigh(Symbol(), Period(), thirdTempMBState.StartIndex());

    if (price > end)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    DidNotBreakLiquidationMBInBullishSetupUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(DidNotBreakLiquidationMBInBullishSetupUnitTest.Directory());

    actual = true;
    int setupError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int DidNotBreakLiquidationMBInBearishSetup(bool &actual)
{
    static int secondMBNumber = EMPTY;
    static int thirdMBNumber = EMPTY;
    static int setupType = EMPTY;
    static bool reset = false;

    int error = SetSetupVariables(OP_SELL, secondMBNumber, thirdMBNumber, setupType, reset);
    if (error != ERR_NO_ERROR)
    {
        return error;
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

    double price = iHigh(Symbol(), Period(), 0);
    double end = iHigh(Symbol(), Period(), thirdTempMBState.StartIndex());

    if (price < end)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    DidNotBreakLiquidationMBInBearishSetupUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(DidNotBreakLiquidationMBInBearishSetupUnitTest.Directory());

    actual = false;
    int setupError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int ThreeConsecutiveBullishMBError(int &actual)
{
    if (!MBT.HasNMostRecentConsecutiveMBs(3))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *secondTempMBState;
    if (!MBT.GetNthMostRecentMB(1, secondTempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (secondTempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ThreeConsecutiveBullishMBErrorUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ThreeConsecutiveBullishMBErrorUnitTest.Directory());

    bool isTrue = false;
    actual = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondTempMBState.Number(), secondTempMBState.Type(), MBT, isTrue);

    return Results::UNIT_TEST_RAN;
}

int ThreeConsecutiveBearishMBError(int &actual)
{
    if (!MBT.HasNMostRecentConsecutiveMBs(3))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *secondTempMBState;
    if (!MBT.GetNthMostRecentMB(1, secondTempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (secondTempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ThreeConsecutiveBearishMBErrorUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ThreeConsecutiveBearishMBErrorUnitTest.Directory());

    bool isTrue = false;
    actual = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondTempMBState.Number(), secondTempMBState.Type(), MBT, isTrue);

    return Results::UNIT_TEST_RAN;
}
