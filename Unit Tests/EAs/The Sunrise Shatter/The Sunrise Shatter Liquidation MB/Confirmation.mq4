//+------------------------------------------------------------------+
//|                                                 Confirmation.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Trackers\MBTracker.mqh>
#include <Wantanites\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Liquidation MB/Confirmation/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MinROCFromTimeStamp *MRFTS;

TheSunriseShatterLiquidationMB *TSSLMB;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
const int MaxSpreadPips = 70;
const double RiskPercent = 0.25;

BoolUnitTest<DefaultUnitTestRecord> *HasConfirmationUnitTest;

int OnInit()
{
    HasConfirmationUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Confirmation", "Should Return True, Indication There Is Confirmation",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasConfirmation);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSLMB;

    delete HasConfirmationUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSLMB.IsDoneTrading())
    {
        Reset();
    }

    TSSLMB.Run();

    HasConfirmationUnitTest.Assert();
}

void Reset()
{
    delete TSSLMB;
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.01);
    TSSLMB = new TheSunriseShatterLiquidationMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int HasConfirmation(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (!TSSLMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool hasConfirmation = false;
    int confirmationError = SetupHelper::FirstMBAfterLiquidationOfSecondPlusHoldingZone(TSSLMB.FirstMBInSetupNumber(), TSSLMB.SecondMBInSetupNumber(), MBT, hasConfirmation);
    if (TerminalErrors::IsTerminalError(confirmationError) || !hasConfirmation)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = TSSLMB.Confirmation();
    return Results::UNIT_TEST_RAN;
}
