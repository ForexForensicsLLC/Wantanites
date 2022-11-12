//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/InnerBreaks/LiquidationBigDipper.mqh>

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

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>("LiquidationBigDipper/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("LiquidationBigDipper/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("LiquidationBigDipper/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("LiquidationBigDipper/Errors/", "Errors.csv");

MBTracker *SetupMBT;
LiquidationBigDipper *LBDBuys;
LiquidationBigDipper *LBDSells;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    LBDBuys = new LiquidationBigDipper(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, 10, RiskPercent, EntryWriter, ExitWriter,
                                       ErrorWriter, SetupMBT);
    LBDBuys.SetPartialCSVRecordWriter(PartialWriter);
    LBDBuys.AddPartial(1000, 100);

    LBDBuys.AddTradingSession(16, 0, 23, 0);

    LBDSells = new LiquidationBigDipper(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, 10, RiskPercent, EntryWriter, ExitWriter,
                                        ErrorWriter, SetupMBT);
    LBDSells.SetPartialCSVRecordWriter(PartialWriter);
    LBDSells.AddPartial(1000, 100);

    LBDSells.AddTradingSession(16, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete LBDBuys;
    delete LBDSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LBDBuys.Run();
    LBDSells.Run();
}
