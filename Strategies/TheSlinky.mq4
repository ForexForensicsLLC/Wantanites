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
double MaxSpreadPips = 10;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = false;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("TheSlinky/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TheSlinky/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("TheSlinky/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TheSlinky/Errors/", "Errors.csv");

MBTracker *SetupMBT;

TheSlinky *slinkyBuys;
TheSlinky *slinkySells;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    slinkyBuys = new TheSlinky(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                               ErrorWriter, SetupMBT);

    slinkyBuys.SetPartialCSVRecordWriter(PartialWriter);
    slinkyBuys.AddPartial(1000, 100);

    slinkySells = new TheSlinky(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                ErrorWriter, SetupMBT);

    slinkySells.SetPartialCSVRecordWriter(PartialWriter);
    slinkySells.AddPartial(1000, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete slinkyBuys;
    delete slinkySells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    slinkyBuys.Run();
    slinkySells.Run();
}
