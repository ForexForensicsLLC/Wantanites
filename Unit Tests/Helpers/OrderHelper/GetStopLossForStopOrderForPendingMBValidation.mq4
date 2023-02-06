//+------------------------------------------------------------------+
//|                 GetStopLossForStopOrderOnPendingMBValidation.mq4 |
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

const string Directory = "/UnitTests/Helpers/OrderHelper/GetStopLossForStopOrderForPendingMBValidation/";
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

// https://drive.google.com/file/d/1vyxlPmL8hkSuZmvTEDBj5k8tAnPDPGcR/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBNoErrorsUnitTest;

// https://drive.google.com/file/d/1g6zsWMFZXowlyMyMEx5BLFUaL1w4Cu6k/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBNoErrorsUnitTest;

// https://drive.google.com/file/d/1V_3iVrxY8ajdt4a7h96tdc7vssm6u9rH/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBEmptyRetracementUnitTest;

// https://drive.google.com/file/d/1N8j1ay56uzDDRRORul3uyVKKPP7oWd1X/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBEmptyRetracementUnitTest;

// https://drive.google.com/file/d/1VhYpWwVkNJRpZbTd0SdXhYdkeoKTGrtm/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBCorrectStopLossUnitTest;

// https://drive.google.com/file/d/1Tl1whOIvDyNklbIAiWPvUTxb4Z0cUaQy/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBCorrectStopLossUnitTest;

// https://drive.google.com/file/d/1QF7DONsDLbL80YZVWSJ5uv1uHJ9L2xCC/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectWithPaddingAndSpreadBullishUnitTest;

// https://drive.google.com/file/d/1xR5Hn7fS_M3_h01PXj0tAVn55-KWKsWw/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectWithPaddingAndSpreadBearishUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBNoErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB No Errors", "No Errors Are Returned When Getting The Stop Loss For A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BullishMBNoErrors);

    BearishMBNoErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB No Errors", "No Errors Are Returned When Getting The Stop Loss For A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BearishMBNoErrors);

    BullishMBEmptyRetracementUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB Empty Retracement", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID, BullishMBEmptyRetracement);

    BearishMBEmptyRetracementUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB Empty Retracment", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::BEARISH_RETRACEMENT_IS_NOT_VALID, BearishMBEmptyRetracement);

    BullishMBCorrectStopLossUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB Correct Stop Loss", "Stop Loss For Bullish MB Is Correct",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BullishMBCorrectStopLossExpected, BullishMBCorrectStopLoss);

    BearishMBCorrectStopLossUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB Correct Stop Loss", "Stop Loss For Bearish MB Is Correct",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BearishMBCorrectStopLossExpected, BearishMBCorrectStopLoss);

    CorrectWithPaddingAndSpreadBullishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct With S And P Bullish", "Correct With 10 Pips Of Padding And Spread",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectWithSpreadAndPaddingBullishExpected, CorrectWithSpreadAndPaddingBullish);

    CorrectWithPaddingAndSpreadBearishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct With S And P Bearish", "Correct With 10 Pips Of Padding And Spread",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectWithPaddingAndSpreadBearishExpected, CorrectWithPaddingAndSpreadBearish);

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

    delete CorrectWithPaddingAndSpreadBullishUnitTest;
    delete CorrectWithPaddingAndSpreadBearishUnitTest;
}

void OnTick()
{
    /*
    BullishMBNoErrorsUnitTest.Assert();
    BearishMBNoErrorsUnitTest.Assert();

    BullishMBEmptyRetracementUnitTest.Assert();
    BearishMBEmptyRetracementUnitTest.Assert();

    BullishMBCorrectStopLossUnitTest.Assert();
    BearishMBCorrectStopLossUnitTest.Assert();
    */

    CorrectWithPaddingAndSpreadBullishUnitTest.Assert();
    CorrectWithPaddingAndSpreadBearishUnitTest.Assert();
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
        int retracementIndex = EMPTY;
        if (!MBT.CurrentBullishRetracementIndexIsValid(retracementIndex))
        {
            return ExecutionErrors::BEARISH_RETRACEMENT_IS_NOT_VALID;
        }

        if ((shouldHaveRetracment && retracementIndex == EMPTY) || (!shouldHaveRetracment && retracementIndex != EMPTY))
        {
            return false;
        }
    }
    else if (type == OP_SELL)
    {
        int retracementIndex = EMPTY;
        if (!MBT.CurrentBearishRetracementIndexIsValid(retracementIndex))
        {
            return ExecutionErrors::BEARISH_RETRACEMENT_IS_NOT_VALID;
        }

        if ((shouldHaveRetracment && retracementIndex == EMPTY) || (!shouldHaveRetracment && retracementIndex != EMPTY))
        {
            return false;
        }
    }

    return true;
}

int CurrentBullishRetracementIndex()
{
    int index;
    if (!MBT.CurrentBullishRetracementIndexIsValid(index))
    {
        return 1;
    }

    return index;
}

int CurrentBearishRetracementIndex()
{
    int index;
    if (!MBT.CurrentBearishRetracementIndexIsValid(index))
    {
        return 1;
    }

    return index;
}

int BullishMBNoErrors(int &actual)
{
    int setupType = OP_BUY;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return Results::UNIT_TEST_RAN;
}

int BearishMBNoErrors(int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return Results::UNIT_TEST_RAN;
}

int BullishMBEmptyRetracement(int &actual)
{
    int setupType = OP_BUY;
    if (!GetStopLossForStopOrderSetup(setupType, false))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return Results::UNIT_TEST_RAN;
}

int BearishMBEmptyRetracement(int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, false))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double stopLoss = 0.0;
    double spreadPips = 0.0;
    double paddingPips = 0.0;

    actual = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    return Results::UNIT_TEST_RAN;
}

int BullishMBCorrectStopLossExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    return MathFloor((iLow(MBT.Symbol(), MBT.TimeFrame(), iLowest(MBT.Symbol(), MBT.TimeFrame(), MODE_LOW, CurrentBullishRetracementIndex(), 0))) * MathPow(10, _Digits));
}

int BullishMBCorrectStopLoss(int &actual)
{
    int setupType = OP_BUY;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
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
    return Results::UNIT_TEST_RAN;
}

int BearishMBCorrectStopLossExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    return MathFloor((iHigh(MBT.Symbol(), MBT.TimeFrame(), iHighest(MBT.Symbol(), MBT.TimeFrame(), MODE_HIGH, CurrentBearishRetracementIndex(), 0))) * MathPow(10, _Digits));
}

int BearishMBCorrectStopLoss(int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
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
    return Results::UNIT_TEST_RAN;
}

int CorrectWithSpreadAndPaddingBullishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    double low = 0.0;
    if (!MQLHelper::GetLowestLow(MBT.Symbol(), MBT.TimeFrame(), CurrentBullishRetracementIndex(), 0, false, low))
    {
        return EMPTY;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());
    return MathFloor((low - OrderHelper::PipsToRange(10)) * MathPow(10, _Digits));
}

int CorrectWithSpreadAndPaddingBullish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    int setupType = OP_BUY;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int retracementIndex = EMPTY;
    if (!MBT.CurrentBullishRetracementIndexIsValid(retracementIndex))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double low = 0.0;
    if (!MQLHelper::GetLowestLow(MBT.Symbol(), MBT.TimeFrame(), retracementIndex, 0, false, low))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "Low Without Spread and Padding: " + DoubleToString(low, 6);
    ut.PendingRecord.AdditionalInformation += MBT.ToSingleLineString();

    double stopLoss = 0.0;
    double spreadPips = 10.0;
    double paddingPips = 10.0;

    int stopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = MathFloor((stopLoss * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}

int CorrectWithPaddingAndSpreadBearishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    double high = 0.0;
    if (!MQLHelper::GetHighestHigh(MBT.Symbol(), MBT.TimeFrame(), CurrentBearishRetracementIndex(), 0, false, high))
    {
        return EMPTY;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return MathFloor((high + OrderHelper::PipsToRange(10) + OrderHelper::PipsToRange(10)) * MathPow(10, _Digits));
}

int CorrectWithPaddingAndSpreadBearish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    int setupType = OP_SELL;
    if (!GetStopLossForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int retracementIndex = EMPTY;
    if (!MBT.CurrentBearishRetracementIndexIsValid(retracementIndex))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double high = 0.0;
    if (!MQLHelper::GetHighestHigh(MBT.Symbol(), MBT.TimeFrame(), retracementIndex, 0, false, high))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());
    ut.PendingRecord.AdditionalInformation = "High Without Spread and Padding: " + DoubleToString(high, 6);
    ut.PendingRecord.AdditionalInformation += MBT.ToSingleLineString();

    double stopLoss = 0.0;
    double spreadPips = 10.0;
    double paddingPips = 10.0;

    int stopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(paddingPips, spreadPips, setupType, MBT, stopLoss);
    if (stopLossError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = MathFloor((stopLoss * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}