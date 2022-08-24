//+------------------------------------------------------------------+
//|                                                          Run.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB - Copy.mqh>

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Double MB/Run/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 0;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MinROCFromTimeStamp *MRFTS;

TheSunriseShatterDoubleMBC *TSSDMBC;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
input const int MaxSpreadPips = 70;
const double RiskPercent = 0.25;

// https://drive.google.com/drive/folders/1UgVUrG5oLCaaYtm7Kcjz_ir-eKebaQ3l?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasSetupChangedUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    HasSetupChangedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Setup Changed", "Should take an image whenever HasSetup() has changed",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, HasSetupChanged);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TSSDMBC;
    delete HasSetupChangedUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSDMBC.mStopTrading)
    {
        Reset();
    }

    TSSDMBC.Run();
    HasSetupChangedUnitTest.Assert();
}

void Reset()
{
    delete TSSDMBC;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.17);
    TSSDMBC = new TheSunriseShatterDoubleMBC(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int HasSetupChanged(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static bool hasSetupLastCheck = TSSDMBC.mHasSetup;

    if (hasSetupLastCheck == TSSDMBC.mHasSetup)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "Previous Has Setup: " + hasSetupLastCheck + " Current Has Setup: " + TSSDMBC.mHasSetup;

    hasSetupLastCheck = TSSDMBC.mHasSetup;
    actual = true;
    return Results::UNIT_TEST_RAN;
}
