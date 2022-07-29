//+------------------------------------------------------------------+
//|                 GetStopLossForStopOrderOnPendingMBValidation.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/GetStopLossForStopOrderForPendingMBValidation/";
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

IntUnitTest<DefaultUnitTestRecord> *BullishMBNoErrorsUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBNoErrorsUnitTest;

IntUnitTest<DefaultUnitTestRecord> *BullishMBEmptyRetracementUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBEmptyRetracementUnitTest;

IntUnitTest<DefaultUnitTestRecord> *BullishMBCorrectStopLossUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBCorrectStopLossUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBNoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB No Errors", "No Errors Are Returned When Getting The Stop Loss For A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BullishMBNoErrors);

    BearishMBNoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB No Errors", "No Errors Are Returned When Getting The Stop Loss For A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BearishMBNoErrors);

    BullishMBEmptyRetracementUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB Empty Reracement", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_EMPTY_BULLISH_RETRACEMENT, BullishMBEmptyRetracement);

    BearishMBEmptyRetracementUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB Empty Retracment", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_EMPTY_BEARISH_RETRACEMENT, BearishMBEmptyRetracement);

    BullishMBCorrectStopLossUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB Correct Stop Loss", "Stop Loss For Bullish MB Is Correct",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BullishMBCorrectStopLossExpected, BullishMBCorrectStopLoss);

    BearishMBCorrectStopLossUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB Correc Stop Loss", "Stop Loss For Bearish MB Is Correct",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BearishMBCorrectStopLossExpected, BearishMBCorrectStopLoss);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishMBNoErrorsUnitTest;
    delete BearishMBNoErrorsUnitTest;

    delete BullishMBEmptyRetracementUnitTest;
    delete BearishMBEmptyRetracementUnitTest;

    delete BullishMBCorrectStopLossUnitTest;
    delete BearishMBCorrectStopLossUnitTest;
}

void OnTick()
{
    BullishMBNoErrorsUnitTest.Assert();
    BearishMBNoErrorsUnitTest.Assert();

    BullishMBEmptyRetracementUnitTest.Assert();
    BearishMBEmptyRetracementUnitTest.Assert();

    BullishMBCorrectStopLossUnitTest.Assert();
    BearishMBCorrectStopLossUnitTest.Assert();
}

bool GetStopLossForStopOrderSetup(int type, bool shouldHaveRetracment)
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
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BearishMBNoErrors(int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BullishMBEmptyRetracement(int &actual)
{
    int setupType = OP_BUY;
    if (!GetStopLossForStopOrderSetup(setupType, false))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BearishMBEmptyRetracement(int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, false))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BullishMBCorrectStopLossExpected()
{
    return MathFloor((iLow(MBT.Symbol(), MBT.TimeFrame(), iLowest(MBT.Symbol(), MBT.TimeFrame(), MODE_LOW, MBT.CurrentBullishRetracementIndex(), 0))) * MathPow(10, _Digits));
}

int BullishMBCorrectStopLoss(int &actual)
{
    int setupType = OP_BUY;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    int stopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    actual = MathFloor((stopLoss * MathPow(10, _Digits)));
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BearishMBCorrectStopLossExpected()
{
    return MathFloor((iHigh(MBT.Symbol(), MBT.TimeFrame(), iHighest(MBT.Symbol(), MBT.TimeFrame(), MODE_HIGH, MBT.CurrentBearishRetracementIndex(), 0))) * MathPow(10, _Digits));
}

int BearishMBCorrectStopLoss(int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    int stopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return stopLossError;
    }

    actual = MathFloor((stopLoss * MathPow(10, _Digits)));
    return UnitTestConstants::UNIT_TEST_RAN;
}