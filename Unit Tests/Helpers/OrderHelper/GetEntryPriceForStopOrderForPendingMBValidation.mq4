//+------------------------------------------------------------------+
//|                                    GetEntryPriceForStopOrder.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/GetEntryPriceForStopOrderForPendingMBValidation/";
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

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBNoErrorsUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBNoErrorsUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBEmptyRetracementUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBEmptyRetracementUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishMBCorrectEntryPriceUnitTest;

// https://drive.google.com/file/d/1f4tCRZjZJOmeSJ9bPFIiPlaVtVu2JCFt/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishMBCorrectEntryPriceUnitTest;

// https://drive.google.com/file/d/1Qte7jtEYX7tz8BlGycogA77s1CEo5YkJ/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectWithSpreadBullishUnitTest;

// https://drive.google.com/file/d/1dMIDM2EbzwpcerFLidb7KQwVmkopt_W1/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectWithSpreadBearishUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBNoErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB No Errors", "No Errors Are Returned When Getting The Entry Price For A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BullishMBNoErrors);

    BearishMBNoErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB No Errors", "No Errors Are Returned When Getting The Entry Price For A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BearishMBNoErrors);

    BullishMBEmptyRetracementUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB Empty Reracement", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::BULLISH_RETRACEMENT_IS_NOT_VALID, BullishMBEmptyRetracement);

    BearishMBEmptyRetracementUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB Empty Retracment", "Should Return Empty Retracement Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ExecutionErrors::BEARISH_RETRACEMENT_IS_NOT_VALID, BearishMBEmptyRetracement);

    BullishMBCorrectEntryPriceUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish MB Correct Entry Price", "Entry Price For Bullish MB Is Correc",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BullishMBCorrectEntryPriceExpected, BullishMBCorrectEntryPrice);

    BearishMBCorrectEntryPriceUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish MB Correct Entry Price", "Entry Price For Bearish MB Is Correct",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        BearishMBCorrectEntryPriceExpected, BearishMBCorrectEntryPrice);

    CorrectWithSpreadBullishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct With Spread Bullish", "Entry Price For Bullish MB Is Correct with 10 Pips Of Spread",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectWithSpreadBullishExpected, CorrectWithSpreadBullish);

    CorrectWithSpreadBearishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct With Spread Bearish", "Entry Price For Bearish MB Is Correct with 10 Pips Of Spread",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectWithSpreadBearishExpected, CorrectWithSpreadBearish);

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

    delete CorrectWithSpreadBullishUnitTest;
    delete CorrectWithSpreadBearishUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    /*
    BullishMBNoErrorsUnitTest.Assert();
    BearishMBNoErrorsUnitTest.Assert();

    BullishMBEmptyRetracementUnitTest.Assert();
    BearishMBEmptyRetracementUnitTest.Assert();

    BullishMBCorrectEntryPriceUnitTest.Assert();
    BearishMBCorrectEntryPriceUnitTest.Assert();
    */

    CorrectWithSpreadBullishUnitTest.Assert();
    CorrectWithSpreadBearishUnitTest.Assert();
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

int BullishMBNoErrors(int &actual)
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double entryPrice = 0.0;
    double spreadPips = 0.0;

    actual = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
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

    actual = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
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

    actual = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
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

    actual = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
    return Results::UNIT_TEST_RAN;
}

int BullishMBCorrectEntryPriceExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    return MathFloor((iHigh(Symbol(), Period(), CurrentBullishRetracementIndex()) * MathPow(10, _Digits)));
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

    int entryPriceError = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    actual = MathFloor((entryPrice * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}

int BearishMBCorrectEntryPriceExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    return MathFloor((iLow(Symbol(), Period(), CurrentBearishRetracementIndex()) * MathPow(10, _Digits)));
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

    int entryPriceError = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return entryPriceError;
    }

    actual = MathFloor((entryPrice * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}

int CorrectWithSpreadBullishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return MathFloor(((iHigh(Symbol(), Period(), CurrentBullishRetracementIndex()) + OrderHelper::PipsToRange(10)) * MathPow(10, _Digits)));
}

int CorrectWithSpreadBullish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    int setupType = OP_BUY;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    double high = iHigh(MBT.Symbol(), MBT.TimeFrame(), CurrentBullishRetracementIndex());
    ut.PendingRecord.AdditionalInformation = "Entry High Without Spread and Padding: " + DoubleToString(high);

    double entryPrice = 0.0;
    double spreadPips = 10.0;

    int entryPriceError = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = MathFloor((entryPrice * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}

int CorrectWithSpreadBearishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return MathFloor((iLow(Symbol(), Period(), CurrentBearishRetracementIndex()) * MathPow(10, _Digits)));
}

int CorrectWithSpreadBearish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    int setupType = OP_SELL;
    if (!GetEntryPriceForStopOrderSetup(setupType, true))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    double low = iLow(MBT.Symbol(), MBT.TimeFrame(), CurrentBearishRetracementIndex());
    ut.PendingRecord.AdditionalInformation = "Entry Low Without Spread and Padding: " + DoubleToString(low);

    double entryPrice = 0.0;
    double spreadPips = 10.0;

    int entryPriceError = OrderHelper::GetEntryPriceForStopOrderForPendingMBValidation(spreadPips, setupType, MBT, entryPrice);
    if (entryPriceError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = MathFloor((entryPrice * MathPow(10, _Digits)));
    return Results::UNIT_TEST_RAN;
}
