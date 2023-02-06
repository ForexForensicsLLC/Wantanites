//+------------------------------------------------------------------+
//|                        GetEntryPriceForStopOrderForBreakOfMB.mq4 |
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

const string Directory = "/UnitTests/Helpers/OrderHelper/GetEntryPriceForStopOrderForBreakOfMB/";
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

// https://drive.google.com/file/d/1fRhKRvz4ZXDngYFfir2_3JOftX-MFSbV/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *InvalidMBNumberErrorUnitTest;

// https://drive.google.com/file/d/1KsZP9U918OGOMTT99N9tR9x8zyq5mTXF/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *NoErrorsUnitTest;

// https://drive.google.com/file/d/1c2I1m8yrxf3qn3xCUZNXYRjDdULTf0Oy/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectEntryPriceForBullishMBUnitTest;

// https://drive.google.com/file/d/1V0ICVeKvQz78paKE74XhPnVoC8Ki8JSW/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectEntryPriceForBearishMBUnitTest;

// https://drive.google.com/file/d/1Ez3_FzoCvVjr3tQ49371aF5k-b7JZD7O/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectEntryWithSpreadAndPaddingBullishUnitTest;

// https://drive.google.com/file/d/1RETUbyzSRUkmISVFQbuUgBE2I7Yi1O6x/view?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CorrectEntryWithSpreadAndPaddingBearishUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    InvalidMBNumberErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Invalid MB Number", "Returns Error When Passing In An Invalid MB Number When Retrieving Entry Price",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::MB_DOES_NOT_EXIST, InvalidMBNumberError);

    NoErrorsUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "No Errors", "Returns No Errors When Retrieving Entry Price",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, NoErrors);

    CorrectEntryPriceForBullishMBUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct Entry Price For Bullish MB", "Returns The Correct Entry Price For A Stop Order On The Break Of A Bullish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectEntryPriceForBullishMBExpected, CorrectEntryPriceForBullishMB);

    CorrectEntryPriceForBearishMBUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct Entry Price For Bearish MB", "Returns The Correct Entry Price For A Stop Order On The Break Of A Bearish MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectEntryPriceForBearishMBExpected, CorrectEntryPriceForBearishMB);

    CorrectEntryWithSpreadAndPaddingBullishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct Entry With S And P For Bullish", "Returns The Correct Entry Price For A Stop Order On The Break Of A Bullish MB With 10 Pips Of Spread And Padding",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectEntryWithSpreadAndPaddingBullishExpected, CorrectEntryWithSpreadAndPaddingBullish);

    CorrectEntryWithSpreadAndPaddingBearishUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Correct Entry With S And P For Bearish", "Returns The Correct Entry Price For A Stop Order On The Break Of A Bearish MB With 10 Pips Of Spread And Padding",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        CorrectEntryWithSpreadAndPaddingBearishExpected, CorrectEntryWithSpreadAndPaddingBearish);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete InvalidMBNumberErrorUnitTest;
    delete NoErrorsUnitTest;

    delete CorrectEntryPriceForBullishMBUnitTest;
    delete CorrectEntryPriceForBearishMBUnitTest;

    delete CorrectEntryWithSpreadAndPaddingBullishUnitTest;
    delete CorrectEntryWithSpreadAndPaddingBearishUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    /*
    InvalidMBNumberErrorUnitTest.Assert();
    NoErrorsUnitTest.Assert();

    CorrectEntryPriceForBullishMBUnitTest.Assert();
    CorrectEntryPriceForBearishMBUnitTest.Assert();
    */

    CorrectEntryWithSpreadAndPaddingBullishUnitTest.Assert();
    CorrectEntryWithSpreadAndPaddingBearishUnitTest.Assert();
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

int CorrectEntryPriceForBullishMBExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
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

int CorrectEntryPriceForBearishMBExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
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

int CorrectEntryWithSpreadAndPaddingBullishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return MathFloor((iLow(MBT.Symbol(), MBT.TimeFrame(), tempMBState.LowIndex()) * MathPow(10, _Digits)));
}

int CorrectEntryWithSpreadAndPaddingBullish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
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

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    double low = iLow(MBT.Symbol(), MBT.TimeFrame(), tempMBState.LowIndex());
    ut.PendingRecord.AdditionalInformation = "Entry Low Without Spread and Padding: " + DoubleToString(low);

    double spreadPips = 10.0;
    double entryPrice = 0.0;

    int error = OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(spreadPips, tempMBState.Number(), MBT, entryPrice);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(entryPrice * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}

int CorrectEntryWithSpreadAndPaddingBearishExpected(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return MathFloor(((iHigh(MBT.Symbol(), MBT.TimeFrame(), tempMBState.HighIndex()) + OrderHelper::PipsToRange(10)) * MathPow(10, _Digits)));
}

int CorrectEntryWithSpreadAndPaddingBearish(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
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

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    double high = iHigh(MBT.Symbol(), MBT.TimeFrame(), tempMBState.HighIndex());
    ut.PendingRecord.AdditionalInformation = "Entry High Without Spread and Padding: " + DoubleToString(high);

    double spreadPips = 10.0;
    double entryPrice = 0.0;

    int error = OrderHelper::GetEntryPriceForStopOrderForBreakOfMB(spreadPips, tempMBState.Number(), MBT, entryPrice);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    actual = MathFloor(entryPrice * MathPow(10, _Digits));
    return Results::UNIT_TEST_RAN;
}