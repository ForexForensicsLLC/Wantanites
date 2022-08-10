//+------------------------------------------------------------------+
//|                                                     CreateMB.mq4 |
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
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/MBTracker/CreateMB/";
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

// https://drive.google.com/file/d/1NZ1iLwR5EM1Fm37b0I_BOpmE_sP87swq/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishMBImagesUnitTest;

// https://drive.google.com/file/d/1sqNgyx7YXcTB3r2cNQnxcVp6xk_lf2ey/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishMBImagesUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowZoneWickBreaks, PrintErrors, CalculateOnTick);

    BullishMBImagesUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB Images", "Images Of Bullish MBs",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishMBImages);

    BearishMBImagesUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB Images", "Images Of Bearish MBs",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishMBImages);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishMBImagesUnitTest;
    delete BearishMBImagesUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);

    BullishMBImagesUnitTest.Assert();
    BearishMBImagesUnitTest.Assert();
}

int BullishMBImages(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
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

    ut.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    newMBNumber = tempMBState.Number();

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishMBImages(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
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

    ut.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    newMBNumber = tempMBState.Number();

    actual = true;
    return Results::UNIT_TEST_RAN;
}
