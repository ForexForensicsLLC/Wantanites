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

IntUnitTest<DefaultUnitTestRecord> *DifferentSymbolsErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *DifferentTimeFramesErrorUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *NoMinROCIsTrueEqualsFalseUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *NotOppositeMBIsTrueEqualsFalseUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *BullishSetupTrueUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *BearishSetupTrueUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    DifferentSymbolsErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Different Symbols Errors", "Should Return A Different Symbols Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::NOT_EQUAL_SYMBOLS, DifferentSymbolsError);

    DifferentTimeFramesErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Different Time Frames Errors", "Should Return A Different Time Frames Error",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        TerminalErrors::NOT_EQUAL_TIMEFRAMES, DifferentTimeFramesError);

    NoMinROCIsTrueEqualsFalseUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "No Min ROC, IsTrue Equals False", "When There Is Not A Min ROC, The Out Parameter IsTrue Should Be Equal To False",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, NoMinROCIsTrueEqualsFalse);

    NotOppositeMBIsTrueEqualsFalseUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Not Opposite MB, IsTrue Equals False", "When There Is Not An Opposite MB, The Out Parameter IsTrue Should Be Equal To False",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        false, NotOppositeMBIsTrueEqualsFalse);

    BullishSetupTrueUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish Setup True", "Should Return True That There Is A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BullishSetupTrue);

    BearishSetupTrueUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish Setup True", "Should Return True That There Is A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, BearishSetupTrue);

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
}

void OnTick()
{
    DifferentSymbolsErrorUnitTest.Assert();
    DifferentTimeFramesErrorUnitTest.Assert();

    NoMinROCIsTrueEqualsFalseUnitTest.Assert();
    NotOppositeMBIsTrueEqualsFalseUnitTest.Assert();

    BullishSetupTrueUnitTest.Assert();
    BearishSetupTrueUnitTest.Assert();
}

int DifferentSymbolsError(int &actual)
{
    string symbol = MBT.Symbol() != "US100.cash" ? "US100.cash" : "EURUSD";

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(symbol, Period(), 10, 10, 10, 10, 0.25);

    bool isTrue = false;
    actual = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    return Results::UNIT_TEST_RAN;
}

int DifferentTimeFramesError(int &actual)
{
    string timeFrame = MBT.TimeFrame() != "1h" ? "1h" : "4h";

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), timeFrame, 10, 10, 10, 10, 0.25);

    bool isTrue = false;
    actual = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, isTrue);

    return Results::UNIT_TEST_RAN;
}

int NoMinROCIsTrueEqualsFalse(bool &actual)
{
    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.5);

    if (tempMRFTS.HadMinROC())
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    return Results::UNIT_TEST_RAN;
}

int NotOppositeMBIsTrueEqualsFalse(bool &actual)
{
    if (MBT.NthMostRecentMBIsOpposite(0))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MinROCFromTimeStamp *tempMRFTS;
    tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.5);

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
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

    if (CheckPointer(tempMRFTS) == POINTER_INVALID || reset)
    {
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.05);
        reset = false;
    }

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

    if (CheckPointer(tempMRFTS) == POINTER_INVALID || reset == true)
    {
        tempMRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Minute(), Hour() + 1, 59, 0.05);
        reset = false;
    }

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

    int error = SetupHelper::BreakAfterMinROC(tempMRFTS, MBT, actual);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    reset = true;
    return Results::UNIT_TEST_RAN;
}