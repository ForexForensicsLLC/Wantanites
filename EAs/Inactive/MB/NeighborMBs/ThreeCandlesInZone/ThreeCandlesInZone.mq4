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
#include <Wantanites/EAs/Inactive/NeighborMBs/ThreeCandlesInZone/ThreeCandlesInZone.mqh>

// --- EA Inputs ---
double RiskPercent = 0.01;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "NeighborMBs/";
string EAName = "Dow/";
string SetupTypeName = "ThreeCandlesInZone/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

NeighborMBs *NMBsBuys;
NeighborMBs *NMBsSells;

// Dow
double MinMBHeight = 900;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

// Nas
// double MinMBHeight = 200;
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 350;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 150;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    NMBsBuys = new NeighborMBs(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                               ExitWriter, ErrorWriter, SetupMBT);

    NMBsBuys.SetPartialCSVRecordWriter(PartialWriter);
    NMBsBuys.AddPartial(CloseRR, 100);

    NMBsBuys.mMinMBHeight = MinMBHeight;
    NMBsBuys.mEntryPaddingPips = EntryPaddingPips;
    NMBsBuys.mMinStopLossPips = MinStopLossPips;
    NMBsBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBsBuys.mBEAdditionalPips = BEAdditionalPips;

    NMBsBuys.AddTradingSession(16, 30, 19, 0);

    NMBsSells = new NeighborMBs(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter, SetupMBT);
    NMBsSells.SetPartialCSVRecordWriter(PartialWriter);
    NMBsSells.AddPartial(CloseRR, 100);

    NMBsSells.mMinMBHeight = MinMBHeight;
    NMBsSells.mEntryPaddingPips = EntryPaddingPips;
    NMBsSells.mMinStopLossPips = MinStopLossPips;
    NMBsSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NMBsSells.mBEAdditionalPips = BEAdditionalPips;

    NMBsSells.AddTradingSession(16, 30, 19, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete NMBsBuys;
    delete NMBsSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NMBsBuys.Run();
    NMBsSells.Run();
}
