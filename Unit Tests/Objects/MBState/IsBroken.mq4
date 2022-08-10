//+------------------------------------------------------------------+
//|                                                     IsBroken.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Objects/MBState/IsBroken/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 1;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/file/d/1C2rdgQMMYm2p8-cd6NbLYCIwsBCtewRI/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishIsBrokenUnitTest;

// https://drive.google.com/file/d/1ysm0aiLUrs6329vDw3pgMuZq8zf3GWvt/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishIsBrokenUnitTest;

// https://drive.google.com/file/d/1lRJwv3jpQgfzrjgt-TbzDEF-xQLUSK0Y/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishNotBrokenUnitTest;

// https://drive.google.com/file/d/1tdwA-zyBi0oJCqCQfgQzigfLtaorDPbN/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishNotBrokenUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    BullishIsBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Is Broken", "Bullish MB Is Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishIsBroken);

    BearishIsBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Is Broken", "Bearish MB Is Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishIsBroken);

    BullishNotBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Is Not Broken", "Bullish MB Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishIsNotBroken);

    BearishNotBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Is Not Broken", "Bearish MB Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishIsNotBroken);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishIsBrokenUnitTest;
    delete BearishIsBrokenUnitTest;

    delete BullishNotBrokenUnitTest;
    delete BearishNotBrokenUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    // BullishIsBrokenUnitTest.Assert();
    BearishIsBrokenUnitTest.Assert();

    /*
    BullishNotBrokenUnitTest.Assert();
    BearishNotBrokenUnitTest.Assert();
    */
}

int CheckSetup(int type, bool mbShouldBeBroken)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != type)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool mbIsBroken = tempMBState.IsBroken(tempMBState.EndIndex());

    if ((mbShouldBeBroken && !mbIsBroken) || (!mbShouldBeBroken && mbIsBroken))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    return ERR_NO_ERROR;
}

int CheckIsBroken(int type, int &mbNumber)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (mbNumber == EMPTY)
    {
        if (tempMBState.Type() != type)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();
    }

    if (mbNumber == tempMBState.Number())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStateTwo;
    if (!MBT.GetMB(mbNumber, tempMBStateTwo))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (!tempMBStateTwo.IsBroken(tempMBStateTwo.EndIndex()))
    {
        mbNumber = EMPTY;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    mbNumber = EMPTY;
    return ERR_NO_ERROR;
}

int BullishIsBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int mbNumber = EMPTY;

    int result = CheckIsBroken(OP_BUY, mbNumber);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishIsBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int mbNumber = EMPTY;

    int result = CheckIsBroken(OP_SELL, mbNumber);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BullishIsNotBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    int result = CheckSetup(OP_BUY, false);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishIsNotBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    int result = CheckSetup(OP_SELL, false);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = MBT.ToSingleLineString();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}
