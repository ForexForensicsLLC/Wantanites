//+------------------------------------------------------------------+
//|                                                CheckSetSetup.mq4 |
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

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Liquidation MB/CheckSetSetup/";
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

BoolUnitTest<DefaultUnitTestRecord> *HasSetupUnitTest;

int OnInit()
{
    HasSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Setup", "Should return true indicating there is a setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasSetup);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TSSLMB;
    delete HasSetupUnitTest;
}

void OnTick()
{
    HasSetupUnitTest.Assert();
    TSSLMB.Run();
}

void Reset()
{
    delete TSSLMB;
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.01);
    TSSLMB = new TheSunriseShatterLiquidationMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int FirstMBNumber = EMPTY;
int SecondMBNumber = EMPTY;
int SetupType = EMPTY;

int HasSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (MRFTS.HadMinROC() && TSSLMB.IsDoneTrading())
    {
        FirstMBNumber = EMPTY;
        SecondMBNumber = EMPTY;
        SetupType = EMPTY;
        Reset();
    }

    if (FirstMBNumber == EMPTY)
    {
        bool isTrue = false;
        int setupError = SetupHelper::BreakAfterMinROC(MRFTS, MBT, isTrue);
        if (TerminalErrors::IsTerminalError(setupError))
        {
            return setupError;
        }

        if (!isTrue)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        MBState *mbOneTempState;
        if (!MBT.GetNthMostRecentMB(0, mbOneTempState))
        {
            FirstMBNumber = EMPTY;
            SecondMBNumber = EMPTY;
            SetupType = EMPTY;

            Reset();
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        FirstMBNumber = mbOneTempState.Number();
    }
    else if (SecondMBNumber == EMPTY)
    {
        MBState *mbTwoTempState;
        if (!MBT.GetSubsequentMB(FirstMBNumber, mbTwoTempState))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        SecondMBNumber = mbTwoTempState.Number();
        SetupType = mbTwoTempState.Type();
    }

    MBState *mbThreeTempState;
    if (!MBT.GetSubsequentMB(SecondMBNumber, mbThreeTempState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (mbThreeTempState.Type() == SetupType)
    {
        FirstMBNumber = EMPTY;
        SecondMBNumber = EMPTY;
        SetupType = EMPTY;

        Reset();
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Most Recent MB: " + tempMBState.Number() +
                                             " Setup Type: " + TSSLMB.SetupType() +
                                             " First MB In Setup: " + TSSLMB.FirstMBInSetupNumber() +
                                             " Second MB In Setup: " + TSSLMB.SecondMBInSetupNumber();

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    TSSLMB.CheckSetSetup();

    actual = FirstMBNumber == TSSLMB.FirstMBInSetupNumber() &&
             SecondMBNumber == TSSLMB.SecondMBInSetupNumber() &&
             TSSLMB.HasSetup();

    FirstMBNumber = EMPTY;
    SecondMBNumber = EMPTY;
    SetupType = EMPTY;

    Reset();
    return Results::UNIT_TEST_RAN;
}