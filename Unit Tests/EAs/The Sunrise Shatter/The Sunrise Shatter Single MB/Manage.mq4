//+------------------------------------------------------------------+
//|                                                       Manage.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <SummitCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <SummitCapital\Framework\Constants\Index.mqh>

#include <SummitCapital\Framework\Trackers\MBTracker.mqh>
#include <SummitCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <SummitCapital\Framework\Helpers\SetupHelper.mqh>
#include <SummitCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <SummitCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/Manage/";
const int NumberOfAsserts = 1;
const int AssertCooldown = 1;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MinROCFromTimeStamp *MRFTS;

TheSunriseShatterSingleMB *TSSSMB;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
const int MaxSpreadPips = 70;
const double RiskPercent = 0.25;

IntUnitTest<DefaultUnitTestRecord> *EmptyTicketStateUnitTest;

IntUnitTest<DefaultUnitTestRecord> *CheckingToEditStopLossStateUnitTest;
IntUnitTest<DefaultUnitTestRecord> *CheckingToTrailStopLossStateUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    EmptyTicketLastStateUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Empty Ticket State", "Should Return ATTEMPTING TO MANAGE ORDER state",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        EAStates::ATTEMPTING_TO_MANAGE_ORDER, EmptyTicketState);

    CheckingToEditStopLossStateUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Checking To Edit Stop Loss State", "Should Return CHECKING TO EDIT STOP LOSS state",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        EAStates::CHECKING_TO_EDIT_STOP_LOSS, CheckingToEditStopLossState);

    CheckingToTrailStopLossStateUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "Checking To Trail Stop Loss State", "Should Return CHECKING TO Trail STOP LOSS state",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        EAStates::CHECKING_TO_TRAIL_STOP_LOSS, CheckingToTrailStopLossState);

    Reset();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete EmptyTicketStateUnitTest;

    delete CheckingToEditStopLossStateUnitTest;
    delete CheckingToTrailStopLossStateUnitTest;
}

void OnTick()
{
    if (MRFTS.HasMinROC() && TSSSMB.StopTrading())
    {
        Reset();
    }

    TSSSMB.Run();

    EmptyTicketStateUnitTest.Assert();

    CheckingToEditStopLossStateUnitTest.Assert();
    CheckingToTrailStopLossStateUnitTest.Assert();
}

void Reset()
{
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.05);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int EmptyTicketState(int &actual)
{
    if (TSSSMB.MBStopOrderTicket() != EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    TSSSMB.Manage();
    actual = TSSSMB.GetLastState();

    return Results::UNIT_TEST_RAN;
}

int CheckingToEditStopLossState(int &actual)
{
    if (TSSSMB.MBStopOrderTicket() == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool isPendingOrder = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(TSSSMB.MBStopOrderTicket(), isPendingOrder);
    if (pendingOrderError != ERR_NO_ERROR)
    {
        return pendingOrderError;
    }

    if (!isPendingOrder)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    TSSSMB.Manage();
    actual = TSSSMB.GetLastState();

    return Results::UNIT_TEST_RAN;
}

int CheckingToTrailStopLossState(int &actual)
{
    if (TSSSMB.MBStopOrderTicket() == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool isPendingOrder = false;
    int pendingOrderError = OrderHelper::IsPendingOrder(TSSSMB.MBStopOrderTicket(), isPendingOrder);
    if (pendingOrderError != ERR_NO_ERROR)
    {
        return pendingOrderError;
    }

    if (isPendingOrder)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    TSSSMB.Manage();
    actual = TSSSMB.GetLastState();

    return Results::UNIT_TEST_RAN;
}
