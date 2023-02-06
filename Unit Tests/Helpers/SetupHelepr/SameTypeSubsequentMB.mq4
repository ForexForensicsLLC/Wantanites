//+------------------------------------------------------------------+
//|                                         SameTypeSubsequentMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Constants\Index.mqh>

#include <WantaCapital\Framework\Trackers\MBTracker.mqh>

#include <WantaCapital\Framework\Helpers\SetupHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/SetupHelper/SameTypeSubsequentMB/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

BoolUnitTest<DefaultUnitTestRecord> *SameBullishTypeUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *SameBearishTypeUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *NotSameBullishTypeUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *NotSameBearishTypeUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SameBullishTypeUnitTest;
    delete SameBearishTypeUnitTest;

    delete NotSameBullishTypeUnitTest;
    delete NotSameBearishTypeUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    SameBullishTypeUnitTest.Assert();
    SameBearishTypeUnitTest.Assert();

    NotSameBullishTypeUnitTest.Assert();
    NotSameBearishTypeUnitTest.Assert();
}

int SameBullishType(BoolUnitTest<DefaultUnitTestRecord> *&ut, bool &actual)
{
    MBState *tempMBStates[];
    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBStates[1].Type() == OP_SELL || tempMBStates[0].Type() == OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    int error = SetupHelper::SameTypeSubsequentMB(tempMBStates[1].Number(), MBT, actual);
    return Results::UNIT_TEST_RAN;
}

int SameBearishType(BoolUnitTest<DefaultUnitTestRecord> *&ut, bool &actual)
{
    MBState *tempMBStates[];
    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBStates[1].Type() == OP_BUY || tempMBStates[0].Type() == OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    int error = SetupHelper::SameTypeSubsequentMB(tempMBStates[1].Number(), MBT, actual);
    return Results::UNIT_TEST_RAN;
}

int NotSameBullishType(BoolUnitTest<DefaultUnitTestRecord> *&ut, bool &actual)
{
    MBState *tempMBStates[];
    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBStates[1].Type() != OP_BUY || tempMBStates[0].Type() == OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    int error = SetupHelper::SameTypeSubsequentMB(tempMBStates[1].Number(), MBT, actual);
    return Results::UNIT_TEST_RAN;
}