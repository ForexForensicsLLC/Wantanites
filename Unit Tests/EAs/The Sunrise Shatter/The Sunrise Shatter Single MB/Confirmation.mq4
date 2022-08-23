//+------------------------------------------------------------------+
//|                                                 Confirmation.mq4 |
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

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/Confirmation/";
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

// https://drive.google.com/drive/folders/1QqwK4jQiOkDlcJNuOdSPIwCw1ekbfrdt?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *HasConfirmationUnitTest;

int OnInit()
{
    HasConfirmationUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Has Confirmation", "Should Return True Indication There Is Confirmation",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasConfirmation);

    Reset();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete HasConfirmationUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSSMB.IsDoneTrading())
    {
        Reset();
    }

    TSSSMB.Run();
    HasConfirmationUnitTest.Assert();
}

void Reset()
{
    delete TSSSMB;
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.01);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int HasConfirmation(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    if (!TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    bool isTrue = false;
    int confirmationError = SetupHelper::MostRecentMBPlusHoldingZone(TSSSMB.FirstMBInSetupNumber(), MBT, isTrue);
    if (confirmationError == ExecutionErrors::MB_IS_NOT_MOST_RECENT)
    {
        return confirmationError;
    }

    if (!isTrue)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetMB(TSSSMB.FirstMBInSetupNumber(), tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = tempMBState.ToSingleLineString();
    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), "_" + IntegerToString(count));

    actual = TSSSMB.Confirmation();
    count += 1;

    return Results::UNIT_TEST_RAN;
}