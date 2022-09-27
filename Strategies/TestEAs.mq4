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
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.25;
input int MaxCurrentSetupTradesAtOnce = 1;
input int MaxTradesPerDay = 5;
input double MaxSpreadPips = 0.3;

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 1;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = false;

int SetupType = OP_BUY;

CSVRecordWriter<MultiTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MultiTimeFrameEntryTradeRecord>("Test/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("Test/Partials/", "Partials.csv");
CSVRecordWriter<MultiTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<MultiTimeFrameExitTradeRecord>("Test/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("Test/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

TestEA *TEA;

LiquidationSetupTracker *LiquidationSetup;
LiquidationSetupTracker *LiquidationConfirmation;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 60, MBsToTrack, 1, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 300, 1, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

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
