//+------------------------------------------------------------------+
//|                                              SmaAccDisInZoen.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Trackers/CandleStickPatternTracker.mqh>
#include <Wantanites/EAs/SMAccDistInZone.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 10;
input double RiskPercent = 0.25;
input int MaxCurrentSetupTradesAtOnce = 1;
input int MaxTradesPerDay = 5;
input double MaxSpreadPips = 10;

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

int SetupType = OP_SELL;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("SMAAccDistInZone/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("SMAAccDistInZone/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("SMAAccDistInZone/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("SMAAccDistInZone/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

CandleStickPatternTracker *CSPT;
SMAccDistInZone *SADC;

LiquidationSetupTracker *LiquidationSetup;
LiquidationSetupTracker *LiquidationConfirmation;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 15, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    CSPT = new CandleStickPatternTracker(true);
    CSPT.TrackDistribution(true);

    LiquidationSetup = new LiquidationSetupTracker(SetupType, SetupMBT);
    LiquidationConfirmation = new LiquidationSetupTracker(SetupType, ConfirmationMBT);

    SADC = new SMAccDistInZone(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                               ErrorWriter, SetupMBT, CSPT);
    SADC.SetPartialCSVRecordWriter(PartialWriter);
    SADC.AddPartial(100000000, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SADC;

    delete SetupMBT;
    delete ConfirmationMBT;

    delete LiquidationSetup;
    delete LiquidationConfirmation;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SADC.Run();
}
