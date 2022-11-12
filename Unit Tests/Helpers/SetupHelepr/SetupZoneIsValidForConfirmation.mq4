//+------------------------------------------------------------------+
//|                         SetupZoneIsValidForConfirmationSetup.mq4 |
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

const string Directory = "/UnitTests/Helpers/SetupHelper/SetupZoneIsValidForConfirmation/";
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

BoolUnitTest<DefaultUnitTestRecord> *AnyResultUnitTest;

int OnInit()
{
    AnyResultUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Any Result", "Any Result",
        NumberOfAsserts, true, AnyResult);

    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 200, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete ConfirmationMBT;

    delete AnyResultUnitTest;
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
        AnyResultUnitTest.Assert();
        mbsCreated = ConfirmationMBT.MBsCreated();
    }
}

int AnyResult(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    static int MBOneNumber = EMPTY;
    static int MBTwoNumber = EMPTY;
    static int LiquidationMBNumber = EMPTY;

    if (MBOneNumber == EMPTY)
    {
        MBState *mostRecentMB;
        if (!SetupMBT.GetNthMostRecentMB(0, mostRecentMB))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if (mostRecentMB.Type() != OP_BUY)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        MBOneNumber = mostRecentMB.Number();
    }

    if (MBOneNumber != EMPTY && MBTwoNumber == EMPTY)
    {
        MBState *subsequentMB;
        if (!SetupMBT.GetSubsequentMB(MBOneNumber, subsequentMB))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if (subsequentMB.Type() != OP_BUY)
        {
            MBOneNumber = EMPTY;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        MBTwoNumber = subsequentMB.Number();
    }

    if (MBOneNumber != EMPTY && MBTwoNumber != EMPTY && LiquidationMBNumber == EMPTY)
    {
        MBState *liquidationMB;
        if (!SetupMBT.GetSubsequentMB(MBTwoNumber, liquidationMB))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if (liquidationMB.Type() != OP_SELL)
        {
            MBOneNumber = EMPTY;
            MBTwoNumber = EMPTY;

            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        LiquidationMBNumber = liquidationMB.Number();
    }

    if (MBOneNumber == EMPTY || MBTwoNumber == EMPTY || LiquidationMBNumber == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!SetupMBT.GetMB(MBOneNumber, tempMBState))
    {
        MBOneNumber = EMPTY;
        MBTwoNumber = EMPTY;
        LiquidationMBNumber = EMPTY;

        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetDeepestHoldingZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool isTrue = false;
    string additionalInformation;
    int error = SetupHelper::SetupZoneIsValidForConfirmation(tempMBState.Number(), 1, SetupMBT, ConfirmationMBT, isTrue, additionalInformation);
    // if (error != ERR_NO_ERROR)
    // {
    //     return error;
    // }

    ut.PendingRecord.AdditionalInformation = additionalInformation;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);
    count += 1;
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count, 8000, 4400);
    count += 1;
    actual = isTrue;

    return Results::UNIT_TEST_RAN;
}