//+------------------------------------------------------------------+
//|                                               AllowedToTrade.mq4 |
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

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/AllowedToTrade/";
const int NumberOfAsserts = 1;
const int AssertCooldown = 1;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 3;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MinROCFromTimeStamp *MRFTS;

TheSunriseShatterSingleMB *TSSSMB;
const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
const int MaxSpreadPips = 70;
const double RiskPercent = 0.25;

BoolUnitTest<DefaultUnitTestRecord> *AllowedToTradeUnitTest;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    AllowedToTradeUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Allowed To Trade", "Should return true, indicating the ea is allowed to trade",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, AllowedToTrade);

    Reset();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete AllowedToTradeUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSSMB.StopTrading())
    {
        Reset();
    }

    TSSSMB.Run();

    AllowedToTradeUnitTest.Assert();
}

void Reset()
{
    delete MRFTS;
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), 59, 0.05);

    delete TSSSMB;
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int AllowedToTrade(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (MRFTS.OpenPrice() == 0.0)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    if ((MarketInfo(Symbol(), MODE_SPREAD) / 10) > MaxSpreadPips)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory());

    actual = TSSSMB.AllowedToTrade();
    return Results::UNIT_TEST_RAN;
}
