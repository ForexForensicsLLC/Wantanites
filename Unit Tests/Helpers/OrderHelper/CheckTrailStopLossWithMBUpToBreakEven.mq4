//+------------------------------------------------------------------+
//|                                     CheckTrailStopLossWithMB.mq4 |
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
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/CheckTrailStopLossWithMBUpToBreakEven/";
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

const int PaddingPips = 0.0;
const int SpreadPips = 0.0;
const double RiskPercent = 0.25;
const int MagicNumber = 0;

BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishNoErrorsSameStopLossUnitTest;
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishNoErrorsSameStopLossUnitTest;

BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishNoErrorsDifferentStopLossUnitTest;
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishNoErrorsDifferentStopLossUnitTest;

IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *DoesNotTrailPendingOrdersUnitTest;

BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishDoesNotTrailPastOpenUnitTest;
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishDoesNotTrailPastOpenUnitTest;

IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *SubsequentMBDoesNotExistErrorUnitTest;

IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishNotEqualMBTypesErrorUnitTest;
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishNotEqualMBTypesErrorUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    BullishNoErrorsSameStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish No Errors Same Stop Loss", "The Stop Loss Was Not Changed When No Errors Were Retruned In A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishNoErrorsSameStopLoss);

    BearishNoErrorsSameStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish No Errors Same Stop Loss", "The Stop Loss Was Not Changed When No Errors Were Retruned In A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishNoErrorsSameStopLoss);

    BullishNoErrorsDifferentStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish No Errors Different Stop Loss", "The Stop Loss Was Changed When No Errors Were Retruned In A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishNoErrorsDifferentStopLoss);

    BearishNoErrorsDifferentStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish No Errors Different Stop Loss", "The Stop Loss Was Changed When No Errors Were Retruned In A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishNoErrorsDifferentStopLoss);

    DoesNotTrailPendingOrdersUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Does Not Trail Pending Orders", "Should Return A Wrong Order Type Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        TerminalErrors::WRONG_ORDER_TYPE, DoesNotTrailPendingOrders);

    BullishDoesNotTrailPastOpenUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish Does Not Trail Past Open", "The Stop Loss Is Not Moved Above / Below The Entry In A Bullish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BullishDoesNotTrailPastOpen);

    BearishDoesNotTrailPastOpenUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish Does Not Trail Past Open", "The Stop Loss Is Not Moved Above / Below The Entry In A Bearish Setup",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, BearishDoesNotTrailPastOpen);

    SubsequentMBDoesNotExistErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Subsequent MB Does Not Exist", "Should Return A Subsequent MB Does Not Exist Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        ExecutionErrors::SUBSEQUENT_MB_DOES_NOT_EXIST, SubsequentMBDoesNotExist);

    BullishNotEqualMBTypesErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bullish Not Equal Types Error", "Should Return A Not Equal MB Types Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        ExecutionErrors::NOT_EQUAL_MB_TYPES, BullishNotEqualTypesError);

    BearishNotEqualMBTypesErrorUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish Not Equal Types Error", "Should Return A Not Equal MB Types Error",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        ExecutionErrors::NOT_EQUAL_MB_TYPES, BearishNotEqualTypesError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete BullishNoErrorsSameStopLossUnitTest;
    delete BearishNoErrorsSameStopLossUnitTest;

    delete BullishNoErrorsDifferentStopLossUnitTest;
    delete BearishNoErrorsDifferentStopLossUnitTest;

    delete DoesNotTrailPendingOrdersUnitTest;

    delete BullishDoesNotTrailPastOpenUnitTest;
    delete BearishDoesNotTrailPastOpenUnitTest;

    delete SubsequentMBDoesNotExistErrorUnitTest;

    delete BullishNotEqualMBTypesErrorUnitTest;
    delete BearishNotEqualMBTypesErrorUnitTest;
}

void OnTick()
{
    MBT.DrawNMostRecentMBs(1);
    MBT.DrawZonesForNMostRecentMBs(1);

    BullishNoErrorsSameStopLossUnitTest.Assert();
    /*
    BearishNoErrorsSameStopLossUnitTest.Assert();

    BullishNoErrorsDifferentStopLossUnitTest.Assert();
    BearishNoErrorsDifferentStopLossUnitTest.Assert();

    DoesNotTrailPendingOrdersUnitTest.Assert();

    BullishDoesNotTrailPastOpenUnitTest.Assert();
    BearishDoesNotTrailPastOpenUnitTest.Assert();

    SubsequentMBDoesNotExistErrorUnitTest.Assert();

    BullishNotEqualMBTypesErrorUnitTest.Assert();
    BearishNotEqualMBTypesErrorUnitTest.Assert();
    */
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

int SetSetupVariables(int type, int &ticket, int &mbNumber, int &setupType, double &stopLoss, double &entryPrice, bool &reset)
{
    if (reset)
    {
        mbNumber = EMPTY;
        setupType = EMPTY;
        stopLoss = 0.0;
        entryPrice = 0.0;

        if (ticket > 0)
        {
            int closeTicketError = CloseTicket(ticket);
        }

        ticket = EMPTY;
        reset = false;
    }

    if (mbNumber != EMPTY)
    {
        bool isTrue = false;
        int error = SetupHelper::BrokeMBRangeStart(mbNumber, MBT, isTrue);
        if (error != ERR_NO_ERROR || isTrue)
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }
    }

    if (ticket == EMPTY)
    {
        MBState *tempMBState;
        if (!MBT.GetNthMostRecentMB(0, tempMBState))
        {
            return TerminalErrors::MB_DOES_NOT_EXIST;
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
                ;
            }
        }

        mbNumber = tempMBState.Number();
        setupType = tempMBState.Type();
        int error = OrderHelper::PlaceStopOrderForPendingMBValidation(PaddingPips, SpreadPips, RiskPercent, MagicNumber, mbNumber, MBT, ticket);
        if (error != ERR_NO_ERROR)
        {
            reset = true;
            return error;
        }

        int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            reset = true;
            return selectError;
        }

        stopLoss = OrderStopLoss();
        entryPrice = OrderOpenPrice();
    }

    return ERR_NO_ERROR;
}

int CheckSetup(int type, int ticket, int mbNumber, int setupType, double stopLoss, bool shouldBePendingOrder, bool newStopLossShouldBeEqual, bool shouldHaveSameTypeMBs)
{
    bool isPending = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(ticket, isPending);
    if (pendingOrderError != ERR_NO_ERROR)
    {
        return pendingOrderError;
    }

    if ((shouldBePendingOrder && !isPending) || (!shouldBePendingOrder && isPending))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    double newStopLoss;
    int newStopLossError = OrderHelper::GetStopLossForStopOrderForPendingMBValidation(PaddingPips, SpreadPips, type, MBT, newStopLoss);
    if (newStopLossError != ERR_NO_ERROR)
    {
        return newStopLossError;
    }

    if ((newStopLossShouldBeEqual && newStopLoss != stopLoss) || (!newStopLossShouldBeEqual && newStopLoss == stopLoss))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (tempMBState.Number() <= mbNumber)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if ((shouldHaveSameTypeMBs && tempMBState.Type() != setupType) || (!shouldHaveSameTypeMBs && tempMBState.Type() == setupType))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    return ERR_NO_ERROR;
}

int BullishNoErrorsSameStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_BUY;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;
    static datetime cooldown = 0;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, true);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    if (!succeeded)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() == stopLoss;

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BearishNoErrorsSameStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_SELL;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    if (!succeeded)
    {
        return trailError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    actual = OrderStopLoss() == stopLoss;

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BullishNoErrorsDifferentStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_BUY;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    if (!succeeded)
    {
        return trailError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    actual = OrderStopLoss() != stopLoss;

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BearishNoErrorsDifferentStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_SELL;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    if (!succeeded)
    {
        return trailError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    actual = OrderStopLoss() != stopLoss;

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int DoesNotTrailPendingOrders(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    const int type = OP_SELL;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, true, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BullishDoesNotTrailPastOpen(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_BUY;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return setupVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    if (!succeeded)
    {
        return trailError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    actual = OrderStopLoss() <= entryPrice;
    reset = true;

    return Results::UNIT_TEST_RAN;
}

int BearishDoesNotTrailPastOpen(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_SELL;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return setupVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    if (!succeeded)
    {
        return trailError;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = OrderHelper::SelectOpenOrderByTicket(ticket, "Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return selectError;
    }

    actual = OrderStopLoss() >= entryPrice;
    reset = true;

    return Results::UNIT_TEST_RAN;
}

int SubsequentMBDoesNotExist(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    int ticket = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Ask - OrderHelper::PipsToRange(200), 0.0, NULL, 0, 0, clrNONE);
    if (ticket < 0)
    {
        return GetLastError();
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, tempMBState.Number(), tempMBState.Type(), MBT, succeeded);

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int error = CloseTicket(ticket);
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    return Results::UNIT_TEST_RAN;
}

int BullishNotEqualTypesError(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    const int type = OP_BUY;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return setupVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, false);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    reset = true;

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return Results::UNIT_TEST_RAN;
}

int BearishNotEqualTypesError(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    const int type = OP_SELL;

    static int ticket = -1;
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return setupVariablesError;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, false);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(ticket, PaddingPips, SpreadPips, mbNumber, setupType, MBT, succeeded);
    reset = true;

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return Results::UNIT_TEST_RAN;
}