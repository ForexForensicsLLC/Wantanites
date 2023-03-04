//+------------------------------------------------------------------+
//|                                                       Manage.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <Wantanites\Framework\Constants\Index.mqh>

#include <Wantanites\Framework\Trackers\MBTracker.mqh>
#include <Wantanites\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <Wantanites\Framework\Helpers\SetupHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\BeforeAndAfterImagesUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/Manage/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 0;
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
input const int MaxSpreadPips = 1;
const double RiskPercent = 0.25;

IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *EmptyTicketStateUnitTest;

IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CheckingToEditStopLossStateUnitTest;
IntUnitTest<BeforeAndAfterImagesUnitTestRecord> *CheckingToTrailStopLossStateUnitTest;

int OnInit()
{
    EmptyTicketStateUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Empty Ticket State", "Should Return ATTEMPTING TO MANAGE ORDER state",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        EAStates::ATTEMPTING_TO_MANAGE_ORDER, EmptyTicketState);

    CheckingToEditStopLossStateUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
        Directory, "Checking To Edit Stop Loss State", "Should Return CHECKING TO EDIT STOP LOSS state",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        EAStates::CHECKING_TO_EDIT_STOP_LOSS, CheckingToEditStopLossState);

    CheckingToTrailStopLossStateUnitTest = new IntUnitTest<BeforeAndAfterImagesUnitTestRecord>(
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
    if (MRFTS.HadMinROC() && TSSSMB.IsDoneTrading())
    {
        Reset();
    }

    TSSSMB.Run();

    EmptyTicketStateUnitTest.Assert();

    // https://drive.google.com/drive/folders/1A_quaQVCoTKTveeswpqZki0k8SyFVbYn?usp=sharing
    CheckingToEditStopLossStateUnitTest.Assert();

    // https://drive.google.com/drive/folders/1vawcBLyGZFGEh-1Uuty-OQgCziEFCMA9?usp=sharing
    CheckingToTrailStopLossStateUnitTest.Assert();
}

void Reset()
{
    delete TSSSMB;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.10);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int EmptyTicketState(int &actual)
{
    if (TSSSMB.TicketNumber() != EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    TSSSMB.Manage();
    actual = TSSSMB.GetLastState();

    return Results::UNIT_TEST_RAN;
}

int CheckingToEditStopLossState(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    Ticket *ticket;
    TSSSMB.Ticket(ticket);
    static int count = 0;

    if (ticket.Number() == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool isActive = false;
    int isActiveError = ticket.IsActive(isActive);
    if (isActiveError != ERR_NO_ERROR)
    {
        return isActiveError;
    }

    if (isActive)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    TSSSMB.Manage();
    actual = TSSSMB.GetLastState();
    count += 1;

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), "_" + IntegerToString(count));

    return Results::UNIT_TEST_RAN;
}

int CheckingToTrailStopLossState(IntUnitTest<BeforeAndAfterImagesUnitTestRecord> &ut, int &actual)
{
    Ticket *ticket;
    TSSSMB.Ticket(ticket);
    static int count = 0;

    if (ticket.Number() == EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    bool isActive = false;
    int isActiveError = ticket.IsActive(isActive);
    if (isActiveError != ERR_NO_ERROR)
    {
        return isActiveError;
    }

    if (!isActive)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.BeforeImage = ScreenShotHelper::TryTakeBeforeScreenShot(ut.Directory(), "_" + IntegerToString(count));

    TSSSMB.Manage();
    actual = TSSSMB.GetLastState();
    count += 1;

    ut.PendingRecord.AfterImage = ScreenShotHelper::TryTakeAfterScreenShot(ut.Directory(), "_" + IntegerToString(count));

    return Results::UNIT_TEST_RAN;
}
