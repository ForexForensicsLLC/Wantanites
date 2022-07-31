//+------------------------------------------------------------------+
//|                                    GetEntryPriceForStopOrder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/GetEntryPriceForStopOrderForPendingMBValidation/";
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

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BullishMBNoErrorsUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BearishMBNoErrorsUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BullishMBEmptyRetracementUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BearishMBEmptyRetracementUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BullishMBCorrectEntryPriceUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *BearishMBCorrectEntryPriceUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBNoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB No Errors", "No Errors Are Returned When Getting The Entry Price For A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BullishMBNoErrors);

    BearishMBNoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB No Errors", "No Errors Are Returned When Getting The Entry Price For A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BearishMBNoErrors);

    BullishMBEmptyRetracementUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB Empty Reracement", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::EMPTY_BULLISH_RETRACEMENT, BullishMBEmptyRetracement);

    BearishMBEmptyRetracementUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB Empty Retracment", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::EMPTY_BEARISH_RETRACEMENT, BearishMBEmptyRetracement);

    BullishMBCorrectEntryPriceUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB Correct Entry Price", "Entry Price For Bullish MB Is Correc",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BullishMBCorrectEntryPriceExpected, BullishMBCorrectEntryPrice);

    BearishMBCorrectEntryPriceUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB Correct Entry Price", "Entry Price For Bearish MB Is Correct",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BearishMBCorrectEntryPriceExpected, BearishMBCorrectEntryPrice);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishMBNoErrorsUnitTest;
    delete BearishMBNoErrorsUnitTest;

    delete BullishMBEmptyRetracementUnitTest;
    delete BearishMBEmptyRetracementUnitTest;

    delete BullishMBCorrectEntryPriceUnitTest;
    delete BearishMBCorrectEntryPriceUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishMBNoErrorsUnitTest.Assert();
    BearishMBNoErrorsUnitTest.Assert();

    BullishMBEmptyRetracementUnitTest.Assert();
    BearishMBEmptyRetracementUnitTest.Assert();

    BullishMBCorrectEntryPriceUnitTest.Assert();
    BearishMBCorrectEntryPriceUnitTest.Assert();
}

bool GetEntryPriceForStopOrderSetup(int type, bool shouldHaveRetracment)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return false;
    }

    if (tempMBState.Type() != type)
    {
        return false;
    }

    if (type == OP_BUY)
    {
        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if ((shouldHaveRetracment && retracementIndex == EMPTY) || (!shouldHaveRetracment && retracementIndex != EMPTY))
        {
            return false;
        }
    }
    else if (type == OP_SELL)
    {
        int retracementIndex = MBT.CurrentBearishRetracementIndex();
        if ((shouldHaveRetracment && retracementIndex == EMPTY) || (!shouldHaveRetracment && retracementIndex != EMPTY))
        {
            return false;
        }
    }

    return true;
}

int BullishMBNoErrors(int &actual)
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int BearishMBNoErrors(int &actual)
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int BullishMBEmptyRetracement(int &actual)
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, false))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int BearishMBEmptyRetracement(int &actual)
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, false))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int BullishMBCorrectEntryPriceExpected()
{
    return MathFloor((iHigh(Symbol(), Period(), MBT.CurrentBullishRetracementIndex()) * MathPow(10, _Digits)));
}

int BullishMBCorrectEntryPrice(int &actual)
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    int entryPriceError = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    actual = MathFloor((entryPrice * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}

int BearishMBCorrectEntryPriceExpected()
{
    return MathFloor((iLow(Symbol(), Period(), MBT.CurrentBearishRetracementIndex()) * MathPow(10, _Digits)));
}

int BearishMBCorrectEntryPrice(int &actual)
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    int entryPriceError = OrderHelper::GetEntryPriceForStopOrderOnMostRecentPendingMB(spreadPips, setupType, MBT, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    actual = MathFloor((entryPrice * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}
