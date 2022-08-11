//+------------------------------------------------------------------+
//|                     CheckEditStopLossForStopOrderOnPendingMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>
#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/CheckEditStopLossForStopOrderOnPendingMB/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
const bool RecordScreenShot = true;
const bool RecordErrors = true;

input int MBsToTrack = 5;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *DidNotEditBullishMBStopLossUnitTest;
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *DidNotEditBearishMBStopLossUnitTest;

BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *DidEditBullishMBStopLossUnitTest;
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *DidEditBearishMBStopLossUnitTest;

const int PaddingPips = 0.0;
const int SpreadPips = 0.0;
const double RiskPercent = 0.25;
const int MagicNumber = 0;
const int MinCooldDown = 1;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    DidNotEditBullishMBStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Did Not Edit Bullish MB Stop Loss", "Stop Loss Was Not Edited When The Old And New Ticker Are The Same",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DidNotEditBullishMBStopLoss);

    DidNotEditBearishMBStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Did Not Edit Bearish MB Stop Loss", "Stop Loss Was Not Edited When The Old And New Ticker Are The Same",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DidNotEditBearishMBStopLoss);

    DidEditBullishMBStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Did Edit Bullish MB Stop Loss", "Stop Loss Was Edited When Retracement went Further",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, DidEditBullishMBStopLoss);

    DidEditBearishMBStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Did Edit Bearish MB Stop Loss", "Stop Loss Was Edited When Retracement went Further",
        NumberOfAsserts, AssertCooldown, RecordErrors,
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

    // DidNotEditBullishMBStopLossUnitTest.Assert();
    DidNotEditBearishMBStopLossUnitTest.Assert();

    // DidEditBullishMBStopLossUnitTest.Assert();
    // DidEditBearishMBStopLossUnitTest.Assert();
}

int CloseTicket(int &ticket)
{
    bool isPending = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(ticket, isPending);
    if (pendingOrderError != ERR_NO_ERROR)
    {
        return pendingOrderError;
    }

    if (isPending)
    {
        if (!OrderDelete(ticket, clrNONE))
        {
            return GetLastError();
        }
    }
    else
    {
        int orderSelectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Check Edit Stop Loss");
        if (orderSelectError != ERR_NO_ERROR)
        {
            return orderSelectError;
        }

        if (!OrderClose(ticket, OrderLots(), Ask, 0, clrNONE))
        {
            return GetLastError();
        }
    }

    return ERR_NO_ERROR;
}

int SetSetupVariables(int type, int &ticket, double &stopLoss, int &mbNumber, bool &reset, datetime &cooldown, int &setupImageCount)
{
    if (reset)
    {
        stopLoss = 0.0;
        mbNumber = EMPTY;
        cooldown = TimeCurrent();
        setupImageCount = 0;

        if (ticket != EMPTY)
        {
            int closeTicketError = CloseTicket(ticket);
            ticket = EMPTY;

            if (closeTicketError != ERR_NO_ERROR)
            {
                reset = false;
                return closeTicketError;
            }
        }

        reset = false;
    }

    if (!PastCooldown(cooldown))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if (mbNumber != -1)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);

        if (error != ERR_NO_ERROR)
        {
            reset = true;
            return error;
        }

        if (isTrue)
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if (!MBT.MBIsMostRecent(mbNumber))
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }
    }

    if (stopLoss == 0.0)
    {
        // this should be moved into its own section like for other tests?
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if (tempMBState.Type() != type)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        int retracementIndex = EMPTY;
        if (type == OP_BUY)
        {
            if (!MBT.CurrentBullishRetracementIndexIsValid(retracementIndex))
            {
                return Results::UNIT_TEST_DID_NOT_RUN;
            }
        }
        else if (type == OP_SELL)
        {
            if (!MBT.CurrentBearishRetracementIndexIsValid(retracementIndex))
            {
                return Results::UNIT_TEST_DID_NOT_RUN;
            }
        }

        mbNumber = tempMBState.Number();

        int error = OrderHelper::PlaceStopOrderForPendingMBValidation(PaddingPips, SpreadPips, RiskPercent, MagicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            return error;
        }

        OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
        stopLoss = OrderStopLoss();
    }

    return ERR_NO_ERROR;
}

bool PastCooldown(datetime cooldown)
{
    if (cooldown == 0)
    {
        return true;
    }

    if (Hour() == TimeHour(cooldown) && (Minute() - TimeMinute(cooldown) >= MinCooldDown))
    {
        return true;
    }

    if (Hour() > TimeHour(cooldown))
    {
        int minutes = (59 - TimeMinute(cooldown)) + Minute();
        return minutes >= MinCooldDown;
    }

    return false;
}

int DidNotEditBullishMBStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    static int ticket = EMPTY;
    static double stopLoss = 0.0;
    static int mbNumber = EMPTY;
    static bool reset = false;
    static datetime cooldown = 0;
    static int setupImageCount = 0;

    int setupError = SetSetupVariables(OP_BUY, ticket, stopLoss, mbNumber, reset, cooldown, setupImageCount);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int oldTicket = ticket;

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(PaddingPips, SpreadPips, RiskPercent, mbNumber, MBT, ticket);

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    if (editStopLossError != ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = oldTicket == ticket;

    setupImageCount += 1;
    return Results::UNIT_TEST_RAN;
}

int DidNotEditBearishMBStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;
    static bool reset = false;
    static datetime cooldown = 0;
    static int setupImageCount = 0;

    int setupError = SetSetupVariables(OP_SELL, ticket, stopLoss, mbNumber, reset, cooldown, setupImageCount);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    int oldTicket = ticket;

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(PaddingPips, SpreadPips, RiskPercent, mbNumber, MBT, ticket);

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    if (editStopLossError != ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD)
    {
        return editStopLossError;
    }

    actual = oldTicket == ticket;

    setupImageCount += 1;
    return Results::UNIT_TEST_RAN;
}

int DidEditBullishMBStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;
    static bool reset = false;
    static datetime cooldown = 0;
    static int setupImageCount = 0;

    int setupVariablesError = SetSetupVariables(OP_BUY, ticket, stopLoss, mbNumber, reset, cooldown, setupImageCount);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return setupVariablesError;
    }

    if (!PastCooldown(cooldown))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double newStopLoss;
    int newStopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(PaddingPips, SpreadPips, OP_BUY, MBT, newStopLoss);
    if (newStopLossError != ERR_NO_ERROR)
    {
        return newStopLossError;
    }

    if (newStopLoss == stopLoss)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(PaddingPips, SpreadPips, RiskPercent, mbNumber, MBT, ticket);
    if (editStopLossError != ERR_NO_ERROR)
    {
        reset = true;
        return editStopLossError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        reset = true;
        return selectError;
    }

    actual = stopLoss != OrderStopLoss();

    setupImageCount += 1;
    return Results::UNIT_TEST_RAN;
}

int DidEditBearishMBStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    static int ticket = -1;
    static double stopLoss = 0.0;
    static int mbNumber = -1;
    static bool reset = false;
    static datetime cooldown = 0;
    static int setupImageCount = 0;

    int setupVariablesError = SetSetupVariables(OP_SELL, ticket, stopLoss, mbNumber, reset, cooldown, setupImageCount);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return setupVariablesError;
    }

    if (!PastCooldown(cooldown))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double newStopLoss;
    int newStopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(PaddingPips, SpreadPips, OP_SELL, MBT, newStopLoss);
    if (newStopLossError != ERR_NO_ERROR)
    {
        return newStopLossError;
    }

    if (newStopLoss == stopLoss)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    int editStopLossError = OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(PaddingPips, SpreadPips, RiskPercent, mbNumber, MBT, ticket);
    if (editStopLossError != ERR_NO_ERROR)
    {
        reset = true;
        return editStopLossError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), IntegerToString(setupImageCount));

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing Editing Stop Loss");
    if (selectError != ERR_NO_ERROR)
    {
        reset = true;
        return selectError;
    }

    actual = stopLoss != OrderStopLoss();

    setupImageCount += 1;
    return Results::UNIT_TEST_RAN;
}