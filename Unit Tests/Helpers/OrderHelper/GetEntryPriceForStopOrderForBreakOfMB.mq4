//+------------------------------------------------------------------+
//|                        GetEntryPriceForStopOrderForBreakOfMB.mq4 |
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

const string Directory = "/UnitTests/Helpers/OrderHelper/GetEntryPriceForStopOrderForBreakOfMB/";
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

IntUnitTest<DefaultUnitTestRecord> *CorrectEntryPriceForBullishMBUnitTest;
IntUnitTest<DefaultUnitTestRecord> *CorrectEntryPriceForBearishMBUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    InvalidMBNumberErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Invalid MB Number", "Returns Error When Passing In An Invalid MB Number When Retrieving Entry Price",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::MB_DOES_NOT_EXIST, InvalidMBNumberError);

    NoErrorsUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "No Errors", "Returns No Errors When Retrieving Entry Price",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoErrors);

    CorrectEntryPriceForBullishMBUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Correct Entry Price For Bullish MB", "Returns The Correct Entry Price For A Stop Order On The Break Of A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectEntryPriceForBullishMBExpected, CorrectEntryPriceForBullishMB);

    CorrectEntryPriceForBearishMBUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Correct Entry Price For Bearish MB", "Returns The Correct Entry Price For A Stop Order On The Break Of A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectEntryPriceForBearishMBExpected, CorrectEntryPriceForBearishMB);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete InvalidMBNumberErrorUnitTest;
    delete NoErrorsUnitTest;
    delete CorrectEntryPriceForBullishMBUnitTest;
    delete CorrectEntryPriceForBearishMBUnitTest;
}

void OnTick()
{
    InvalidMBNumberErrorUnitTest.Assert();
    NoErrorsUnitTest.Assert();

    CorrectEntryPriceForBullishMBUnitTest.Assert();
    CorrectEntryPriceForBearishMBUnitTest.Assert();
}

int InvalidMBNumberError(int &actual)
{
    int mbNumber = -1;
    double spreadPips = 0.0;
    double entryPrice = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(spreadPips, mbNumber, MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int NoErrors(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double spreadPips = 0.0;
    double entryPrice = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(spreadPips, tempMBState.Number(), MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int CorrectEntryPriceForBullishMBExpected()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    return MathFloor((iLow(MBT.Symbol(), MBT.TimeFrame(), tempMBState.LowIndex()) * MathPow(10, _Digits)));
}

int CorrectEntryPriceForBullishMB(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double spreadPips = 0.0;
    double entryPrice = 0.0;

    int error = OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(spreadPips, tempMBState.Number(), MBT, entryPrice);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(entryPrice * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}

int CorrectEntryPriceForBearishMBExpected()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    return MathFloor((iHigh(MBT.Symbol(), MBT.TimeFrame(), tempMBState.HighIndex()) * MathPow(10, _Digits)));
}

int CorrectEntryPriceForBearishMB(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double spreadPips = 0.0;
    double entryPrice = 0.0;

    int error = OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(spreadPips, tempMBState.Number(), MBT, entryPrice);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(entryPrice * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}