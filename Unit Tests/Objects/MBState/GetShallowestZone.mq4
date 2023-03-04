//+------------------------------------------------------------------+
//|                                            GetShallowestZone.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Trackers\MBTracker.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/MBState/GetShallowestZone/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 1;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/file/d/1FKgyM8ss5-hC3ncZCzfURRvb4C5s6Sj1/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *IsShallowestZoneUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    IsShallowestZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Is Shallowest Zone", "Should Return True Indicating The Zones Number Is 0",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, IsShallowestZone);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete IsShallowestZoneUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    IsShallowestZoneUnitTest.Assert();
}

int IsShallowestZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
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

    if (tempZoneState.EntryIndex() <= tempMBState.EndIndex())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Zone Number: " + IntegerToString(tempZoneState.Number());
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = tempZoneState.Number() == MaxZonesInMB - tempMBState.ZoneCount();
    return Results::UNIT_TEST_RAN;
}