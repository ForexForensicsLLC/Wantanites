//+------------------------------------------------------------------+
//|                                                   CreateZone.mq4 |
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
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/MB/CreateZone/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 0;
const bool RecordErrors = true;

input int MBsToTrack = 5;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowZoneWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/drive/folders/1GcOzUTiNmLQwNk33agwbRDoQe9LEk__B?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DemandZoneImagesUnitTest;

// https://drive.google.com/drive/folders/1VP440ru2UahYyY-DDj_Y1SmQSgsfnhJW?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *SupplyZoneImagesUnitTest;
int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowZoneWickBreaks, PrintErrors, CalculateOnTick);

    DemandZoneImagesUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Demand Zone Images", "Images Of Demand Zones",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DemandZoneImages);

    SupplyZoneImagesUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Supply Zone Images", "Images Of Supply Zones",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, SupplyZoneImages);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete DemandZoneImagesUnitTest;
    delete SupplyZoneImagesUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    DemandZoneImagesUnitTest.Assert();
    SupplyZoneImagesUnitTest.Assert();
}

int DemandZoneImages(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int newMBNumber = EMPTY;

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (newMBNumber == tempMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.ZoneCount() == 0)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Total Zones: " + IntegerToString(tempMBState.ZoneCount()) + " " + tempMBState.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    newMBNumber = tempMBState.Number();

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int SupplyZoneImages(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int newMBNumber = EMPTY;

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (newMBNumber == tempMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.ZoneCount() == 0)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Total Zones: " + IntegerToString(tempMBState.ZoneCount()) + " " + tempMBState.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    newMBNumber = tempMBState.Number();

    actual = true;
    return Results::UNIT_TEST_RAN;
}
