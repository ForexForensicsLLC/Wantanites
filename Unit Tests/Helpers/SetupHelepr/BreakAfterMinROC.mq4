//+------------------------------------------------------------------+
//|                                             BreakAfterMinROC.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/SetupHelper/BreakAfterMinROC/";
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

// https://drive.google.com/file/d/16Pfo5Y9kkN08a-FlHXDjm1vUohTi55CZ/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *DifferentSymbolsErrorUnitTest;

// https://drive.google.com/file/d/1ZjqUUcHDAxNk0DGGtG-GHhncrbPrZsj1/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *DifferentTimeFramesErrorUnitTest;

// https://drive.google.com/file/d/1m63I5olV6f0uI_uM7uNEgMUps2sY1ex5/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *NoMinROCIsTrueEqualsFalseUnitTest;

// https://drive.google.com/file/d/1KlD9w_D2dO7OXbgx6aWoJNNqye3UsBeh/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *NotOppositeMBIsTrueEqualsFalseUnitTest;

// https://drive.google.com/file/d/1n9V1kqFldtC8A3uvgrcDeSslFT9CmURy/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BullishSetupTrueUnitTest;

// https://drive.google.com/file/d/1PyawVRMHd4ZUdXRTfaIo8Nir3Na99OL0/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *BearishSetupTrueUnitTest;

// https://drive.google.com/drive/folders/1KYKO8X96_CBsYYNScyEzLCKzo2zCFCrf?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *MinROCAfterBreakReturnsFalseUnitTest;

// https://drive.google.com/drive/folders/10fv7FoVVoicR7Hnsh22UzsGJiOM-mkrY?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *MBBreakIsAfterMinROCUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    DifferentSymbolsErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Different Symbols Errors", "Should Return A Different Symbols Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        TerminalErrors::NOT_EQUAL_SYMBOLS, DifferentSymbolsError);

    DifferentTimeFramesErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Different Time Frames Errors", "Should Return A Different Time Frames Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        TerminalErrors::NOT_EQUAL_TIMEFRAMES, DifferentTimeFramesError);

    NoMinROCIsTrueEqualsFalseUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "No Min ROC IsTrue Equals False", "When There Is Not A Min ROC The Out Parameter IsTrue Should Be Equal To False",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, NoMinROCIsTrueEqualsFalse);

    NotOppositeMBIsTrueEqualsFalseUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Not Opposite MB IsTrue Equals False", "When There Is Not An Opposite MB,The Out Parameter IsTrue Should Be Equal To False",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, NotOppositeMBIsTrueEqualsFalse);

    BullishSetupTrueUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Setup True", "Should Return True That There Is A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishSetupTrue);

    MinROCAfterBreakReturnsFalseUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Min ROC After Break Is False", "Should Return False when an MB breaks and then there is a min roc before a new mb",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, MinROCAfterBreakReturnsFalse);

    MBBreakIsAfterMinROCUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "MB Break is after Min ROC", "Should Return True That The MB that broke happened after the min roc was achieved",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, MBBreakIsAfterMinROC);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete DifferentSymbolsErrorUnitTest;
    delete DifferentTimeFramesErrorUnitTest;

    delete NoMinROCIsTrueEqualsFalseUnitTest;
    delete NotOppositeMBIsTrueEqualsFalseUnitTest;

    delete BullishSetupTrueUnitTest;
    delete BearishSetupTrueUnitTest;

    delete MinROCAfterBreakReturnsFalseUnitTest;
    delete MBBreakIsAfterMinROCUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    /*
    DifferentSymbolsErrorUnitTest.Assert();
    DifferentTimeFramesErrorUnitTest.Assert();

    NoMinROCIsTrueEqualsFalseUnitTest.Assert();
    NotOppositeMBIsTrueEqualsFalseUnitTest.Assert();

    BullishSetupTrueUnitTest.Assert();
    BearishSetupTrueUnitTest.Assert();
    */

    MinROCAfterBreakReturnsFalseUnitTest.Assert();
    MBBreakIsAfterMinROCUnitTest.Assert();
}

int DifferentSymbolsError(int &actual)
{
    string symbol = MBT.Symbol() != "US100.cash" ? "US100.cash" : "EURUSD";

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(symbol, Period(), 10, 10, 10, 10, 0.25);

    bool isTrue = false;
    actual = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    delete tempMRFTS;
    return Results::UNIT_TEST_RAN;
}

int DifferentTimeFramesError(int &actual)
{
    string timeFrame = MBT.TimeFrame() != "1h" ? "1h" : "4h";

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), timeFrame, 10, 10, 10, 10, 0.25);

    bool isTrue = false;
    actual = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    delete tempMRFTS;
    return Results::UNIT_TEST_RAN;
}

int NoMinROCIsTrueEqualsFalse(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Hour() + 1, Minute(), 59, 0.5);

    if (tempMRFTS.HadMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    tempMRFTS.Draw();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);

    delete tempMRFTS;

    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    return Results::UNIT_TEST_RAN;
}

int NotOppositeMBIsTrueEqualsFalse(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (MBT.NthMostRecentMBIsOpposite(0))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Hour() + 1, Minute(), 59, 0.5);

    tempMRFTS.Draw();
    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);

    delete tempMRFTS;

    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    return Results::UNIT_TEST_RAN;
}

int BullishSetupTrue(bool &actual)
{
    static MinROCFromTimeStamp *tempMRFTS;
    static bool reset = false;

    if (Minute() == 0)
    {
        reset = true;
    }

    if (CheckPointer(tempMRFTS) == POINTER_INVALID || reset)
    {
        delete tempMRFTS;
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, 0, 59, 0.05);

        reset = false;
    }

    tempMRFTS.Draw();

    if (!tempMRFTS.HadMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!MBT.NthMostRecentMBIsOpposite(0))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStates[];
    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    bool bothBelow = iHigh(Symbol(), Period(), tempMBStates[1].HighIndex()) < tempMRFTS.OpenPrice() && iHigh(Symbol(), Period(), tempMBStates[0].HighIndex()) < tempMRFTS.OpenPrice();
    bool breakingUp = bothBelow && tempMBStates[0].Type() == OP_BUY;

    if (!breakingUp)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BullishSetupTrueUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(BullishSetupTrueUnitTest.Directory());

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BearishSetupTrue(bool &actual)
{
    static MinROCFromTimeStamp *tempMRFTS;
    static bool reset = false;

    if (Minute() == 0)
    {
        reset = true;
    }

    if (CheckPointer(tempMRFTS) == POINTER_INVALID || reset == true)
    {
        delete tempMRFTS;
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, 0, 59, 0.05);

        reset = false;
    }

    tempMRFTS.Draw();

    if (!tempMRFTS.HadMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!MBT.NthMostRecentMBIsOpposite(0))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStates[];

    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    bool bothAbove = iLow(Symbol(), Period(), tempMBStates[1].LowIndex()) > tempMRFTS.OpenPrice() && iLow(Symbol(), Period(), tempMBStates[0].LowIndex()) > tempMRFTS.OpenPrice();
    bool breakingDown = bothAbove && tempMBStates[0].Type() == OP_SELL;

    if (!breakingDown)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    BearishSetupTrueUnitTest.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(BearishSetupTrueUnitTest.Directory());

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int MinROCAfterBreakReturnsFalse(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static MinROCFromTimeStamp *tempMRFTS;
    static bool reset = false;

    if (CheckPointer(tempMRFTS) == POINTER_INVALID || reset == true)
    {
        delete tempMRFTS;
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), Minute() + 2, 0.07);

        reset = false;
    }

    if (tempMRFTS.OpenPrice() == 0.0)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    tempMRFTS.Draw();

    if (!tempMRFTS.HadMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (!MBT.NthMostRecentMBIsOpposite(0))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBStates[];
    if (!MBT.GetNMostRecentMBs(2, tempMBStates))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (iTime(tempMRFTS.Symbol(), tempMRFTS.TimeFrame(), tempMBStates[0].EndIndex()) > tempMRFTS.MinROCAchievedTime())
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    bool isTrue = true;
    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    actual = !isTrue && error == ERR_NO_ERROR;
    reset = true;
    return Results::UNIT_TEST_RAN;
}

int MBBreakIsAfterMinROC(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static MinROCFromTimeStamp *tempMRFTS;
    static bool reset = false;

    if (CheckPointer(tempMRFTS) == POINTER_INVALID || reset == true)
    {
        delete tempMRFTS;
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), Minute() + 2, 0.07);

        reset = false;
    }

    if (tempMRFTS.OpenPrice() == 0.0)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    tempMRFTS.Draw();

    bool isTrue = true;
    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    if (error != ERR_NO_ERROR || !isTrue)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());
    actual = iTime(tempMRFTS.Symbol(), tempMRFTS.TimeFrame(), tempMBState.EndIndex()) > tempMRFTS.MinROCAchievedTime();
    reset = true;
    return Results::UNIT_TEST_RAN;
}