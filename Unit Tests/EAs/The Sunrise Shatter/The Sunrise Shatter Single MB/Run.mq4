//+------------------------------------------------------------------+
//|                                                          Run.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/Run/";
const int NumberOfAsserts = 250;
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

TheSunriseShatterSingleMB *TSSSMB;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
input const int MaxSpreadPips = 7000;
const double RiskPercent = 0.25;

// https://drive.google.com/drive/folders/1XGWnYCxvr1doXz0Pvtsqhcy1xGeT_LqI?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *HasSetupChangedUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *NewMBDuringSetupUnitTest;

int OnInit()
{
    HasSetupChangedUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Has Setup Changed", "Should take an image whenever HasSetup() has changed",
        75, AssertCooldown, RecordErrors,
        true, HasSetupChanged);

    NewMBDuringSetupUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "New MB During Setup", "Should take an image whenever there is a new mb during a setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, NewMBDuringSetup);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TSSSMB;

    delete HasSetupChangedUnitTest;
    delete NewMBDuringSetupUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSSMB.IsDoneTrading())
    {
        Reset();
    }

    TSSSMB.Run();

    HasSetupChangedUnitTest.Assert();

    // this basically does the exact same thing as the first test but not as well
    // NewMBDuringSetupUnitTest.Assert();
}

void Reset()
{
    delete TSSSMB;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.17);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int HasSetupChanged(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static bool hasSetupLastCheck = TSSSMB.HasSetup();

    if (hasSetupLastCheck == TSSSMB.HasSetup())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "Previous Has Setup: " + hasSetupLastCheck + " Current Has Setup: " + TSSSMB.HasSetup();

    hasSetupLastCheck = TSSSMB.HasSetup();
    actual = true;
    return Results::UNIT_TEST_RAN;
}

int NewMBDuringSetup(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int currentMBNumber = EMPTY;
    static int hasSetupLastCheck = false;

    if (!hasSetupLastCheck && !TSSSMB.HasSetup())
    {
        currentMBNumber = EMPTY;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (currentMBNumber == EMPTY)
    {
        currentMBNumber = tempMBState.Number();

        ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
        ut.PendingRecord.AdditionalInformation = "Has Setup: " + TSSSMB.HasSetup() + " Stop Trading: " + TSSSMB.IsDoneTrading();

        actual = true;
        return Results::UNIT_TEST_RAN;
    }

    if (currentMBNumber == tempMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    currentMBNumber = tempMBState.Number();

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "Has Setup: " + TSSSMB.HasSetup() + " Stop Trading: " + TSSSMB.IsDoneTrading();

    actual = true;
    hasSetupLastCheck = TSSSMB.HasSetup();

    return Results::UNIT_TEST_RAN;
}
