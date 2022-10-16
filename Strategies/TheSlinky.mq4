//+------------------------------------------------------------------+
//|                                                    TheSlinky.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/TheSlinky.mqh>

// --- EA Inputs ---
double StopLossPaddingPips = 0;
double RiskPercent = 0.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 0.3;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = false;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

int SetupType = OP_SELL;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("TheSlinky/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TheSlinky/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("TheSlinky/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TheSlinky/Errors/", "Errors.csv");

MBTracker *SetupMBT;
TheSlinky *slinkz;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    slinkz = new TheSlinky(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                           ErrorWriter, SetupMBT);

    slinkz.SetPartialCSVRecordWriter(PartialWriter);
    slinkz.AddPartial(1000, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete slinkz;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    slinkz.Run();
}
