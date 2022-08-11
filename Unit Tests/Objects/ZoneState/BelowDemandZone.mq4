//+------------------------------------------------------------------+
//|                                              BelowDemandZone.mq4 |
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

const string Directory = "/UnitTests/Objects/ZoneState/BelowDemandZone/";
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

// https://drive.google.com/file/d/1CYuvpE8ZpYS8kIEFWmDl3YgQoz8m_qhQ/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *AllowWicksIsAboveDemandZoneUnitTest;

// https://drive.google.com/file/d/1fyWw3Tdv_57XdRZIVO7tb4sJ2vyKlVD9/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *AllowWicksIsBelowDemandZoneUnitTest;

// https://drive.google.com/file/d/1Dd1TIhSBM3n4KQSzG0mCq9ecsCtGEI8D/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoNotAllowWicksIsAboveDemandZoneUnitTest;

// https://drive.google.com/file/d/1JZ-Pfen6io_YN-TEPBkmryfMLavHgRnr/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *DoNotAllowWicksIsBelowDemandZoneUnitTest;

int OnInit()
{
    AllowZoneWickBreaksMBT = new MBTracker(Symbol(), Period(),
                                           MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    DoNotAllowZoneWickBreaksMBT = new MBTracker(Symbol(), Period(),
                                                MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, false, PrintErrors, CalculateOnTick);

    AllowWicksIsAboveDemandZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Allow Wicks Is Above", "Allow Wicks And Is Above The Shallowest Demand Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, AllowWicksIsAboveDemandZone);

    AllowWicksIsBelowDemandZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Allow Wicks Is Below", "Allow Wicks And Is Below The Shallowest Demand Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, AllowWicksIsBelowDemandZone);

    DoNotAllowWicksIsAboveDemandZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Do not Allow Wicks Is Above", "Do Not Allow Wicks And Is Above The Shallowest Demand Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DoNotAllowWicksIsAboveDemandZone);

    DoNotAllowWicksIsBelowDemandZoneUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Do not Allow Wicks Is Below", "Do Not Allow Wicks And Is Below The Shallowest Demand Zone",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DoNotAllowWicksIsBelowDemandZone);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete AllowZoneWickBreaksMBT;
    delete DoNotAllowZoneWickBreaksMBT;

    delete AllowWicksIsAboveDemandZoneUnitTest;
    delete AllowWicksIsBelowDemandZoneUnitTest;

    delete DoNotAllowWicksIsAboveDemandZoneUnitTest;
    delete DoNotAllowWicksIsBelowDemandZoneUnitTest;
}

void OnTick()
{
    AllowZoneWickBreaksMBT.DrawNMostRecentMBs(1);
    AllowZoneWickBreaksMBT.DrawZonesForNMostRecentMBs(1);

    AllowWicksIsAboveDemandZoneUnitTest.Assert();
    AllowWicksIsBelowDemandZoneUnitTest.Assert();

    DoNotAllowWicksIsAboveDemandZoneUnitTest.Assert();
    DoNotAllowWicksIsBelowDemandZoneUnitTest.Assert();
}

int CheckSetup(bool allowWicks, bool shouldBeBelowDemandZone, double &entryPrice, double &exitPrice)
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

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ZoneState *tempZoneState;
    if (!tempMBState.GetShallowestZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool belowDemandZone = tempZoneState.BelowDemandZone(0);
    if ((shouldBeBelowDemandZone && !belowDemandZone) || (!shouldBeBelowDemandZone && belowDemandZone))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    entryPrice = tempZoneState.EntryPrice();
    exitPrice = tempZoneState.ExitPrice();

    return ERR_NO_ERROR;
}

int AllowWicksIsAboveDemandZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(true, false, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int AllowWicksIsBelowDemandZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(true, true, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int DoNotAllowWicksIsAboveDemandZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(false, false, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int DoNotAllowWicksIsBelowDemandZone(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(false, true, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}
