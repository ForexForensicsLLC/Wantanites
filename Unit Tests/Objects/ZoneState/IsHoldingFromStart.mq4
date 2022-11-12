//+------------------------------------------------------------------+
//|                                           IsHoldingFromStart.mq4 |
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

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/ZoneState/IsHoldingFromStart/";
const int NumberOfAsserts = 500;
const int AssertCooldown = 0;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

BoolUnitTest<DefaultUnitTestRecord> *IsHoldingFromStartUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *IsNotHoldingFromStartUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    IsHoldingFromStartUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Holding", "Should return true indicating the zone is holding from its start",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, IsHoldingFromStart);

    IsNotHoldingFromStartUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Not Holding", "Should return false indicating the zone is not holding from its start",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, IsNotHoldingFromStart);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete IsHoldingFromStartUnitTest;
    delete IsNotHoldingFromStartUnitTest;
}

int BarsCalculated = 0;

void OnTick()
{
    int bars = iBars(MBT.Symbol(), MBT.TimeFrame());
    int limit = bars - BarsCalculated;

    if (limit > 0)
    {
        MBT.DrawNMostRecentMBs(1);
        MBT.DrawZonesForNMostRecentMBs(1);

        IsHoldingFromStartUnitTest.Assert();
        IsNotHoldingFromStartUnitTest.Assert();

        BarsCalculated = bars;
    }
}

int IsHoldingFromStart(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetShallowestZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!tempZoneState.IsHoldingFromStart())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = tempMBState.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);

    actual = true;
    count += 1;

    return Results::UNIT_TEST_RAN;
}

int IsNotHoldingFromStart(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetShallowestZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempZoneState.IsHoldingFromStart())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = tempMBState.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), "_" + count);

    actual = false;
    count += 1;

    return Results::UNIT_TEST_RAN;
}
