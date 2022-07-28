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
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/OrderHelper/CheckEditStopLossForStopOrderOnPendingMB/";
const int NumberOfAsserts = 100;
const int AssertCooldown = 0;
const bool RecordScreenShot = true;
const bool RecordErrors = true;

input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

BoolUnitTest<DefaultUnitTestRecord> *DidNotEditBullishMBStopLossUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *DidNotEditBearishMBStopLossUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *DidEditBullishMBStopLossUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *DidEditBearishMBStopLossUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);

    DidNotEditBullishMBStopLossUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Edit Bullish MB Stop Loss", "Stop Loss Was Not Edited When The Old And New Ticker Are The Same",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, DidNotEditBullishMBStopLoss);

    DidNotEditBearishMBStopLossUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Not Edit Bearish MB Stop Loss", "Stop Loss Was Not Edited When The Old And New Ticker Are The Same",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, DidNotEditBearishMBStopLoss);

    DidEditBullishMBStopLossUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Edit Bullish MB Stop Loss", "Stop Loss Was Edited When Retracement went Further",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, DidEditBullishMBStopLoss);

    DidEditBearishMBStopLossUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Did Edit Bearish MB Stop Loss", "Stop Loss Was Edited When Retracement went Further",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, DidEditBearishMBStopLoss);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete DidNotEditBullishMBStopLossUnitTest;
    delete DidNotEditBearishMBStopLossUnitTest;

    delete DidEditBullishMBStopLossUnitTest;
    delete DidEditBearishMBStopLossUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    DidNotEditBullishMBStopLossUnitTest.Assert();
    DidNotEditBearishMBStopLossUnitTest.Assert();

    DidEditBullishMBStopLossUnitTest.Assert();
    DidEditBearishMBStopLossUnitTest.Assert();
}

int DidNotEditBullishMBStopLoss(bool &actual)
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
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        if (tempMBState.Type() != OP_BUY)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return error;
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
            return editStopLossError;
        }

        actual = oldTicket == ticket;
        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
}

int DidNotEditBearishMBStopLoss(bool &actual)
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
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        if (tempMBState.Type() != OP_SELL)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        int retracementIndex = MBT.CurrentBearishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return error;
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
            return editStopLossError;
        }

        actual = oldTicket == ticket;
        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
}

int DidEditBullishMBStopLoss(bool &actual)
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;

    const int type = OP_BUY;
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
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        if (tempMBState.Type() != type)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return error;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }
    else
    {
        double newStopLoss;
        int newStopLossError = OrderHelper::GetStopLossForStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, type, MBT, newStopLoss);
        if (newStopLossError != ERR_NO_ERROR)
        {
            return newStopLossError;
        }

        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(paddingPips, spreadPips, riskPercent, mbNumber, MBT, ticket);
        if (editStopLossError != ERR_NO_ERROR)
        {
            return editStopLossError;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        if (selectError != ERR_NO_ERROR)
        {
            return selectError;
        }

        actual = stopLoss != OrderStopLoss();
        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
}

int DidEditBearishMBStopLoss(bool &actual)
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;

    const int type = OP_SELL;
    const int paddingPips = 0.0;
    const int spreadPips = 0.0;
    const double riskPercent = 0.25;
    const int magicNumber = 0;

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
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        if (tempMBState.Type() != type)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        int retracementIndex = MBT.CurrentBullishRetracementIndex();
        if (retracementIndex == EMPTY)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, riskPercent, magicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return error;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }
    else
    {
        double newStopLoss;
        int newStopLossError = OrderHelper::GetStopLossForStopOrderOnMostRecentPendingMB(paddingPips, spreadPips, type, MBT, newStopLoss);
        if (newStopLossError != ERR_NO_ERROR)
        {
            return newStopLossError;
        }

        if (newStopLoss == stopLoss)
        {
            return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
        }

        int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(paddingPips, spreadPips, riskPercent, mbNumber, MBT, ticket);
        if (editStopLossError != ERR_NO_ERROR)
        {
            return editStopLossError;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        if (selectError != ERR_NO_ERROR)
        {
            return selectError;
        }

        actual = stopLoss != OrderStopLoss();
        return UnitTestConstants::UNIT_TEST_RAN;
    }

    return UnitTestConstants::UNIT_TEST_DID_NOT_RUN;
}