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
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/PlaceStopOrderOnMostRecentPendingMB/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 1;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete bullishMBNoErrorUnitTest;
    delete bearishMBNoErrorUnitTest;
    delete notMostRecentMBError;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishMBNoError();
    BearishMBNoError();

    NotMostRecentMBError();
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

    return OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, setupMBNumber, MBT, ticket);
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

UnitTest<DefaultUnitTestRecord> *bullishMBNoErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BullishMBNoError()
{
    int ticket = -1;
    int type = OP_BUY;

    int expected = ERR_NO_ERROR;
    int actual = PlaceStoporderOnMostRecentPendingMB(type, ticket);

    bullishMBNoErrorUnitTest.addTest(__FUNCTION__);
    bullishMBNoErrorUnitTest.assertEquals("Place Stop Order On Most Recent Bullish MB No Error", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *bearishMBNoErrorUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void BearishMBNoError()
{
    int ticket = -1;
    int type = OP_SELL;

    int expected = ERR_NO_ERROR;
    int actual = PlaceStoporderOnMostRecentPendingMB(type, ticket);

    bearishMBNoErrorUnitTest.addTest(__FUNCTION__);
    bearishMBNoErrorUnitTest.assertEquals("Place Stop Order On Most Recent Bullish MB No Error", expected, actual);

    if (ticket > 0)
    {
        OrderDelete(ticket, clrNONE);
    }
}

UnitTest<DefaultUnitTestRecord> *notMostRecentMBError = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void NotMostRecentMBError()
{
    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(2, tempMBState))
    {
        return;
    }

    int ticket = -1;

    int expected = Errors::ERR_MB_IS_NOT_MOST_RECENT;
    int actual = PlaceStopOrder(tempMBState.Number(), ticket);

    notMostRecentMBError.addTest(__FUNCTION__);
    notMostRecentMBError.assertEquals("Not Most Recent MB Error", expected, actual);
}