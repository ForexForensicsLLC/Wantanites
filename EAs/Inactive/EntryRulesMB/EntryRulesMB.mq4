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
#include <SummitCapital/EAs/Inactive/EntryRulesMB/EntryRulesMB.mqh>

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

string StrategyName = "EntryRulesMB/";
string EAName = "Dow/";
string SetupTypeName = "IntenseManagement/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

EntryRulesMB *ERMBBuys;
EntryRulesMB *ERMBSells;

// Dow
double MaxMBHeight = 1500;
double MinMBHeight = 300;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 100;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    ERMBBuys = new EntryRulesMB(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter, SetupMBT);

    ERMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    ERMBBuys.AddPartial(CloseRR, 100);

    ERMBBuys.mMaxMBHeight = MaxMBHeight;
    ERMBBuys.mMinMBHeight = MinMBHeight;
    ERMBBuys.mEntryPaddingPips = EntryPaddingPips;
    ERMBBuys.mMinStopLossPips = MinStopLossPips;
    ERMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ERMBBuys.mBEAdditionalPips = BEAdditionalPips;

    ERMBBuys.AddTradingSession(16, 30, 19, 0);

    ERMBSells = new EntryRulesMB(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, SetupMBT);
    ERMBSells.SetPartialCSVRecordWriter(PartialWriter);
    ERMBSells.AddPartial(CloseRR, 100);

    ERMBSells.mMaxMBHeight = MaxMBHeight;
    ERMBSells.mMinMBHeight = MinMBHeight;
    ERMBSells.mEntryPaddingPips = EntryPaddingPips;
    ERMBSells.mMinStopLossPips = MinStopLossPips;
    ERMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ERMBSells.mBEAdditionalPips = BEAdditionalPips;

    ERMBSells.AddTradingSession(16, 30, 19, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete ERMBBuys;
    delete ERMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    ERMBBuys.Run();
    ERMBSells.Run();
}
