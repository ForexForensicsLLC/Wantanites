//+------------------------------------------------------------------+
//|                                            TheSunriseShatter.mq4 |
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

// --- EA Inputs ---
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.25;
input int MaxTradesPerStrategy = 1;
input int MaxSpreadPips = 10;

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

// --- Min ROC. Inputs ---
input int ServerHourStartTime = 16;
input int ServerMinuteStartTime = 30;
input int ServerHourEndTime = 16;
input int ServerMinuteEndTime = 33;
input double MinROCPercent = 0.17;

MBTracker *MBT;
MinROCFromTimeStamp *MRFTS;

TheSunriseShatterSingleMB *TSSSMB;
TheSunriseShatterDoubleMB *TSSDMB;
TheSunriseShatterLiquidationMB *TSSLMB;

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), ServerHourStartTime, ServerHourEndTime, ServerMinuteStartTime, ServerMinuteEndTime, MinROCPercent);

    TSSSMB = new TheSunriseShatterSingleMB(Period(), MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
    TSSDMB = new TheSunriseShatterDoubleMB(Period(), MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);
    TSSLMB = new TheSunriseShatterLiquidationMB(Period(), MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, MRFTS, MBT);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TSSSMB;
    delete TSSDMB;
    delete TSSLMB;
}

void OnTick()
{
    TSSSMB.Run();
    TSSDMB.Run();
    TSSLMB.Run();
}
