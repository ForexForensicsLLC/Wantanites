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

BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakLiquidationMBInBullishSetupUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakLiquidationMBInBearishSetupUnitTest;

IntUnitTest<DefaultUnitTestRecord> *ThreeConsecutiveBullishMBErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *ThreeConsecutiveBearishMBErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    HasBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Bullish Setup", "Should Return True Indicating that there Is A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, HasBullishSetup);

    HasBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Bearish Setup", "Should Return True Indicating that there Is A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, HasBearishSetup);

    DidNotBreakLiquidationMBInBullishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Break Liquidation MB In Bullish Setup", "Should Return False Indicating that the MB That Liquidated The Second In A Bullish Setup Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, DidNotBreakLiquidationMBInBullishSetup);

    DidNotBreakLiquidationMBInBearishSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Break Liquidation MB In Bearish Setup", "Should Return False Indicating that the MB That Liquidated The Second In A Bearish Setup Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, DidNotBreakLiquidationMBInBearishSetup);

    ThreeConsecutiveBullishMBErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Three Consecutive Bullish MBs Error", "Should Return Equal MB Types Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::EQUAL_MB_TYPES, ThreeConsecutiveBullishMBError);

    ThreeConsecutiveBearishMBErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Three Consecutive Bearish MBs Error", "Should Return Equal MB Types Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
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

    DidNotBreakLiquidationMBInBullishSetupUnitTest.Assert();
    DidNotBreakLiquidationMBInBearishSetupUnitTest.Assert();

    ThreeConsecutiveBullishMBErrorUnitTest.Assert();
    ThreeConsecutiveBearishMBErrorUnitTest.Assert();
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
        return Results::UNIT_TEST_DID_NOT_RUN;
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
        if (MBT.NthMostRecentMBIsOpposite(1) && MBT.HasNMostRecentConsecutiveMBs(2) && MBT.GetNthMostRecentMB(0, secondTempMBState))
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

int HasBullishSetup(bool &actual)
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

    if (price <= end)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = false;
    int setupError = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondMBNumber, setupType, MBT, actual);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int HasBearishSetup(bool &actual)
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

    if (price >= end)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

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

    bool isTrue = false;
    actual = SetupHelper::BrokeDoubleMBPlusLiquidationSetupRangeEnd(secondTempMBState.Number(), secondTempMBState.Type(), MBT, isTrue);

    return Results::UNIT_TEST_RAN;
}
