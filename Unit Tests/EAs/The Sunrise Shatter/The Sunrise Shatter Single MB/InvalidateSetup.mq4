//+------------------------------------------------------------------+
//|                                              InvalidateSetup.mq4 |
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

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/InvalidateSetup/";
const int NumberOfAsserts = 1;
const int AssertCooldown = 1;
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

BoolUnitTest<DefaultUnitTestRecord> *InvalidateWhenNotMostRecentMBUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest;

IntUnitTest<DefaultUnitTestRecord> *ClosedPendingOrderWhenInvalidatedUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    InvalidateWhenNotMostRecentMBUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Invalidate When Not Most Recent MB", "GetLastState should return 1 of 3 possible states, indicating InvalidateSetup() was called",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, InvalidateWhenNotMostRecentMB);

    InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Invalidate After Crossed Open After Min ROC", "GetLastState should return 1 of 3 possible states, indicating InvalidateSetup() was called",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, InvalidateAfterCrossedOpenPriceAfterMinROC);

    ClosedPendingOrderWhenInvalidatedUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Closed Pending Order", "GetLastState should return CLOSING PENDING ORDER",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        EAStates::CHECKING_IF_PENDING_ORDER, ClosedPendingOrderWhenInvalidated);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete InvalidateWhenNotMostRecentMBUnitTest;
    delete InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest;

    delete ClosedPendingOrderWhenInvalidatedUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSSMB.StopTrading())
    {
        Reset();
    }

    InvalidateWhenNotMostRecentMBUnitTest.Assert();
    InvalidateAfterCrossedOpenPriceAfterMinROCUnitTest.Assert();

    ClosedPendingOrderWhenInvalidatedUnitTest.Assert();

    // Run after checking tests so that I can check invalidations on the next tick
    TSSSMB.Run();
}

void Reset()
{
    delete MRFTS;
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.05);

    delete TSSSMB;
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int InvalidateWhenNotMostRecentMB(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (MBT.MBIsMostRecent(TSSSMB.FirstMBInSetupNumber()))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    TSSSMB.CheckInvalidateSetup();
    int state = TSSSMB.GetLastState();

    // any of these mean we called InvalidateSetup()
    actual = state == EAStates::INVALIDATING_SETUP ||
             state == EAStates::CHECKING_IF_PENDING_ORDER ||
             state == EAStates::CLOSING_PENDING_ORDER;

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

    TSSSMB.CheckInvalidateSetup();
    int state = TSSSMB.GetLastState();

    // any of these mean we called InvalidateSetup()
    actual = state == EAStates::INVALIDATING_SETUP ||
             state == EAStates::CHECKING_IF_PENDING_ORDER ||
             state == EAStates::CLOSING_PENDING_ORDER;

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

    bool invalidation = !MBT.MBIsMostRecent(TSSSMB.FirstMBInSetupNumber()) || MRFTS.CrossedOpenPriceAfterMinROC();
    if (!invalidation)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    TSSSMB.CheckInvalidateSetup();
    int state = TSSSMB.GetLastState();

    actual = state == EAStates::CHECKING_IF_PENDING_ORDER ||
             state == EAStates::CLOSING_PENDING_ORDER;

    return Results::UNIT_TEST_RAN;
}
