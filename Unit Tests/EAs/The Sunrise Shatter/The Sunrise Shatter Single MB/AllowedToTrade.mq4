//+------------------------------------------------------------------+
//|                                               AllowedToTrade.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <WantaCapital\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <WantaCapital\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

#include <WantaCapital\Framework\Constants\Index.mqh>

#include <WantaCapital\Framework\Trackers\MBTracker.mqh>
#include <WantaCapital\Framework\Objects\MinROCFromTimeStamp.mqh>

#include <WantaCapital\Framework\Helpers\SetupHelper.mqh>
#include <WantaCapital\Framework\UnitTests\IntUnitTest.mqh>
#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/The Sunrise Shatter Single MB/AllowedToTrade/";
const int NumberOfAsserts = 25;
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

// https://drive.google.com/drive/folders/1OHTHHN7kg9Gy_EHPPpJcWmD9nDGW8_fm?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *AllowedToTradeUnitTest;

// https://drive.google.com/drive/folders/1zfXL9OC0r3Nax3lMjyX-I-4JlNvOJfxv?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *TooMuchSpreadUnitTest;

int OnInit()
{
    AllowedToTradeUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Allowed To Trade", "Should return true indicating the ea is allowed to trade",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, AllowedToTrade);

    TooMuchSpreadUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Too Much Spread", "Should Return False indicating that the ea cant trade due to too much spread",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        false, TooMuchSpread);

    Reset();

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete MRFTS;
    delete TSSSMB;

    delete AllowedToTradeUnitTest;
    delete TooMuchSpreadUnitTest;
}

void OnTick()
{
    if (MRFTS.HadMinROC() && TSSSMB.IsDoneTrading())
    {
        Reset();
    }

    TSSSMB.Run();

    // AllowedToTradeUnitTest.Assert();
    TooMuchSpreadUnitTest.Assert();
}

void Reset()
{
    delete TSSSMB;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), 23, Minute(), Minute() + 1, 0.05);
    TSSSMB = new TheSunriseShatterSingleMB(MaxTradesPerStrategy, StopLossPaddingPips, 5, RiskPercent, MRFTS, MBT);
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

int TooMuchSpread(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    if (MRFTS.OpenPrice() == 0.0)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    actual = TSSSMB.AllowedToTrade();
    return Results::UNIT_TEST_RAN;
}
