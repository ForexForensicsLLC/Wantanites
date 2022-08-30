//+------------------------------------------------------------------+
//|                                      MBPushedFurtherIntoZone.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/SetupHelper/MBPushedFurtherIntoSetupZone/";
const int NumberOfAsserts = 1000;
const int AssertCooldown = 0;
const bool RecordErrors = true;

input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

BoolUnitTest<DefaultUnitTestRecord> *PushedFurtherIntoBullishZoneUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *PushedFurtherIntoBearishZoneUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *DidNotPushFurtherIntoZoneUnitTest;

int OnInit()
{
    PushedFurtherIntoBullishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Pushed Further Into Bullish Zone", "Should return true indicating the MB pushed further into the zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, PushedFurtherIntoBullishZone);

    PushedFurtherIntoBearishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Pushed Further Into Bearish Zone", "Should return true indicating the MB pushed further into the zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, PushedFurtherIntoBearishZone);

    DidNotPushFurtherIntoZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Push Further Into Zone", "Should return false indicating the MB did not push further into the zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, DidNotPushFurtherIntoZone);

    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 200, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete ConfirmationMBT;

    delete PushedFurtherIntoBullishZoneUnitTest;
    delete PushedFurtherIntoBearishZoneUnitTest;

    delete DidNotPushFurtherIntoZoneUnitTest;
}

int BarsCalculated = 0;

void OnTick()
{
    SetupMBT.DrawNMostRecentMBs(1);
    SetupMBT.DrawZonesForNMostRecentMBs(1);

    ConfirmationMBT.DrawNMostRecentMBs(1);
    ConfirmationMBT.DrawZonesForNMostRecentMBs(1);

    int bars = iBars(ConfirmationMBT.Symbol(), ConfirmationMBT.TimeFrame());
    int limit = bars - BarsCalculated;

    if (limit > 0)
    {
        PushedFurtherIntoBullishZoneUnitTest.Assert();
        PushedFurtherIntoBearishZoneUnitTest.Assert();

        DidNotPushFurtherIntoZoneUnitTest.Assert();

        BarsCalculated = bars;
    }
}

int PushedFurtherIntoBullishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    static int prevMBNumber = EMPTY;

    MBState *tempConfirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(0, tempConfirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    /*
    if (prevMBNumber == tempConfirmationMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }
    */

    MBState *tempMBState;
    if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!SetupMBT.MBsClosestValidZoneIsHolding(tempMBState.Number(), tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool pushedFurtherIntoZone = false;
    string info;

    int error = SetupHelper::MBPushedFurtherIntoSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, info);
    ut.PendingRecord.AdditionalInformation = info;

    if (error != ERR_NO_ERROR)
    {
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
        count += 1;
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
        count += 1;

        return error;
    }

    if (!pushedFurtherIntoZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    prevMBNumber = tempConfirmationMBState.Number();
    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}

int PushedFurtherIntoBearishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    static int prevMBNumber = EMPTY;

    MBState *tempConfirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(0, tempConfirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    /*
    if (prevMBNumber == tempConfirmationMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }
    */

    MBState *tempMBState;
    if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!SetupMBT.MBsClosestValidZoneIsHolding(tempMBState.Number(), tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool pushedFurtherIntoZone = false;
    string info;

    int error = SetupHelper::MBPushedFurtherIntoSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, info);
    ut.PendingRecord.AdditionalInformation = info;

    if (error != ERR_NO_ERROR)
    {
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
        count += 1;
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
        count += 1;
        return error;
    }

    if (!pushedFurtherIntoZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    prevMBNumber = tempConfirmationMBState.Number();
    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}

int DidNotPushFurtherIntoZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int prevMBNumber = EMPTY;
    static int count = 0;

    MBState *tempConfirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(0, tempConfirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    /*
    if (prevMBNumber == tempConfirmationMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }
    */

    MBState *tempMBState;
    if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!SetupMBT.MBsClosestValidZoneIsHolding(tempMBState.Number(), tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool pushedFurtherIntoZone = false;
    string info;

    int error = SetupHelper::MBPushedFurtherIntoSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, info);
    ut.PendingRecord.AdditionalInformation = info;

    if (error != ERR_NO_ERROR)
    {
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
        count += 1;
        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
        count += 1;

        return error;
    }

    if (pushedFurtherIntoZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    prevMBNumber = tempConfirmationMBState.Number();

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;
    return Results::UNIT_TEST_RAN;
}