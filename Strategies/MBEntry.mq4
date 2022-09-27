//+------------------------------------------------------------------+
//|                                                      MBEntry.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/MBEntry.mqh>

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

input int SetupType = OP_BUY;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>("MBEntry/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("MBEntry/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("MBEntry/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("MBEntry/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBEntry *MBE;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, 1, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    MBE = new MBEntry(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                      ErrorWriter, SetupMBT);
    MBE.SetPartialCSVRecordWriter(PartialWriter);
    MBE.AddPartial(100000000, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBE;
    delete SetupMBT;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBE.Run();
}
