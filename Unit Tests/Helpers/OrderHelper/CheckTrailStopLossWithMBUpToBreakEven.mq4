//+------------------------------------------------------------------+
//|                                     CheckTrailStopLossWithMB.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Objects\Ticket.mqh>
#include <Wantanites\Framework\Trackers\MBTracker.mqh>
#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/CheckTrailStopLossWithMBUpToBreakEven/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = true;
const bool RecordErrors = true;

input int MBsToTrack = 5;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MBTracker *MBT;

const int PaddingPips = 0;
input const int SpreadPips = 0;
const double RiskPercent = 0.25;
const int MagicNumber = 0;

BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishNoErrorsSameStopLossUnitTest;
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishNoErrorsSameStopLossUnitTest;

// https://drive.google.com/drive/folders/16NPpWIxicKMQGgFzCkrxUN_aATBDB77y?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishNoErrorsDifferentStopLossUnitTest;

// https://drive.google.com/drive/folders/1u-9mSJ3nxnd2x1QDlcdOot692O_9vkYQ?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishNoErrorsDifferentStopLossUnitTest;

// https://drive.google.com/drive/folders/1yarxTr7rt6Cef7RCQCpgN9EX8a_rMbio?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *DoesNotTrailPendingOrdersUnitTest;

// https://drive.google.com/drive/folders/1AEqtukYUM-R8_gPeX-2DoOhlF1-Bsh6z?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishDoesNotTrailPastOpenUnitTest;

// https://drive.google.com/drive/folders/16qV_WDQdFS8HzaZOY92Y-w6jRtSxUlp9?usp=sharing
BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> *BearishDoesNotTrailPastOpenUnitTest;

// https://drive.google.com/drive/folders/1GaFEnPh-ej3U-Dbe_U913LLMJVW2iC6l?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *SubsequentMBDoesNotExistErrorUnitTest;

// https://drive.google.com/drive/folders/1U66XeqapweKptnfdFzYUPm6lc0otSVhV?usp=sharing
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *BullishNotEqualMBTypesErrorUnitTest;

// https://drive.google.com/drive/folders/1KBkwnMZEoJ1aX2_F0FW5uJl7U7LZt4cF?usp=sharing
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
        12, AssertCooldown, RecordErrors,
        true, BullishNoErrorsDifferentStopLoss);

    BearishNoErrorsDifferentStopLossUnitTest = new BoolUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Bearish No Errors Different Stop Loss", "The Stop Loss Was Changed When No Errors Were Retruned In A Bearish Setup",
        16, AssertCooldown, RecordErrors,
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

    // BullishNoErrorsSameStopLossUnitTest.Assert();
    // BearishNoErrorsSameStopLossUnitTest.Assert();

    // BullishNoErrorsDifferentStopLossUnitTest.Assert();
    // BearishNoErrorsDifferentStopLossUnitTest.Assert();

    // DoesNotTrailPendingOrdersUnitTest.Assert();

    // BullishDoesNotTrailPastOpenUnitTest.Assert();
    // BearishDoesNotTrailPastOpenUnitTest.Assert();

    // SubsequentMBDoesNotExistErrorUnitTest.Assert();

    BullishNotEqualMBTypesErrorUnitTest.Assert();
    BearishNotEqualMBTypesErrorUnitTest.Assert();
}

int SetSetupVariables(int type, Ticket *&ticket, int &mbNumber, int &setupType, double &stopLoss, double &entryPrice, bool &reset)
{
    if (reset)
    {
        mbNumber = EMPTY;
        setupType = EMPTY;
        stopLoss = 0.0;
        entryPrice = 0.0;

        if (ticket.Number() != EMPTY)
        {
            ticket.Close();
        }

        ticket.SetNewTicket(EMPTY);
        reset = false;
    }

    if (ticket.Number() == EMPTY && mbNumber != EMPTY && !MBT.MBIsMostRecent(mbNumber))
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
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
    else
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
            }
        }

        mbNumber = tempMBState.Number();
        setupType = tempMBState.Type();
    }

    if (ticket.Number() == EMPTY && mbNumber != EMPTY)
    {
        int ticketNumber;
        int error = OrderHelper::PlaceStopOrderForPendingMBValidation(PaddingPips, SpreadPips, RiskPercent, MagicNumber, mbNumber, MBT, ticketNumber);
        if (error != ERR_NO_ERROR)
        {
            reset = true;
            return error;
        }

        ticket.SetNewTicket(ticketNumber);
        int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            reset = true;
            return selectError;
        }

        stopLoss = OrderStopLoss();
        entryPrice = OrderOpenPrice();
    }
    else if (ticket.Number() != EMPTY)
    {
        bool isActive;
        int isActiveError = ticket.IsActive(isActive);
        if (!isActive)
        {
            OrderHelper::CheckEditStopLossForStopOrderOnPendingMB(PaddingPips, SpreadPips, RiskPercent, mbNumber, MBT, ticket);
        }

        // This is here just to catch if the order has been closed and reset if it has
        int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
        if (selectError != ERR_NO_ERROR)
        {
            reset = true;
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        stopLoss = OrderStopLoss();
    }

    return ERR_NO_ERROR;
}

int CheckSetup(int type, Ticket *&ticket, int mbNumber, int setupType, double stopLoss,
               bool shouldBePendingOrder, bool useNewStopLossShouldBeEqual, bool newStopLossShouldBeEqual, bool shouldHaveSameTypeMBs)
{
    bool isActive;
    int isActiveError = ticket.IsActive(isActive);
    if (isActiveError != ERR_NO_ERROR)
    {
        return isActiveError;
    }

    if ((shouldBePendingOrder && isActive) || (!shouldBePendingOrder && !isActive))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    if (useNewStopLossShouldBeEqual)
    {
        if (tempMBState.Number() <= mbNumber)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        int selectError = ticket.SelectIfOpen("Getting Stop Loss");
        if (selectError != ERR_NO_ERROR)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        double newStopLoss;
        if (tempMBState.Type() == OP_BUY)
        {
            newStopLoss = MathMin(
                OrderOpenPrice(), MathMax(
                                      stopLoss, iLow(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.LowIndex()) - OrderHelper::PipsToRange(PaddingPips)));
        }
        else if (tempMBState.Type() == OP_SELL)
        {
            newStopLoss = MathMax(
                OrderOpenPrice(), MathMin(
                                      stopLoss, iHigh(tempMBState.Symbol(), tempMBState.TimeFrame(), tempMBState.HighIndex()) + OrderHelper::PipsToRange(PaddingPips) + OrderHelper::PipsToRange(SpreadPips)));
        }

        if ((newStopLossShouldBeEqual && newStopLoss != stopLoss) || (!newStopLossShouldBeEqual && newStopLoss == stopLoss))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }
    }

    if (!shouldBePendingOrder)
    {
        if (tempMBState.Number() <= mbNumber)
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }

        if ((shouldHaveSameTypeMBs && tempMBState.Type() != setupType) || (!shouldHaveSameTypeMBs && tempMBState.Type() == setupType))
        {
            return Results::UNIT_TEST_DID_NOT_RUN;
        }
    }

    return ERR_NO_ERROR;
}

int BullishNoErrorsSameStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_BUY;

    static Ticket *ticket = new Ticket(EMPTY);
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

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, true, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    if (trailError != ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() == stopLoss;

    if (OrderStopLoss() == OrderOpenPrice())
    {
        reset = true;
    }

    return Results::UNIT_TEST_RAN;
}

int BearishNoErrorsSameStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_SELL;

    static Ticket *ticket = new Ticket(EMPTY);
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

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, true, true);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    if (trailError != ExecutionErrors::NEW_STOPLOSS_EQUALS_OLD)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() == stopLoss;

    if (OrderStopLoss() == OrderOpenPrice())
    {
        reset = true;
    }
    return Results::UNIT_TEST_RAN;
}

int BullishNoErrorsDifferentStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_BUY;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    if (TerminalErrors::IsTerminalError(trailError))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() != stopLoss;
    stopLoss = OrderStopLoss();

    if (OrderStopLoss() == OrderOpenPrice())
    {
        reset = true;
    }
    return Results::UNIT_TEST_RAN;
}

int BearishNoErrorsDifferentStopLoss(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_SELL;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    if (TerminalErrors::IsTerminalError(trailError))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() != stopLoss;
    stopLoss = OrderStopLoss();

    if (OrderStopLoss() == OrderOpenPrice())
    {
        reset = true;
    }
    return Results::UNIT_TEST_RAN;
}

int DoesNotTrailPendingOrders(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    const int type = OP_BUY;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    ut.PendingRecord.AdditionalInformation = "Ticket: " + ticket.Number() + " MB: " + mbNumber + " Setup Type: " + setupType + " SL: " + stopLoss + " Entry: " + entryPrice;

    int setVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setVariablesError != ERR_NO_ERROR)
    {
        return setVariablesError;
    }

    ut.PendingRecord.AdditionalInformation += " Made it past Variables";

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, true, false, false, false);
    if (setupError != ERR_NO_ERROR)
    {
        return setupError;
    }

    ut.PendingRecord.AdditionalInformation += " Made it past Check Setup";

    bool isActive;
    int isActiveError = ticket.IsActive(isActive);
    if (isActiveError != ERR_NO_ERROR)
    {
        return isActiveError;
    }

    if (isActive)
    {
        reset = true;
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation += " Made it past isActive";

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;

    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    reset = true;
    return Results::UNIT_TEST_RAN;
}

int BullishDoesNotTrailPastOpen(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_BUY;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    if (TerminalErrors::IsTerminalError(trailError))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() <= OrderOpenPrice();
    stopLoss = OrderStopLoss();

    if (OrderStopLoss() == OrderOpenPrice())
    {
        reset = true;
    }

    return Results::UNIT_TEST_RAN;
}

int BearishDoesNotTrailPastOpen(BoolUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, bool &actual)
{
    const int type = OP_SELL;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, true, false, true);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    int trailError = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    if (TerminalErrors::IsTerminalError(trailError))
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int selectError = ticket.SelectIfOpen("Testing trailing stop losss");
    if (selectError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = OrderStopLoss() >= OrderOpenPrice();
    stopLoss = OrderStopLoss();

    if (OrderStopLoss() == OrderOpenPrice())
    {
        reset = true;
    }

    return Results::UNIT_TEST_RAN;
}

int SubsequentMBDoesNotExist(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    static Ticket *ticket = new Ticket(EMPTY);

    int ticketNumber = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Ask - OrderHelper::PipsToRange(200), 0.0, NULL, 0, 0, clrNONE);
    if (ticketNumber < 0)
    {
        return GetLastError();
    }

    ticket.SetNewTicket(ticketNumber);

    MBState *tempMBState;
    if (!MBT.GetNthMostRecentMB(0, tempMBState))
    {
        return TerminalErrors::MB_DOES_NOT_EXIST;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory());

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, tempMBState.Number(), tempMBState.Type(), MBT, ticket, succeeded);

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    int error = ticket.Close();
    if (error != ERR_NO_ERROR)
    {
        return error;
    }

    return Results::UNIT_TEST_RAN;
}

int BullishNotEqualTypesError(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    const int type = OP_BUY;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    ut.PendingRecord.AdditionalInformation = "Ticket: " + ticket.Number() + " MB: " + mbNumber + " StopLoss: " + stopLoss + " EntryPrice: " + entryPrice;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, false, false);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    reset = true;

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return Results::UNIT_TEST_RAN;
}

int BearishNotEqualTypesError(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    const int type = OP_SELL;

    static Ticket *ticket = new Ticket(EMPTY);
    static int mbNumber = -1;
    static int setupType = -1;
    static double stopLoss = 0.0;
    static double entryPrice = 0.0;
    static bool reset = false;

    int setupVariablesError = SetSetupVariables(type, ticket, mbNumber, setupType, stopLoss, entryPrice, reset);
    if (setupVariablesError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    int setupError = CheckSetup(type, ticket, mbNumber, setupType, stopLoss, false, false, false, false);
    if (setupError != ERR_NO_ERROR)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool succeeded = false;
    actual = OrderHelper::CheckTrailStopLossWithMBUpToBreakEven(PaddingPips, SpreadPips, mbNumber, setupType, MBT, ticket, succeeded);
    reset = true;

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory());

    return Results::UNIT_TEST_RAN;
}