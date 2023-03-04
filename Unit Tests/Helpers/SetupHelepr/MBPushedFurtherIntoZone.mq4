//+------------------------------------------------------------------+
//|                                      MBPushedFurtherIntoZone.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Trackers\MBTracker.mqh>
#include <Wantanites\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/SetupHelper/MBPushedFurtherIntoSetupZone/";
const int NumberOfAsserts = 10000;

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

BoolUnitTest<DefaultUnitTestRecord> *FirstnthMBPushedFurtherIntoBullishZoneUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *SecondthMBPushedFurtherIntoBullishZoneUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *ZerothIsTrueUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *OnethIsTrueUnitTest;

int OnInit()
{
    PushedFurtherIntoBullishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "0th MB Further Into Bullish Zone", "Should return true indicating the MB pushed further into the zone",
        NumberOfAsserts, true, PushedFurtherIntoBullishZone);

    PushedFurtherIntoBearishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Pushed Further Into Bearish Zone", "Should return true indicating the MB pushed further into the zone",
        NumberOfAsserts, true, PushedFurtherIntoBearishZone);

    FirstnthMBPushedFurtherIntoBullishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "1nth MB pushed further into Bullish Zone", "Should return true indicating the 1nth mb pushed further",
        NumberOfAsserts, true, FirstnthMBPushedFurtherIntoBullishZone);

    SecondthMBPushedFurtherIntoBullishZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "2nth MB pushed further into bullish zone", "Should return true indicating the 2nth mb pushed further",
        NumberOfAsserts, true, SecondthMBPushedFurtherIntoBullishZone);

    ZerothIsTrueUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "0th MB is true", "Should return true indicating the 2nth mb pushed further",
        NumberOfAsserts, true, ZerothIsTrue);

    OnethIsTrueUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "1th MB is true", "Should return true indicating the 2nth mb pushed further",
        NumberOfAsserts, true, OnethIsTrue);

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

    delete FirstnthMBPushedFurtherIntoBullishZoneUnitTest;
    delete SecondthMBPushedFurtherIntoBullishZoneUnitTest;

    delete ZerothIsTrueUnitTest;
    delete OnethIsTrueUnitTest;
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
        // PushedFurtherIntoBullishZoneUnitTest.Assert();
        //  PushedFurtherIntoBearishZoneUnitTest.Assert();

        // FirstnthMBPushedFurtherIntoBullishZoneUnitTest.Assert();
        // SecondthMBPushedFurtherIntoBullishZoneUnitTest.Assert();

        ZerothIsTrueUnitTest.Assert();
        OnethIsTrueUnitTest.Assert();

        mbsCreated = ConfirmationMBT.MBsCreated();
    }
}

int PushedFurtherIntoBullishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

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

    bool pushedFurtherIntoZone = false;
    string additionalInformation;

    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(tempMBState.Number(), 0, SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(0, confirmationMBState))
    {
        return error;
    }

    ut.PendingRecord.AdditionalInformation = "Confirmation MB : " + confirmationMBState.Number() + " Pushed Further: " + confirmationMBState.mPushedFurtherIntoSetupZone;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}

int PushedFurtherIntoBearishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

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

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool pushedFurtherIntoZone = false;
    string additionalInformation;

    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(tempMBState.Number(), 0, SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, additionalInformation);
    ut.PendingRecord.AdditionalInformation = additionalInformation;

    if (error != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;
    return Results::UNIT_TEST_RAN;
}

int FirstnthMBPushedFurtherIntoBullishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

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

    string additionalInformation;
    bool pushedFurtherIntoZone = false;
    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(tempMBState.Number(), 1, SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(1, confirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.AdditionalInformation = "Confirmation MB : " + confirmationMBState.Number() + " Pushed Further: " + confirmationMBState.mPushedFurtherIntoSetupZone;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}

int SecondthMBPushedFurtherIntoBullishZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

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

    string additionalInformation;
    bool pushedFurtherIntoZone = false;
    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(tempMBState.Number(), 2, SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(2, confirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.AdditionalInformation = "Confirmation MB : " + confirmationMBState.Number() + " Pushed Further: " + confirmationMBState.mPushedFurtherIntoSetupZone;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}

int ZerothIsTrue(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

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

    string additionalInformation;
    bool pushedFurtherIntoZone = false;
    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(tempMBState.Number(), 0, SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    if (!pushedFurtherIntoZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(2, confirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.AdditionalInformation = "Confirmation MB : " + confirmationMBState.Number() + " Pushed Further: " + confirmationMBState.mPushedFurtherIntoSetupZone + additionalInformation;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}

int OnethIsTrue(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

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

    string additionalInformation;
    bool pushedFurtherIntoZone = false;
    int error = SetupHelper::MBPushedFurtherIntoDeepestHoldingSetupZone(tempMBState.Number(), 1, SetupMBT, ConfirmationMBT, pushedFurtherIntoZone, additionalInformation);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    if (!pushedFurtherIntoZone)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *confirmationMBState;
    if (!ConfirmationMBT.GetNthMostRecentMB(2, confirmationMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.AdditionalInformation = "Confirmation MB : " + confirmationMBState.Number() + " Pushed Further: " + confirmationMBState.mPushedFurtherIntoSetupZone + additionalInformation;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;

    actual = pushedFurtherIntoZone;

    return Results::UNIT_TEST_RAN;
}