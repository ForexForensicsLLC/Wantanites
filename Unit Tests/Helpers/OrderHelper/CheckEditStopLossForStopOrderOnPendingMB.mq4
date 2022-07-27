//+------------------------------------------------------------------+
//|                     CheckEditStopLossForStopOrderOnPendingMB.mq4 |
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
#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\UnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/CheckEditStopLossForStopOrderOnPendingMB/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 0;

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
    delete didNotEditStopLossUnitTest;
    delete didEditStopLossUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    DidNotEditStopLoss();
    DidEditStopLoss();
}

UnitTest<DefaultUnitTestRecord> *didNotEditStopLossUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void DidNotEditStopLoss()
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;

    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    // reset state if we broke the mb
    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR || isTrue)
        {
            mbNumber = -1;
            stopLoss = 0.0;
            ticket = -1;
        }
    }

    // make sure we have a setup
    if (stopLoss == 0.0)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }
    else
    {
        int oldTicket = ticket;
        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(paddingPips, spreadPips, riskPercent, mbNumber, MBT, ticket);

        if (editStopLossError != Errors::ERR_NEW_STOPLOSS_EQUALS_OLD)
        {
            return;
        }

        bool expected = true;
        bool actual = oldTicket == ticket;

        didNotEditStopLossUnitTest.addTest(__FUNCTION__);
        didNotEditStopLossUnitTest.assertEquals("Did Not Edit Stop Loss", expected, actual);
    }
}

UnitTest<DefaultUnitTestRecord> *didEditStopLossUnitTest = new UnitTest<DefaultUnitTestRecord>(Directory, NumberOfAsserts, AssertCooldown);
void DidEditStopLoss()
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;

    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

    // reset state if we broke the mb
    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR || isTrue)
        {
            mbNumber = -1;
            stopLoss = 0.0;
            ticket = -1;
        }
    }

    // make sure we have a setup
    if (stopLoss == 0.0)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }
    else
    {
        int oldTicket = ticket;
        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(paddingPips, spreadPips, riskPercent, mbNumber, MBT, ticket);

        if (editStopLossError != ERR_NO_ERROR)
        {
            return;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        if (selectError != ERR_NO_ERROR)
        {
            return;
        }

        bool expected = true;
        bool actual = stopLoss == OrderStopLoss();

        didEditStopLossUnitTest.addTest(__FUNCTION__);
        didEditStopLossUnitTest.assertEquals("Did Edit Stop Loss", expected, actual);
    }
}
