//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/MBCluster/MBCluster.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "MBCluster/";
string EAName = "S&P/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MBCluster *MBClusterBuys;
MBCluster *MBClusterSells;

// Nas
// double MaxSpreadPips = SymbolConstants::NasSpreadPips;
// double EntryPaddingPips = 20;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = SymbolConstants::NasSlippagePips;
// double CloseRR = 1000;

// Dow
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 20;
// double MinStopLossPips = 350;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 1000;

// S&P;
double MaxSpreadPips = SymbolConstants::SPXSpreadPips;
double EntryPaddingPips = 5;
double MinStopLossPips = 20;
double StopLossPaddingPips = 10;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = SymbolConstants::SPXSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    MBClusterBuys = new MBCluster(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, SetupMBT);

    MBClusterBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBClusterBuys.AddPartial(CloseRR, 100);

    MBClusterBuys.mEntryPaddingPips = EntryPaddingPips;
    MBClusterBuys.mMinStopLossPips = MinStopLossPips;
    MBClusterBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBClusterBuys.mBEAdditionalPips = BEAdditionalPips;

    MBClusterBuys.AddTradingSession(16, 30, 23, 0);

    MBClusterSells = new MBCluster(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter, SetupMBT);
    MBClusterSells.SetPartialCSVRecordWriter(PartialWriter);
    MBClusterSells.AddPartial(CloseRR, 100);

    MBClusterSells.mEntryPaddingPips = EntryPaddingPips;
    MBClusterSells.mMinStopLossPips = MinStopLossPips;
    MBClusterSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBClusterSells.mBEAdditionalPips = BEAdditionalPips;

    MBClusterSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MBClusterBuys;
    delete MBClusterSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBClusterBuys.Run();
    MBClusterSells.Run();
}
