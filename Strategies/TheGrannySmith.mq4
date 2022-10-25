//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/TheGrannySmith.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.25;
input int MaxCurrentSetupTradesAtOnce = 1;
input int MaxTradesPerDay = 5;
input double MaxSpreadPips = 10;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>("TheGrannySmith/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TheGrannySmith/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("TheGrannySmith/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TheGrannySmith/Errors/", "Errors.csv");

MBTracker *SetupMBT;
TheGrannySmith *AppleBuys;
TheGrannySmith *AppleSells;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    AppleBuys = new TheGrannySmith(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, 10, RiskPercent, EntryWriter, ExitWriter,
                                   ErrorWriter, SetupMBT);
    AppleBuys.SetPartialCSVRecordWriter(PartialWriter);
    AppleBuys.AddPartial(1000, 100);

    AppleBuys.AddTradingSession(16, 0, 23, 0);

    AppleSells = new TheGrannySmith(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, 10, RiskPercent, EntryWriter, ExitWriter,
                                    ErrorWriter, SetupMBT);
    AppleSells.SetPartialCSVRecordWriter(PartialWriter);
    AppleSells.AddPartial(1000, 100);

    AppleSells.AddTradingSession(16, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete AppleBuys;
    delete AppleSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    AppleBuys.Run();
    AppleSells.Run();
}
