//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Inactive/5minMBSetup/LoneDoji/LoneDoji.mqh>

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "5MinMBSetup/";
string EAName = "Dow/";
string SetupTypeName = "LoneDoji/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

LoneDoji *LDBuys;
LoneDoji *LDSells;

// Dow
// double MinMBHeight = 900;
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 0;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 1000;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 10;

// Nas
double MinMBHeight = 200;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 150;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    LDBuys = new LoneDoji(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, SetupMBT);

    LDBuys.SetPartialCSVRecordWriter(PartialWriter);
    LDBuys.AddPartial(CloseRR, 100);

    LDBuys.mMinMBHeight = MinMBHeight;
    LDBuys.mEntryPaddingPips = EntryPaddingPips;
    LDBuys.mMinStopLossPips = MinStopLossPips;
    LDBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LDBuys.mBEAdditionalPips = BEAdditionalPips;

    LDBuys.AddTradingSession(16, 40, 23, 0);

    LDSells = new LoneDoji(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, SetupMBT);
    LDSells.SetPartialCSVRecordWriter(PartialWriter);
    LDSells.AddPartial(CloseRR, 100);

    LDSells.mMinMBHeight = MinMBHeight;
    LDSells.mEntryPaddingPips = EntryPaddingPips;
    LDSells.mMinStopLossPips = MinStopLossPips;
    LDSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LDSells.mBEAdditionalPips = BEAdditionalPips;

    LDSells.AddTradingSession(16, 40, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete LDBuys;
    delete LDSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LDBuys.Run();
    LDSells.Run();
}
