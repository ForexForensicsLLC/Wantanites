//+------------------------------------------------------------------+
//|                                  MostRecentMBPlusHoldingZone.mq4 |
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

const string Directory = "/UnitTests/Helpers/SetupHelper/MostRecentMBPlusHoldingZone/";
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

// https://drive.google.com/file/d/1MVdqEZUyL60R_oLXdU8_0mxqfoNrKzNj/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *MBIsNotMostRecentErrorUnitTest;

// https://drive.google.com/file/d/1xwRIVSUS74Cuzwuu4g2Rzc5nld54ROBN/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasSetupUnitTest;

// https://drive.google.com/file/d/1euJ9s4_a2oPATNMgY-d0RTl3D7Gblq0o/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoesNotHaveSetupUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    MBIsNotMostRecentErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "MB Is Not Most Recent Error", "Returns MB Is Not Most Recent Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::MB_IS_NOT_MOST_RECENT, MBIsNotMostRecentError);

    HasSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Setup", "Should Return True Indicating There Is A Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, HasSetup);

    DoesNotHaveSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Does Not Has Setup", "Should Return False Indicating There Is Not A Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, DoesNotHaveSetup);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete MBIsNotMostRecentErrorUnitTest;

    delete HasSetupUnitTest;
    delete DoesNotHaveSetupUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    MBIsNotMostRecentErrorUnitTest.Assert();

    HasSetupUnitTest.Assert();
    DoesNotHaveSetupUnitTest.Assert();
}

int MBIsNotMostRecentError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(1, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    MBIsNotMostRecentErrorUnitTest.TryTakeScreenShot();

    bool isTrue = false;
    actual = SetupHelper::MostRecentMBPlusHoldingZone(tempMBState.Number(), MBT, isTrue);

    return Results::UNIT_TEST_RAN;
}

int HasSetup(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!tempMBState.ClosestValidZoneIsHolding(EMPTY))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    HasSetupUnitTest.TryTakeScreenShot();

    SetupHelper::MostRecentMBPlusHoldingZone(tempMBState.Number(), MBT, actual);
    return Results::UNIT_TEST_RAN;
}

int DoesNotHaveSetup(bool &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.ClosestValidZoneIsHolding(EMPTY))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    DoesNotHaveSetupUnitTest.TryTakeScreenShot();

    SetupHelper::MostRecentMBPlusHoldingZone(tempMBState.Number(), MBT, actual);
    return Results::UNIT_TEST_RAN;
}
