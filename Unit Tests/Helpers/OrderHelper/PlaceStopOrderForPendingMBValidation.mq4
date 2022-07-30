//+------------------------------------------------------------------+
//|                          PlaceStopOrderOnMostRecentPendingMB.mq4 |
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

const string Directory = "/UnitTests/OrderHelper/PlaceStopOrderForPendingMBValidation/";
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
IntUnitTest<DefaultUnitTestRecord> *NotMostRecentMBErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    BullishMBNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bullish MB No Errors", "Places Stop Order On Most Recent Bullish MB Without Errors",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BullishMBNoError);

    BearishMBNoErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Bearish MB No Errors", "Places Stop Order On Most Recent Bearish MB Without Errors",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        ERR_NO_ERROR, BearishMBNoError);

    NotMostRecentMBErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Not Most Recent MB Error", "Returns An Error When Trying To Place A Stop Order Not On The Most Recent MB",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::ERR_MB_IS_NOT_MOST_RECENT, NotMostRecentMBError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishMBNoErrorUnitTest;
    delete BearishMBNoErrorUnitTest;
    delete NotMostRecentMBErrorUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishMBNoErrorUnitTest.Assert();
    BearishMBNoErrorUnitTest.Assert();

    NotMostRecentMBErrorUnitTest.Assert();
}

int CheckMostRecentPendingMB(int type)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return EMPTY;
    }

    if (tempMBState.Type() != type)
    {
        return EMPTY;
    }

    int retracementIndex = EMPTY;
    if (type == OP_BUY)
    {
        retracementIndex = MBT.CurrentBullishRetracementIndex();
    }
    else if (type == OP_SELL)
    {
        retracementIndex = MBT.CurrentBearishRetracementIndex();
    }

    if (retracementIndex == EMPTY)
    {
        return EMPTY;
    }

    return tempMBState.Number();
}

int PlaceStopOrder(int setupMBNumber, out int &ticket)
{
    ticket = -1;
    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    return OrderHelper::PlaceStopOrderForPendingMBValidation(paddingPips, spreadPips, riskPercent, magicNumber, setupMBNumber, MBT, ticket);
}

int PlaceStoporderOnMostRecentPendingMB(int type, out int &ticket)
{
    int mbNumber = CheckMostRecentPendingMB(type);
    if (mbNumber == EMPTY)
    {
        return Errors::ERR_MB_IS_NOT_MOST_RECENT;
    }

    return PlaceStopOrder(mbNumber, ticket);
}

int BullishMBNoError(int &actual)
{
    int ticket = -1;
    int type = OP_BUY;

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket);
    if (error == Errors::ERR_MB_IS_NOT_MOST_RECENT)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    actual = error;
    return UnitTestConstants::UNIT_TEST_RAN;
}

int BearishMBNoError(int &actual)
{
    int ticket = -1;
    int type = OP_SELL;

    int error = PlaceStoporderOnMostRecentPendingMB(type, ticket);
    if (error == Errors::ERR_MB_IS_NOT_MOST_RECENT)
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    actual = error;
    return UnitTestConstants::UNIT_TEST_RAN;
}

int NotMostRecentMBError(int &actual)
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(2, tempMBState))
    {
        return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
    }

    int ticket = -1;

    actual = PlaceStopOrder(tempMBState.Number(), ticket);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }

    return UnitTestConstants::UNIT_TEST_RAN;
}