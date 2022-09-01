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
const int NumberOfAsserts = 10000;
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

BoolUnitTest<DefaultUnitTestRecord> *RetappedBullishZoneUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *RetappedBearishZoneUnitTest;

int OnInit()
{
    RetappedBullishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Retapped Bullish Zone", "Should return true indicating the zone was retapped",
        NumberOfAsserts, true, BullishZone);

    RetappedBearishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Retapped Bearish Zone", "Should return true indicating the zone was retapped",
        NumberOfAsserts, true, BearishZone);

    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 200, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete ConfirmationMBT;

    delete RetappedBullishZoneUnitTest;
    delete RetappedBearishZoneUnitTest;
}

void OnTick()
{
    static int mbsCreated = EMPTY;

    SetupMBT.DrawNMostRecentMBs(1);
    SetupMBT.DrawZonesForNMostRecentMBs(1);

    ConfirmationMBT.DrawNMostRecentMBs(1);
    ConfirmationMBT.DrawZonesForNMostRecentMBs(1);

    if (mbsCreated < ConfirmationMBT.MBsCreated())
    {
        RetappedBullishZoneUnitTest.Assert();
        // RetappedBearishZoneUnitTest.Assert();

        mbsCreated = ConfirmationMBT.MBsCreated();
    }
}

int BullishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    string info = "";

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(0, confirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.AdditionalInformation = "Confirmation MB: " + confirmationMBState.Number();

    MBState *tempMBState;
    if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, retappedZone, info);
    ut.PendingRecord.AdditionalInformation += info;
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;
    actual = retappedZone;

    return Results::UNIT_TEST_RAN;
}

int BearishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    string info = "";

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(0, confirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    info += "Confirmation MB: " + confirmationMBState.Number();
    MBState *tempMBState;
    if (!SetupMBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool retappedZone = false;
    int error = SetupHelper::MBRetappedSetupZone(tempMBState.Number(), SetupMBT, ConfirmationMBT, retappedZone, info);
    ut.PendingRecord.AdditionalInformation = info;
    if (error != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;
    actual = retappedZone;

    return Results::UNIT_TEST_RAN;
}