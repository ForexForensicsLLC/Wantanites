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
#include <Wantanites/EAs/Inactive/5minMBSetup/FastSetup/ZoneExit/ZoneExit.mqh>

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

string StrategyName = "5MinMBSetup/";
string EAName = "Nas/";
string SetupTypeName = "ZoneExit/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

ZoneExit *ZEBuys;
ZoneExit *ZESells;

// Dow - 5min
double MinValidationPercentChange = 0.25;
double MinMBHeight = 900;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 2000;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 2;

// Nas - No go
// double MinValidationPercentChange = 0.25;
// double MinMBHeight = 600;
// double MaxSpreadPips = SymbolConstants::NasSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 0;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 2000;
// double BEAdditionalPips = SymbolConstants::NasSlippagePips;
// double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    ZEBuys = new ZoneExit(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, SetupMBT);

    ZEBuys.SetPartialCSVRecordWriter(PartialWriter);
    ZEBuys.AddPartial(CloseRR, 100);

    ZEBuys.mMinValidationPercentChange = MinValidationPercentChange;
    ZEBuys.mMinMBHeight = MinMBHeight;
    ZEBuys.mEntryPaddingPips = EntryPaddingPips;
    ZEBuys.mMinStopLossPips = MinStopLossPips;
    ZEBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ZEBuys.mBEAdditionalPips = BEAdditionalPips;

    ZEBuys.AddTradingSession(16, 30, 23, 0);

    ZESells = new ZoneExit(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, SetupMBT);
    ZESells.SetPartialCSVRecordWriter(PartialWriter);
    ZESells.AddPartial(CloseRR, 100);

    ZESells.mMinValidationPercentChange = MinValidationPercentChange;
    ZESells.mMinMBHeight = MinMBHeight;
    ZESells.mEntryPaddingPips = EntryPaddingPips;
    ZESells.mMinStopLossPips = MinStopLossPips;
    ZESells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ZESells.mBEAdditionalPips = BEAdditionalPips;

    ZESells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete ZEBuys;
    delete ZESells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    ZEBuys.Run();
    ZESells.Run();
}
