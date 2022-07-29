//+------------------------------------------------------------------+
//|                      CorrectStopLossForStopOrderForBreakOfMB.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/GetStopLossForStopOrderForBreakOfMB/";
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

IntUnitTest<DefaultUnitTestRecord> *InvalidMBNumberErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *NoErrorsUnitTest;

IntUnitTest<DefaultUnitTestRecord> *CorrectStopLossForBullishMBUnitTest;
IntUnitTest<DefaultUnitTestRecord> *CorrectStopLossForBearishMBUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    InvalidMBNumberErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Invalid MB Number", "Returns Error When Passing In An Invalid MB Number When Retrieving Stop Loss",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_MB_DOES_NOT_EXIST, InvalidMBNumberError);

    NoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "No Errors", "Returns No Errors When Retrieving Stop Loss",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoErrors);

    CorrectStopLossForBullishMBUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Correct Stop Loss For Bullish MB", "Returns The Correct Stop Loss For A Stop Order On The Break Of A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectStopLossForBullishMBExpected, CorrectStopLossForBullishMB);

    CorrectStopLossForBearishMBUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Correct Stop Loss For Bearish MB", "Returns The Correct Stop Loss For A Stop Order On The Break Of A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectStopLossForBearishMBExpected, CorrectStopLossForBearishMB);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete InvalidMBNumberErrorUnitTest;
    delete NoErrorsUnitTest;
    delete CorrectStopLossForBullishMBUnitTest;
    delete CorrectStopLossForBearishMBUnitTest;
}

void OnTick()
{
    InvalidMBNumberErrorUnitTest.Assert();
    NoErrorsUnitTest.Assert();

    CorrectStopLossForBullishMBUnitTest.Assert();
    CorrectStopLossForBearishMBUnitTest.Assert();
}

int InvalidMBNumberError(int &actual)
{
    int mbNumber = -1;
    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, mbNumber, MBT, stopLoss);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int NoErrors(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    return UnitTestConstants::UNIT_TEST_RAN;
}

int CorrectStopLossForBullishMBExpected()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    return MathFloor((iHigh(MBT.Symbol(), MBT.TimeFrame(), iHighest(MBT.Symbol(), MBT.TimeFrame(), MODE_HIGH, tempMBState.EndIndex(), 0)) * MathPow(10, _Digits)));
}

int CorrectStopLossForBullishMB(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    int error = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(stopLoss * MathPow(10, _Digits));
    return UnitTestConstants::UNIT_TEST_RAN;
}

int CorrectStopLossForBearishMBExpected()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    return MathFloor((iLow(MBT.Symbol(), MBT.TimeFrame(), iLowest(MBT.Symbol(), MBT.TimeFrame(), MODE_LOW, tempMBState.EndIndex(), 0)) * MathPow(10, _Digits)));
}

int CorrectStopLossForBearishMB(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    int error = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(stopLoss * MathPow(10, _Digits));
    return UnitTestConstants::UNIT_TEST_RAN;
}
