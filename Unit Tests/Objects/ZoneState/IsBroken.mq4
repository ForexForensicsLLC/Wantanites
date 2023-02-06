//+------------------------------------------------------------------+
//|                                                     IsBroken.mq4 |
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

const string Directory = "/UnitTests/Objects/ZoneState/IsBroken/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 0;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/file/d/1Lw-Imo59KvomsgNsJ8TOQMbJwW8sgeUD/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishIsBrokenUnitTest;

// https://drive.google.com/file/d/1rI8Z7xhTkfPb-MN6TASy5r2Qw0ZxUqPy/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishIsBrokenUnitTest;

// https://drive.google.com/file/d/1rhRNe07FV6vHvdJP5oh2JJjgjcO-WckL/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishNotBrokenUnitTest;

// https://drive.google.com/file/d/1Asizdo-sCHXebPweFIC_Svj8crHtO-jY/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishNotBrokenUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    BullishIsBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Is Broken", "Zone In Bullish MB Is Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishIsBroken);

    BearishIsBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Is Broken", "Zone In Bearish MB Is Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishIsBroken);

    BullishNotBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Is Not Broken", "Zone In Bullish MB Is Not Broken",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishIsNotBroken);

    BearishNotBrokenUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Is Not Broken", "Zone In Bearish MB Is Not Broken",
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

    BullishIsBrokenUnitTest.Assert();
    BearishIsBrokenUnitTest.Assert();

    BullishNotBrokenUnitTest.Assert();
    BearishNotBrokenUnitTest.Assert();
}

int CheckSetup(int type, bool zoneShouldBeBroken, double &entryPrice, double &exitPrice)
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

    ZoneState *tempZoneState;
    if (!tempMBState.GetShallowestZone(tempZoneState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool zoneIsBroken = tempZoneState.IsBroken();

    if ((zoneShouldBeBroken && !zoneIsBroken) || (!zoneShouldBeBroken && zoneIsBroken))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    entryPrice = tempZoneState.EntryPrice();
    exitPrice = tempZoneState.ExitPrice();

    return ERR_NO_ERROR;
}

int BullishIsBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(OP_BUY, true, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishIsBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(OP_SELL, true, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BullishIsNotBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(OP_BUY, false, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishIsNotBroken(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    double entryPrice;
    double exitPrice;

    int result = CheckSetup(OP_SELL, false, entryPrice, exitPrice);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "Entry Price: " + DoubleToString(entryPrice, 3) + " Exit Price: " + DoubleToString(exitPrice);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}