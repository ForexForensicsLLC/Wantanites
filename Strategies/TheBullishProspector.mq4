//+------------------------------------------------------------------+
//|                                         TheBullishProspector.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/TheProspector.mqh>

// --- EA Inputs ---
double StopLossPaddingPips = 0;
double RiskPercent = 0.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 1.3;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

int SetupType = OP_BUY;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("TheBullishProspector/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TheBullishProspector/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("TheBullishProspector/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TheBullishProspector/Errors/", "Errors.csv");

MBTracker *SetupMBT;
TheProspector *StinkyPete;

int OnInit()
{
    // Should only be running on the 5 minute TF
    if (Period() != 5)
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    // Should only be running on Gold
    if (StringFind(Symbol(), "XAU") == -1)
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    StinkyPete = new TheProspector(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                   ErrorWriter, SetupMBT);

    StinkyPete.SetPartialCSVRecordWriter(PartialWriter);
    StinkyPete.AddPartial(20, 50);
    StinkyPete.AddPartial(50, 100);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete StinkyPete;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    StinkyPete.Run();
}
