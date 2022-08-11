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

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/BreakAfterMinROC/";
const int NumberOfAsserts = 1;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
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

IntUnitTest<DefaultUnitTestRecord> *EmptyTicketErrorUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *HasPendingOrderTriedToEditStopLossUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *PendingOrderEditedStopLossUnitTest;

BoolUnitTest<DefaultUnitTestRecord> *HasActiveOrderTriedToTrailStopLossUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *StopLossTrailedUnitTest;

int OnInit()
{
    MBT = new MBTracker(MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, PrintErrors, CalculateOnTick);
    Reset();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
    if (MRFTS.HasMinROC() && TSSSMB.StopTrading())
    {
        Reset();
    }

    TSSSMB.Run();
}

void Reset()
{
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), Hour(), Minute(), 59, 0.05);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int EmptyTicketError(int &actual)
{
    if (TSSSMB.MBStopOrderTicket() != EMPTY)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = TSSSMB.Manage();
    return Results::UNIT_TEST_RAN;
}

int HasPendingOrderTriedToEditStopLoss(bool &actual)
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

    int error = TSSSMB.Manage();
    if (error == EAConstants::EDITED_STOP_LOSS || error == Errors::ERR_NEW_STOP_LOSS_EQUALS_OLD)
    {
        actual = true;
        return Results::UNIT_TEST_RAN;
    }

    return error;
}

int PednginOrderEditStopLos(bool &actual)
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

    int ticket = TSSSMB.MBStopOrderTicket();
    int error = TSSSMB.Manage();
    if (error != EAConstants::EDITED_STOP_LOSS)
    {
        return error;
    }

    actual = ticket != TSSSMB.MBStopOrderTicket();
    return UniTestConstants::UNIT_TEST_RAN;
}

int HasActiveOrderTriedToTrailStopLoss(bool &actual)
{
}