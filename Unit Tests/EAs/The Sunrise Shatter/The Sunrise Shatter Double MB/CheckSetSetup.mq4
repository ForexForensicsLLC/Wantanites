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

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Double MB/CheckSetSetup/";
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

TheSunriseShatterDoubleMB *TSSDMB;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
input const int MaxSpreadPips = 7000;
const double RiskPercent = 0.25;

// https://drive.google.com/drive/folders/1H5WcqjljpFOH9jFifR72xJB9WkY1kzHV?usp=sharing
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
    TSSDMB.Run();
    HasSetupUnitTest.Assert();
}

void Reset()
{
    delete TSSDMB;
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.07);
    TSSDMB = new TheSunriseShatterDoubleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int HasSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static bool previousHasSetup = false;

    if (MRFTS.HadMinROC() && TSSDMB.IsDoneTrading())
    {
        Reset();
    }

    if (!previousHasSetup && TSSDMB.HasSetup())
    {
        MBState *tempMBStates[];
        if (!MBT.GetNMostRecentMBs(2, tempMBStates))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

        TSSDMB.CheckSetSetup();

        previousHasSetup = TSSDMB.HasSetup();
        actual = tempMBStates[1].Number() == TSSDMB.FirstMBInSetupNumber() &&
                 tempMBStates[0].Number() == TSSDMB.SecondMBInSetupNumber() &&
                 TSSDMB.HasSetup();

        Reset();
        return Results::UNIT_TEST_RAN;
    }

    previousHasSetup = TSSDMB.HasSetup();
    return Results::UNIT_TEST_DID_NOT_RUN;
}
