//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/TinyMBs/TinyMBBreak.mqh>

// --- EA Inputs ---
// double StopLossPaddingPips = 0;
double RiskPercent = 0.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 10;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>("TinyMBBreak/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("TinyMBBreak/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("TinyMBBreak/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("TinyMBBreak/Errors/", "Errors.csv");

MBTracker *SetupMBT;
TinyMBBreak *TMBBBuys;
TinyMBBreak *TMBBSells;

// Nas
// double StopLossPaddingPips = 50;
// double MaxMBHeightPips = 150;
// double PipsToWaitBeforeBE = 200;
// double BEAdditionalPips = 50;

// Dow
double StopLossPaddingPips = 200;
double MaxMBHeightPips = 500;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = 200;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    TMBBBuys = new TinyMBBreak(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                               ErrorWriter, SetupMBT);
    TMBBBuys.SetPartialCSVRecordWriter(PartialWriter);
    TMBBBuys.AddPartial(1000, 100);

    TMBBBuys.mMaxMBHeightPips = MaxMBHeightPips;
    TMBBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBBBuys.mBEAdditionalPips = BEAdditionalPips;

    TMBBBuys.AddTradingSession(16, 30, 23, 0);

    TMBBSells = new TinyMBBreak(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                ErrorWriter, SetupMBT);
    TMBBSells.SetPartialCSVRecordWriter(PartialWriter);
    TMBBSells.AddPartial(1000, 100);

    TMBBSells.mMaxMBHeightPips = MaxMBHeightPips;
    TMBBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBBSells.mBEAdditionalPips = BEAdditionalPips;

    TMBBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TMBBBuys;
    delete TMBBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TMBBBuys.Run();
    TMBBSells.Run();
}
