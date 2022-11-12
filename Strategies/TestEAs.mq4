//+------------------------------------------------------------------+
//|                                                      TestEAs.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/TestEA.mqh>

// --- EA Inputs ---
double StopLossPaddingPips = 0;
double RiskPercent = 0.025; // TODO: Put back
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 0.3;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

int SetupType = OP_BUY;

CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MultiTimeFrameEntryTradeRecord>("TestEA/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TestEA/Partials/", "Partials.csv");
CSVRecordWriter<MultiTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<MultiTimeFrameExitTradeRecord>("TestEA/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TestEA/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

TestEA *TEA;

LiquidationSetupTracker *LiquidationSetup;
LiquidationSetupTracker *LiquidationConfirmation;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 100, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    LiquidationSetup = new LiquidationSetupTracker(SetupType, SetupMBT);
    LiquidationConfirmation = new LiquidationSetupTracker(SetupType, ConfirmationMBT);

    TEA = new TestEA(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                     ErrorWriter, SetupMBT, ConfirmationMBT, LiquidationSetup);
    TEA.SetPartialCSVRecordWriter(PartialWriter);
    TEA.AddPartial(100000000, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TEA;

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
    TEA.Run();
}
