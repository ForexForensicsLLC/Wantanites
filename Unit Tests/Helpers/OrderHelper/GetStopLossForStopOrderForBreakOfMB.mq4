//+------------------------------------------------------------------+
//|                      CorrectStopLossForStopOrderForBreakOfMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\Framework\Helpers\OrderHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/GetStopLossForStopOrderForBreakOfMB/";
const int NumberOfAsserts = 50;
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

// https://drive.google.com/file/d/1u5eDVCXiMmwZQyQkRVXwbWE1zM_wZhWp/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *InvalidMBNumberErrorUnitTest;

// https://drive.google.com/file/d/1h2babp8qvA6DNGdQl3Pqjyum58xb0bMA/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *NoErrorsUnitTest;

// https://drive.google.com/file/d/1N52VkkrfTBJYHYMhLBBvmKf-u-VPlKe7/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectStopLossForBullishMBUnitTest;

// https://drive.google.com/file/d/19730FDMUVd_FmD7uW0PrJ04xIr1B1Hld/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectStopLossForBearishMBUnitTest;

// https://drive.google.com/file/d/1wH8FybvHPiFS2ofVb5bJXv808ConnFio/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectWithSpreadAndPaddingForBullishUnitTest;

// https://drive.google.com/file/d/1e94TJS7ZOanV9Fviho9QoaEymqfkTXdm/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectWithSpreadAndPaddingForBearishUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    InvalidMBNumberErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Invalid MB Number", "Returns Error When Passing In An Invalid MB Number When Retrieving Stop Loss",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::MB_DOES_NOT_EXIST, InvalidMBNumberError);

    NoErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "No Errors", "Returns No Errors When Retrieving Stop Loss",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoErrors);

    CorrectStopLossForBullishMBUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct Stop Loss For Bullish MB", "Returns The Correct Stop Loss For A Stop Order On The Break Of A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectStopLossForBullishMBExpected, CorrectStopLossForBullishMB);

    CorrectStopLossForBearishMBUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct Stop Loss For Bearish MB", "Returns The Correct Stop Loss For A Stop Order On The Break Of A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectStopLossForBearishMBExpected, CorrectStopLossForBearishMB);

    CorrectWithSpreadAndPaddingForBullishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct With S And P Bullish", "Returns The Correct Stop Loss For A Stop Order On The Break Of A Bullish MB With 10 Pips Of Spread And Padding",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectWithSpreadAndPaddingForBullishExpected, CorrectWithSpreadAndPaddingForBullish);

    CorrectWithSpreadAndPaddingForBearishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct With S And P Bearish", "Returns The Correct Stop Loss For A Stop Order On The Break Of A Bearish MB With 10 Pips Of Spread And Padding",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectWithSpreadAndPaddingForBearishExpected, CorrectWithSpreadAndPaddingForBearish);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete InvalidMBNumberErrorUnitTest;
    delete NoErrorsUnitTest;

    delete CorrectStopLossForBullishMBUnitTest;
    delete CorrectStopLossForBearishMBUnitTest;

    delete CorrectWithSpreadAndPaddingForBullishUnitTest;
    delete CorrectWithSpreadAndPaddingForBearishUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    /*
    InvalidMBNumberErrorUnitTest.Assert();
    NoErrorsUnitTest.Assert();

    CorrectStopLossForBullishMBUnitTest.Assert();
    CorrectStopLossForBearishMBUnitTest.Assert();
    */

    CorrectWithSpreadAndPaddingForBullishUnitTest.Assert();
    CorrectWithSpreadAndPaddingForBearishUnitTest.Assert();
}

int InvalidMBNumberError(int &actual)
{
    int mbNumber = -1;
    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, mbNumber, MBT, stopLoss);
    return Results::UNIT_TEST_RAN;
}

int NoErrors(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    return Results::UNIT_TEST_RAN;
}

int CorrectStopLossForBullishMBExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    double high;
    if (!MQLHelper::GetHighestHigh(MBT.Symbol(), MBT.TimeFrame(), tempMBState.EndIndex(), 0, true, high))
    {
        return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
    }

    return MathFloor((high * MathPow(10, _Digits)));
}

int CorrectStopLossForBullishMB(int &actual)
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

    double paddingPips = 0.0;
    double spreadPips = 0.0;
    double stopLoss = 0.0;

    int error = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(stopLoss * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}

int CorrectStopLossForBearishMBExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
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
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
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
    return Results::UNIT_TEST_RAN;
}

int CorrectWithSpreadAndPaddingForBullishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    double high;
    if (!MQLHelper::GetHighestHigh(MBT.Symbol(), MBT.TimeFrame(), tempMBState.EndIndex(), 0, true, high))
    {
        return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
    }

    return MathFloor(((high + OrderHelper::PipsToRange(10) + OrderHelper::PipsToRange(10)) * MathPow(10, _Digits)));
}

int CorrectWithSpreadAndPaddingForBullish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
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

    double high;
    if (!MQLHelper::GetHighestHigh(MBT.Symbol(), MBT.TimeFrame(), tempMBState.EndIndex(), 0, true, high))
    {
        return ExecutionErrors::COULD_NOT_RETRIEVE_HIGH;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "High Without Spread and Padding: " + DoubleToString(high, 6);
    ut.PendingRecord.AdditionalInformation += MBT.ToSingleLineString();

    double paddingPips = 10;
    double spreadPips = 10;
    double stopLoss = 0.0;

    int error = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(stopLoss * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}

int CorrectWithSpreadAndPaddingForBearishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    double low = 0.0;
    if (!MQLHelper::GetLowestLow(MBT.Symbol(), MBT.TimeFrame(), tempMBState.EndIndex(), 0, true, low))
    {
        return ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
    }

    return MathFloor(((low - OrderHelper::PipsToRange(10)) * MathPow(10, _Digits)));
}

int CorrectWithSpreadAndPaddingForBearish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
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

    double low = 0.0;
    if (!MQLHelper::GetLowestLow(MBT.Symbol(), MBT.TimeFrame(), tempMBState.EndIndex(), 0, true, low))
    {
        return ExecutionErrors::COULD_NOT_RETRIEVE_LOW;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "Low Without Spread and Padding: " + DoubleToString(low, 6);
    ut.PendingRecord.AdditionalInformation += MBT.ToSingleLineString();

    double paddingPips = 10;
    double spreadPips = 10;
    double stopLoss = 0.0;

    int error = OrderHelper::GetStopLossForStopOrderForBreakOfMB(paddingPips, spreadPips, tempMBState.Number(), MBT, stopLoss);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(stopLoss * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}