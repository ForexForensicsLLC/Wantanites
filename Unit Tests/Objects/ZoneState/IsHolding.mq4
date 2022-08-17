//+------------------------------------------------------------------+
//|                                                    IsHolding.mq4 |
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

const string Directory = "/UnitTests/Objects/ZoneState/IsHolding/";
const int NumberOfAsserts = 500;
const int AssertCooldown = 0;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

// https://drive.google.com/file/d/1KcLVdwZFOkE57-i9xwN77lW7UBclhdC0/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishIsHoldingUnitTest;

// https://drive.google.com/file/d/1ACt-EZ9xGZqTRcZ0ANs2zw_ZiqcaWh2s/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishIsHoldingUnitTest;

// https://drive.google.com/file/d/1pCFbEmgzohuF5tjbyn9cDFD4TKBAsXYr/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishNotHoldingUnitTest;

// https://drive.google.com/file/d/19Wa_ksUmThNs0mKcf_9j2vsJPIUKbMTB/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishNotHoldingUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    BullishIsHoldingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Is Holding", "Zone In Bullish MB Is Holding",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishIsHolding);

    BearishIsHoldingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Is Holding", "Zone In Bearish MB Is Holding",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishIsHolding);

    BullishNotHoldingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Is Not Holding", "Zone In Bullish MB Is Not Holding",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishIsNotHolding);

    BearishNotHoldingUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Is Not Holding", "Zone In Bearish MB Is Not Holding",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishIsNotHolding);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishIsHoldingUnitTest;
    delete BearishIsHoldingUnitTest;

    delete BullishNotHoldingUnitTest;
    delete BearishNotHoldingUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    // BullishIsHoldingUnitTest.Assert();
    // BearishIsHoldingUnitTest.Assert();

    BullishNotHoldingUnitTest.Assert();
    BearishNotHoldingUnitTest.Assert();
}

int CheckSetup(int type, bool zoneShouldBeHolding, int &mbEndIndex)
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

    bool zoneIsHolding = tempZoneState.IsHolding(tempZoneState.EndIndex());

    if ((zoneShouldBeHolding && !zoneIsHolding) || (!zoneShouldBeHolding && zoneIsHolding))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    mbEndIndex = tempMBState.EndIndex();

    return ERR_NO_ERROR;
}

int BullishIsHolding(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    int mbEndIndex;

    int result = CheckSetup(OP_BUY, true, mbEndIndex);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "MB End Index: " + IntegerToString(mbEndIndex);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishIsHolding(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    int mbEndIndex;

    int result = CheckSetup(OP_SELL, true, mbEndIndex);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "MB End Index: " + IntegerToString(mbEndIndex);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BullishIsNotHolding(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    int mbEndIndex;

    int result = CheckSetup(OP_BUY, false, mbEndIndex);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "MB End Index: " + IntegerToString(mbEndIndex);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}

int BearishIsNotHolding(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    int mbEndIndex;

    int result = CheckSetup(OP_SELL, false, mbEndIndex);
    if (result != ERR_NO_ERROR)
    {
        return result;
    }

    ut.PendingRecord.AdditionalInformation = "MB End Index: " + IntegerToString(mbEndIndex);
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = true;
    return Results::UNIT_TEST_RAN;
}