//+------------------------------------------------------------------+
//|                                                CheckSetSetup.mq4 |
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

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Double MB/CheckSetSetup/";
const int NumberOfAsserts = 25;
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

TheSunriseShatterDoubleMB *TSSDMB;
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
    delete TSSDMB;
    delete HasSetupUnitTest;
}

void OnTick()
{
    HasSetupUnitTest.Assert();
    TSSDMB.Run();
}

void Reset()
{
    delete TSSDMB;
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.01);
    TSSDMB = new TheSunriseShatterDoubleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int FirstMBNumber = EMPTY;
int SecondMBNumber = EMPTY;

int HasSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (MRFTS.HadMinROC() && TSSDMB.IsDoneTrading())
    {
        FirstMBNumber = EMPTY;
        SecondMBNumber = EMPTY;
        Reset();
    }

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

    if (FirstMBNumber == EMPTY)
    {
        MBState *mbOneTempState;
        if (!MBT.GetNthMostRecentMB(0, mbOneTempState))
        {
            FirstMBNumber = EMPTY;
            SecondMBNumber = EMPTY;
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
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    TSSDMB.CheckSetSetup();

    actual = FirstMBNumber == TSSDMB.FirstMBInSetupNumber() &&
             SecondMBNumber == TSSDMB.SecondMBInSetupNumber() &&
             TSSDMB.HasSetup();

    FirstMBNumber = EMPTY;
    SecondMBNumber = EMPTY;
    Reset();
    return Results::UNIT_TEST_RAN;
}
