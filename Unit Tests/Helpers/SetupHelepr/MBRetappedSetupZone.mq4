//+------------------------------------------------------------------+
//|                                          MBRetappedSetupZone.mq4 |
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

const string Directory = "/UnitTests/Helpers/SetupHelper/MBRetappedSetupZone/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 1;
const bool RecordErrors = true;

input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

BoolUnitTest<DefaultUnitTestRecord> *RetappedBullishZoneUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *RetappedBearishZoneUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *DidNotRetapZoneUnitTest;

int OnInit()
{
    RetappedBullishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Retapped Bullish Zone", "Should return true indicating the zone was retapped",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, RetappedBullishZone);

    RetappedBearishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Retapped Bearish Zone", "Should return true indicating the zone was retapped",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, RetappedBearishZone);

    DidNotRetapZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Retap Zone", "Should return false indicating the zone was not retapped",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, DidNotRetapZone);

    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete ConfirmationMBT;

    delete RetappedBullishZoneUnitTest;
    delete RetappedBearishZoneUnitTest;

    delete DidNotRetapZoneUnitTest;
}

void OnTick()
{
    SetupMBT.DrawNMostRecentMBs(1);
    SetupMBT.DrawZonesForNMostRecentMBs(1);

    ConfirmationMBT.DrawNMostRecentMBs(1);
    ConfirmationMBT.DrawZonesForNMostRecentMBs(1);

    RetappedBullishZoneUnitTest.Assert();
    RetappedBearishZoneUnitTest.Assert();

    DidNotRetapZoneUnitTest.Assert();
}

int RetappedBullishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
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

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, retappedZone);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    if (!retappedZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    actual = retappedZone;

    return Results::UNIT_TEST_RAN;
}

int RetappedBearishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
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

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, retappedZone);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    if (!retappedZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    actual = retappedZone;

    return Results::UNIT_TEST_RAN;
}

int DidNotRetapZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    MBState *tempMBState;
    if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!SetupMBT.MBsClosestValidZoneIsHolding(tempMBState.Number(), tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, retappedZone);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    if (retappedZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    actual = retappedZone;

    return Results::UNIT_TEST_RAN;
}
