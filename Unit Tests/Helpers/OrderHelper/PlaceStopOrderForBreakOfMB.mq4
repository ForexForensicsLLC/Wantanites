//+------------------------------------------------------------------+
//|                                    PlaceStopOrderOnBreakOfMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Errors.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/PlaceStopOrderForBreakOfMB/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;
const bool RecordScreenShot = true;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

IntUnitTest<DefaultUnitTestRecord> *BullishMBNoErrorUnitTest;
IntUnitTest<DefaultUnitTestRecord> *BearishMBNoErrorUnitTest;

IntUnitTest<DefaultUnitTestRecord> *MBDoesNotExistErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete BullishMBNoErrorUnitTest;
    delete BearishMBNoErrorUnitTest;

    delete MBDoesNotExistErrorUnitTest;
}

void OnTick()
{
    BullishMBNoErrorUnitTest.Assert();
    BearishMBNoErrorUnitTest.Assert();

    MBDoesNotExistErrorUnitTest.Assert();
}

int PlaceOrder(int mbNumber, int &ticket)
{
    int paddingPips = 0.0;
    int spreadPips = 0.0;
    double riskPercent = 0.25;
    int magicNumber = 0;

    return OrderHelper::PlaceStopOrderForBreakOfMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
}

int BullishMBNoError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_BUY)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int ticket = EMPTY;
    actual = PlaceOrder(tempMBState.Number(), ticket);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}

int BearishMBNoError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return Errors::ERR_MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Type() != OP_SELL)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int ticket = EMPTY;
    actual = PlaceOrder(tempMBState.Number(), ticket);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}

int MBDoesNotExistError(int &actual)
{
    int ticket = EMPTY;
    actual = PlaceOrder(EMPTY, ticket);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}