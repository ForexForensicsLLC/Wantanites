//+------------------------------------------------------------------+
//|                                         CheckInvalidateSetup.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/CheckStopTrading/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MinROCFromTimeStamp *MRFTS;

TheSunriseShatterSingleMB *TSSSMB;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
const int MaxSpreadPips = 70;
const double RiskPercent = 0.25;

// https://drive.google.com/drive/folders/1BRZXZ91Ud_dV72--9zaOTs45NyeLUdVK?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CheckingIfBrokeRangeStartUnitTest;

// https://drive.google.com/drive/folders/14nWNTtt5T9VkIsQvkxulGTgMUUYTR4KY?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CheckingIfBrokeRangeEndUnitTest;

// https://drive.google.com/drive/folders/1Ee30EQbrQWSnj07CVRPI0OnfVrlrUiw5?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *CheckingIfCrossingOpenPriceAfterMinROCUnitTest;

int OnInit()
{
    CheckingIfBrokeRangeStartUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broke Range Start", "Should Return true",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, CheckingIfBrokeRangeStart);

    CheckingIfBrokeRangeEndUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broke Range End", "Should Return true",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, CheckingIfBrokeRangeEnd);

    CheckingIfCrossingOpenPriceAfterMinROCUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Crossed Open Price After ROC", "Should Return CHECKING IF CROSSED OPEN PRICE AFTER MIN ROC State",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, CheckingIfCrossingOpenPriceAfterMinROC);

    Reset();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete CheckingIfBrokeRangeStartUnitTest;
    delete CheckingIfBrokeRangeEndUnitTest;

    delete CheckingIfCrossingOpenPriceAfterMinROCUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSSMB.IsDoneTrading())
    {
        Reset();
    }

    CheckingIfBrokeRangeStartUnitTest.Assert();
    // CheckingIfBrokeRangeEndUnitTest.Assert();

    CheckingIfCrossingOpenPriceAfterMinROCUnitTest.Assert();

    TSSSMB.Run();
}

void Reset()
{
    delete TSSSMB;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.01);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int CheckingIfBrokeRangeStart(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (MRFTS.CrossedOpenPriceAfterMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetMB(TSSSMB.FirstMBInSetupNumber(), tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!tempMBState.IsBroken(tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    TSSSMB.CheckStopTrading();
    actual = TSSSMB.GetLastState() == EAStates::CHECKING_IF_BROKE_RANGE_START && !TSSSMB.HasSetup();

    return Results::UNIT_TEST_RAN;
}

int CheckingIfBrokeRangeEnd(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (MRFTS.CrossedOpenPriceAfterMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetMB(TSSSMB.FirstMBInSetupNumber(), tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.IsBroken(tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (MBT.MBIsMostRecent(tempMBState.Number()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    TSSSMB.CheckStopTrading();
    actual = TSSSMB.GetLastState() == EAStates::CHECKING_IF_BROKE_RANGE_END && !TSSSMB.HasSetup();

    return Results::UNIT_TEST_RAN;
}

int CheckingIfCrossingOpenPriceAfterMinROC(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetMB(TSSSMB.FirstMBInSetupNumber(), tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.IsBroken(tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!MRFTS.CrossedOpenPriceAfterMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    TSSSMB.CheckStopTrading();
    actual = TSSSMB.GetLastState() == EAStates::CHECKING_IF_CROSSED_OPEN_PRICE_AFTER_MIN_ROC && !TSSSMB.HasSetup();

    return Results::UNIT_TEST_RAN;
}
