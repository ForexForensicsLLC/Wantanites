//+------------------------------------------------------------------+
//|                                                BullishKatara.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#include <SummitCapital/EAs/Katara/KataraSingleMB.mqh>
#include <SummitCapital/EAs/Katara/KataraDoubleMB.mqh>
#include <SummitCapital/EAs/Katara/KataraLiquidationMB.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.25;
input int MaxTradesPerStrategy = 1;
input double MaxSpreadPips = 3; // TODO: Put back to 0.3

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

int SetupType = OP_BUY;

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

KataraSingleMB *KSMB;
KataraDoubleMB *KDMB;
KataraLiquidationMB *KLMB;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    KSMB = new KataraSingleMB("Katara/BullishKataraSingleMB/", SetupType, MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, SetupMBT, ConfirmationMBT);
    KDMB = new KataraDoubleMB("Katar/BullishKatarDoubleMB/", SetupType, MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, SetupMBT, ConfirmationMBT);
    KLMB = new KataraLiquidationMB("Kara/BullishKataraLiquidationMB/", SetupType, MaxTradesPerStrategy, StopLossPaddingPips, MaxSpreadPips, RiskPercent, SetupMBT, ConfirmationMBT);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete KSMB;
    delete KDMB;
    delete KLMB;
}

void OnTick()
{
    KSMB.Run();
    KDMB.Run();
    KLMB.Run();
}
