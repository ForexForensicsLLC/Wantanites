//+------------------------------------------------------------------+
//|                                              AboveSupplyZone.mq4 |
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

const string Directory = "/UnitTests/Objects/ZoneState/AboveSupplyZone/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *AllowZoneWickBreaksMBT;
MBTracker *DoNotAllowZoneWickBreaksMBT;

// https://drive.google.com/file/d/1Hi-QB2Sex4Oh27qcm8TL45zHCqdlC1p1/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *AllowWicksIsAboveSupplyZoneUnitTest;

// https://drive.google.com/file/d/1N1eorsBaA3W0x0axXXKolHuQEU45mz8s/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *AllowWicksIsBelowSupplyZoneUnitTest;

// https://drive.google.com/file/d/1IUmscKlTRxNRPIk6heandvz1_rruGloo/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoNotAllowWicksIsAboveSupplyZoneUnitTest;

// https://drive.google.com/file/d/1CHK8rOymBLX-rmhLPEx-dCx55A1Np3AW/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoNotAllowWicksIsBelowSupplyZoneUnitTest;

int OnInit()
{
    AllowZoneWickBreaksMBT = new MBTracker(Symbol(), Period(),
                                           MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    DoNotAllowZoneWickBreaksMBT = new MBTracker(Symbol(), Period(),
                                                MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, false, PrintErrors, CalculateOnTick);

    AllowWicksIsAboveSupplyZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Allow Wicks Is Above", "Allow Wicks And Is Above The Shallowest Supply Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, AllowWicksIsAboveSupplyZone);

    AllowWicksIsBelowSupplyZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Allow Wicks Is Below", "Allow Wicks And Is Below The Shallowest Supply Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, AllowWicksIsBelowSupplyZone);

    DoNotAllowWicksIsAboveSupplyZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Do not Allow Wicks Is Above", "Do Not Allow Wicks And Is Above The Shallowest Supply Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DoNotAllowWicksIsAboveSupplyZone);

    DoNotAllowWicksIsBelowSupplyZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Do not Allow Wicks Is Below", "Do Not Allow Wicks And Is Below The Shallowest Supply Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DoNotAllowWicksIsBelowSupplyZone);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete AllowZoneWickBreaksMBT;
    delete DoNotAllowZoneWickBreaksMBT;

    delete AllowWicksIsAboveSupplyZoneUnitTest;
    delete AllowWicksIsBelowSupplyZoneUnitTest;

    delete DoNotAllowWicksIsAboveSupplyZoneUnitTest;
    delete DoNotAllowWicksIsBelowSupplyZoneUnitTest;
}

void OnTick()
{
    AllowZoneWickBreaksMBT.DrawNMostRecentMBs(1);
    AllowZoneWickBreaksMBT.DrawZonesForNMostRecentMBs(1);

    AllowWicksIsAboveSupplyZoneUnitTest.Assert();
    AllowWicksIsBelowSupplyZoneUnitTest.Assert();

    DoNotAllowWicksIsAboveSupplyZoneUnitTest.Assert();
    DoNotAllowWicksIsBelowSupplyZoneUnitTest.Assert();
}

int CheckSetup(bool allowWicks, bool shouldBeAboveSupplyZone, double &entryPrice, double &exitPrice)
{
    MBState *tempMBState;
    if (allowWicks)
    {
        if (!AllowZoneWickBreaksMBT.GetNthMostRecentMB(0, tempMBState))
        {
            return TerminalErrors::MB_DOES_NOT_EXIST;
        }
    }
    else
    {
        if (!DoNotAllowZoneWickBreaksMBT.GetNthMostRecentMB(0, tempMBState))
        {
            return TerminalErrors::MB_DOES_NOT_EXIST;
        }
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetShallowestZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool aboveSupplyZone = tempZoneState.AboveSupplyZone(0);
    if ((shouldBeAboveSupplyZone && !aboveSupplyZone) || (!shouldBeAboveSupplyZone && aboveSupplyZone))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    entryPrice = tempZoneState.EntryPrice();
    exitPrice = tempZoneState.ExitPrice();

    return Errors::NO_ERROR;
}

int AllowWicksIsAboveSupplyZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(true, true, entryPrice, exitPrice);
    if (result != Errors::NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int AllowWicksIsBelowSupplyZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(true, false, entryPrice, exitPrice);
    if (result != Errors::NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int DoNotAllowWicksIsAboveSupplyZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(false, true, entryPrice, exitPrice);
    if (result != Errors::NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int DoNotAllowWicksIsBelowSupplyZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(false, false, entryPrice, exitPrice);
    if (result != Errors::NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}