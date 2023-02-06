//+------------------------------------------------------------------+
//|                                              InvalidateSetup.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <WantaCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <WantaCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <WantaCapital\Framework\Constants\Index.mqh>

#include <WantaCapital\Framework\Trackers\MBTracker.mqh>
#include <WantaCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <WantaCapital\Framework\Helpers\SetupHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/StopTrading/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 8;
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

// https://drive.google.com/drive/folders/1BhYiTpxuG9ctbQt7bID4cHkDAV1W0ez2?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *InvalidateWhenBrokenSetupMBUnitTest;

// https://drive.google.com/drive/folders/1GCM3JSmMjDS1eHMKqSVde8lFRz6vv6O0?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest;

// https://drive.google.com/drive/folders/1n3DU9mL9u6cKgGDy9M52cUD_Qp8o4UAD?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *ClosedPendingOrderWhenInvalidatedUnitTest;

int OnInit()
{
    InvalidateWhenBrokenSetupMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Broken Setup MB", "GetLastState should return true indicating InvalidateSetup() was called",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, InvalidateWhenBrokenSetupMB);

    InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Crossed Open After", "GetLastState should return 1 of 3 possible states indicating InvalidateSetup() was called",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, InvalidateAfterCrossedOpenPriceAfterMinROC);

    ClosedPendingOrderWhenInvalidatedUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Closed Pending Order", "GetLastState should return CLOSING PENDING ORDER",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, ClosedPendingOrderWhenInvalidated);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete InvalidateWhenBrokenSetupMBUnitTest;
    delete InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest;

    delete ClosedPendingOrderWhenInvalidatedUnitTest;
}

void OnTick()
{
    InvalidateWhenBrokenSetupMBUnitTest.Assert();
    // InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest.Assert();

    // ClosedPendingOrderWhenInvalidatedUnitTest.Assert();

    if (MRFTS.HadMinROC() && TSSSMB.IsDoneTrading())
    {
        Reset();
    }

    // Run after checking tests so that I can check invalidations on the next tick
    TSSSMB.Run();
}

void Reset()
{
    delete TSSSMB;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.01);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int InvalidateWhenBrokenSetupMB(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
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

    if (!tempMBState.IsBroken(tempMBState.EndIndex()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    bool hasSetup = TSSSMB.HasSetup();

    TSSSMB.CheckInvalidateSetup();

    actual = hasSetup != TSSSMB.HasSetup() && !TSSSMB.HasSetup();
    return Results::UNIT_TEST_RAN;
}

int InvalidateAfterCrossedOpenPriceAfterMinROC(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!MBT.MBIsMostRecent(TSSSMB.FirstMBInSetupNumber()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!MRFTS.CrossedOpenPriceAfterMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    bool hasSetup = TSSSMB.HasSetup();

    TSSSMB.CheckInvalidateSetup();

    // has setup should have been reset if we called InvalidateSetup()
    actual = TSSSMB.HasSetup() != hasSetup;
    return Results::UNIT_TEST_RAN;
}

int ClosedPendingOrderWhenInvalidated(IntUnitTest<DefaultUnitTestRecord> &ut, int &actual)
{
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (TSSSMB.TicketNumber() == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetMB(TSSSMB.FirstMBInSetupNumber(), tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool invalidation = tempMBState.IsBroken(tempMBState.EndIndex()) || MRFTS.CrossedOpenPriceAfterMinROC();
    if (!invalidation)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    TSSSMB.CheckInvalidateSetup();
    actual = TSSSMB.TicketNumber() == EMPTY;

    return Results::UNIT_TEST_RAN;
}
