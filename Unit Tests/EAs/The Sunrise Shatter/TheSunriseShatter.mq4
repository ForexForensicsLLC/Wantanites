//+------------------------------------------------------------------+
//|                                            TheSunriseShatter.mq4 |
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

#include <WantaCapital\Framework\UnitTests\BoolUnitTest.mqh>

#include <WantaCapital\Framework\CSVWriting\CSVRecordTypes\UnitTestRecords\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/EAs/The Sunrise Shatter/Tests/";
const int NumberOfAsserts = 50;
const int AssertCooldown = 0;
const bool RecordErrors = true;

MBTracker *MBT;
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

MinROCFromTimeStamp *MRFTS;

TheSunriseShatterSingleMB *TSSSMB;
TheSunriseShatterDoubleMB *TSSDMB;
TheSunriseShatterLiquidationMB *TSSLMB;

const int MaxTradesPerStrategy = 1;
const int StopLossPaddingPips = 0;
input const int MaxSpreadPips = 70;
const double RiskPercent = 0.25;

BoolUnitTest<DefaultUnitTestRecord> *TSSSMBHasTicketUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *TSSDMBHasTicketUnitTest;
BoolUnitTest<DefaultUnitTestRecord> *TSSLMBHasTicketUnitTest;

int OnInit()
{
    TSSSMBHasTicketUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "TSSSMB Has Ticket", "True if Ticket is not empty",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, TSSSMBHasTicket);

    TSSDMBHasTicketUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "TSSDMB Has Ticket", "True if Ticket is not empty",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, TSSDMBHasTicket);

    TSSLMBHasTicketUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "TSSLMB Has Ticket", "True if Ticket is not empty",
        NumberOfAsserts, AssertCooldown, RecordErrors,
        true, TSSLMBHasTicket);

    Reset();
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TSSSMBHasTicketUnitTest;
    delete TSSDMBHasTicketUnitTest;
    delete TSSLMBHasTicketUnitTest;
}

void OnTick()
{
    if (MRFTS.OpenPrice() == 0.0 || (TSSSMB.mStopTrading && TSSDMB.mStopTrading && TSSLMB.mStopTrading))
    {
        Reset();
    }

    TSSSMB.Run();
    TSSSMBHasTicketUnitTest.Assert();

    TSSDMB.Run();
    TSSDMBHasTicketUnitTest.Assert();

    TSSLMB.Run();
    TSSLMBHasTicketUnitTest.Assert();
}

void Reset()
{
    delete TSSSMB;
    delete TSSDMB;
    delete TSSLMB;

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, true, PrintErrors, CalculateOnTick);

    int endHour = Minute() + 10 > 59 ? Hour() + 1 : Hour();
    int endMinute = Minute() + 10 > 59 ? 10 - (59 - Minute()) : Minute() + 10;

    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), Hour(), endHour, Minute(), endMinute, 0.05);

    TSSSMB = new TheSunriseShatterSingleMB(Period(), MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
    TSSDMB = new TheSunriseShatterDoubleMB(Period(), MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
    TSSLMB = new TheSunriseShatterLiquidationMB(Period(), MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
}

int TSSSMBHasTicket(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    static bool prevHadTicket = false;

    if (TSSSMB.mTicket.Number() == EMPTY && !prevHadTicket)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Ticket Number: " + IntegerToString(TSSSMB.mTicket.Number()) +
                                             " Has Confirmation: " + TSSSMB.Confirmation() +
                                             " Has Setup: " + TSSSMB.mHasSetup +
                                             " Stop Trading: " + TSSSMB.mStopTrading;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), IntegerToString(count));

    count += 1;
    actual = true;
    prevHadTicket = TSSDMB.mTicket.Number() != EMPTY;

    return Results::UNIT_TEST_RAN;
}

int TSSDMBHasTicket(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    static bool prevHadTicket = false;

    if (TSSDMB.mTicket.Number() == EMPTY && !prevHadTicket)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Ticket Number: " + IntegerToString(TSSDMB.mTicket.Number()) +
                                             " Has Confirmation: " + TSSDMB.Confirmation() +
                                             " Has Setup: " + TSSDMB.mHasSetup +
                                             " Stop Trading: " + TSSDMB.mStopTrading;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), IntegerToString(count));

    count += 1;
    actual = true;
    prevHadTicket = TSSDMB.mTicket.Number() != EMPTY;

    return Results::UNIT_TEST_RAN;
}

int TSSLMBHasTicket(BoolUnitTest<DefaultUnitTestRecord> &ut, bool &actual)
{
    static int count = 0;
    static bool prevHadTicket = false;

    if (TSSLMB.mTicket.Number() == EMPTY && !prevHadTicket)
    {
        return Results::UNIT_TEST_DID_NOT_RUN;
    }

    ut.PendingRecord.AdditionalInformation = "Ticket Number: " + IntegerToString(TSSLMB.mTicket.Number()) +
                                             " Has Confirmation: " + TSSLMB.Confirmation() +
                                             " Has Setup: " + TSSLMB.mHasSetup +
                                             " Stop Trading: " + TSSLMB.mStopTrading;

    ut.PendingRecord.Image = ScreenShotHelper::TryTakeScreenShot(ut.Directory(), IntegerToString(count));

    count += 1;
    actual = true;
    prevHadTicket = TSSLMB.mTicket.Number() != EMPTY;

    return Results::UNIT_TEST_RAN;
}
