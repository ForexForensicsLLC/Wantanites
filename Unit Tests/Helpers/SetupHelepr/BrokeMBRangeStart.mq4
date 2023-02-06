//+------------------------------------------------------------------+
//|                                            BrokeMBRangeStart.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Constants\Index.mqh>

#include <WantaCapital\Framework\Trackers\MBTracker.mqh>
#include <WantaCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <WantaCapital\Framework\Helpers\SetupHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/SetupHelper/BrokeMBRangeStart/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/file/d/1vMTnIdg9z1VkIMp7gPSfATVMzw6GMNue/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BrokeBullishMBUnitTest;

// https://drive.google.com/file/d/1XHgzEBF0-B7wKwe5T7xSYZeH7-x_I0D2/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BrokeBearishMBUnitTest;

// https://drive.google.com/file/d/1VYqJJt1Su1kcXlwpi64YZl-bpzaeiOLr/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakBullishMBUnitTest;

// https://drive.google.com/file/d/1_Ppr4eveekIXnps7pTNtbus8pAIElSQu/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakBearishMBUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BrokeBullishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broke Bullish MB", "Should Return True Indicating That The Previous Bullish Start Range Was Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BrokeBullishMB);

    BrokeBearishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broke Bearish MB", "Should Return True Indicating That The Previous Bearish Start Range Was Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BrokeBearishMB);

    DidNotBreakBullishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Break Bullish MB", "Should Return False Indicating That The Previous Bullish Start Range Was Not Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, DidNotBreakBullishMB);

    DidNotBreakBearishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Break Bearish MB", "Should Return False Indicating That The Previous Bearish Start Range Was Not Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, DidNotBreakBearishMB);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BrokeBullishMBUnitTest;
    delete BrokeBearishMBUnitTest;

    delete DidNotBreakBullishMBUnitTest;
    delete DidNotBreakBearishMBUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BrokeBullishMBUnitTest.Assert();
    BrokeBearishMBUnitTest.Assert();

    DidNotBreakBullishMBUnitTest.Assert();
    DidNotBreakBearishMBUnitTest.Assert();
}

int BrokeBullishMB(bool &actual)
{
    static int mbNumber = EMPTY;
    static bool reset = false;

    if (reset)
    {
        mbNumber = EMPTY;
        reset = false;
    }

    BrokeBullishMBUnitTest.PendingRecord.AdditionalInformation = "MBNumber: " + IntegerToString(mbNumber);

    if (mbNumber == EMPTY)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            reset = true;
            return TerminalErrors::MB_DOES_NOT_EXIST;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();
    }

    if (MBT.MBIsMostRecent(mbNumber))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetSubsequentMB(mbNumber, tempMBStateTwo))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBStateTwo.Type() == OP_BUY)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BrokeBullishMBUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(BrokeBullishMBUnitTest.Directory());

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        reset = true;
        return brokeRangeError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BrokeBearishMB(bool &actual)
{
    static int mbNumber = EMPTY;
    static bool reset = false;

    if (reset)
    {
        mbNumber = EMPTY;
        reset = false;
    }

    if (mbNumber == EMPTY)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            reset = true;
            return TerminalErrors::MB_DOES_NOT_EXIST;
        }

        if (tempMBState.Type() != OP_SELL)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();
    }

    if (MBT.MBIsMostRecent(mbNumber))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetSubsequentMB(mbNumber, tempMBStateTwo))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBStateTwo.Type() == OP_SELL)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BrokeBearishMBUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(BrokeBearishMBUnitTest.Directory());

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        reset = true;
        return brokeRangeError;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int DidNotBreakBullishMB(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    DidNotBreakBullishMBUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(DidNotBreakBullishMBUnitTest.Directory());

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(tempMBState.Number(), MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        return brokeRangeError;
    }

    return Results::UNIT_TEST_RAN;
}

int DidNotBreakBearishMB(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    DidNotBreakBearishMBUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(DidNotBreakBearishMBUnitTest.Directory());

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(tempMBState.Number(), MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        return brokeRangeError;
    }

    return Results::UNIT_TEST_RAN;
}