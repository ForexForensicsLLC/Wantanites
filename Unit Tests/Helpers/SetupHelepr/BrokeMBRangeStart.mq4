//+------------------------------------------------------------------+
//|                                            BrokeMBRangeStart.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Errors.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/SetupHelper/BreakAfterMinROC/";
const int NumberOfAsserts = 25;
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

BoolUnitTest<DefaultUnitTestRecord> *BrokeBullishMBUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *BrokeBearishMBUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakBullishMBUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *DidNotBreakBearishMBUnitTest;

int OnInit()
{
    BrokeBullishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broke Bullish MB", "Should Return True Indicating That The Previous Bullish Start Range Was Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BrokeBullishMB);

    BrokeBearishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broke Bearish MB", "Should Return True Indicating That The Previous Bearish Start Range Was Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BrokeBearishMB);

    DidNotBreakBullishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Break Bullish MB", "Should Return True Indicating That The Previous Bullish Start Range Was Not Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, DidNotBreakBullishMB);

    DidNotBreakBearishMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Break Bearish MB", "Should Return True Indicating That The Previous Bearish Start Range Was Not Broken",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, DidNotBreakBearishMB);

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
    BrokeBullishMBUnitTest.Assert();
    BrokeBearishMBUnitTest.Assert();

    DidNotBreakBullishMBUnitTest.Assert();
    DidNotBreakBearishMBUnitTest.Assert();
}

int BrokeBullishMB(bool &actual)
{
    static int mbNumber = -1;
    static bool reset = false;

    if (reset)
    {
        mbNumber = -1;
        reset = false;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (mbNumber == -1)
    {
        mbNumber = tempMBState.Number();
    }

    if (MBT.MBIsMostRecent(mbNumber))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetMB(mbNumber + 1, tempMBStateTwo))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == OP_BUY)
    {
        reset = true;
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        reset = true;
        return brokeRangeError;
    }

    reset = true;
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BrokeBearishMB(bool &actual)
{
    static int mbNumber = -1;
    static bool reset = false;

    if (reset)
    {
        mbNumber = -1;
        reset = false;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (mbNumber == -1)
    {
        mbNumber = tempMBState.Number();
    }

    if (MBT.MBIsMostRecent(mbNumber))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetMB(mbNumber + 1, tempMBStateTwo))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() == OP_SELL)
    {
        reset = true;
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        reset = true;
        return brokeRangeError;
    }

    reset = true;
    return UnitTestConstants::UNIT_TEST_RAN;
}

int DidNotBreakBullishMB(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(tempMBState.Number(), MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        return brokeRangeError;
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}

int DidNotBreakBearishMB(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int brokeRangeError = SetupHelper::BrokeMBRangeStart(tempMBState.Number(), MBT, actual);
    if (brokeRangeError != ERR_NO_ERROR)
    {
        return brokeRangeError;
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}