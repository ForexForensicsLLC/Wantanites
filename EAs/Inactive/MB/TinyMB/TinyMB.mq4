//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Inactive/TinyMB/TinyMB.mqh>

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "TinyMB/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

TinyMB *TMBBuys;
TinyMB *TMBSells;

// Dow
double MaxMBHeight = 1000;
double MinMBGap = 100;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 350;
double StopLossPaddingPips = 100;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TMBBuys = new TinyMB(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                         ExitWriter, ErrorWriter, SetupMBT);

    TMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    TMBBuys.AddPartial(CloseRR, 100);

    TMBBuys.mMaxMBHeight = MaxMBHeight;
    TMBBuys.mMinMBGap = MinMBGap;
    TMBBuys.mEntryPaddingPips = EntryPaddingPips;
    TMBBuys.mMinStopLossPips = MinStopLossPips;
    TMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBBuys.mBEAdditionalPips = BEAdditionalPips;

    TMBBuys.AddTradingSession(16, 30, 23, 0);

    TMBSells = new TinyMB(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, SetupMBT);
    TMBSells.SetPartialCSVRecordWriter(PartialWriter);
    TMBSells.AddPartial(CloseRR, 100);

    TMBSells.mMaxMBHeight = MaxMBHeight;
    TMBSells.mMinMBGap = MinMBGap;
    TMBSells.mEntryPaddingPips = EntryPaddingPips;
    TMBSells.mMinStopLossPips = MinStopLossPips;
    TMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBSells.mBEAdditionalPips = BEAdditionalPips;

    TMBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TMBBuys;
    delete TMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TMBBuys.Run();
    TMBSells.Run();
}
