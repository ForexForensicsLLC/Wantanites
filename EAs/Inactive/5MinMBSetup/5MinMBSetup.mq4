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
#include <SummitCapital/EAs/Inactive/5MinMBSetup/5MinMBSetup.mqh>

// --- EA Inputs ---
double RiskPercent = 0.01;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = false;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "5MinMBSetup/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *EntryMBT;

FiveMinMBSetup *FMBSBuys;
FiveMinMBSetup *FMBSSells;

// Dow
double MaxMBPips = 300;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 350;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 5, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    EntryMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    FMBSBuys = new FiveMinMBSetup(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, SetupMBT, EntryMBT);

    FMBSBuys.SetPartialCSVRecordWriter(PartialWriter);
    FMBSBuys.AddPartial(CloseRR, 100);

    FMBSBuys.mEntryPaddingPips = EntryPaddingPips;
    FMBSBuys.mMinStopLossPips = MinStopLossPips;
    FMBSBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    FMBSBuys.mBEAdditionalPips = BEAdditionalPips;

    FMBSBuys.AddTradingSession(16, 30, 23, 0);

    FMBSSells = new FiveMinMBSetup(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter, SetupMBT, EntryMBT);
    FMBSSells.SetPartialCSVRecordWriter(PartialWriter);
    FMBSSells.AddPartial(CloseRR, 100);

    FMBSSells.mEntryPaddingPips = EntryPaddingPips;
    FMBSSells.mMinStopLossPips = MinStopLossPips;
    FMBSSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    FMBSSells.mBEAdditionalPips = BEAdditionalPips;

    FMBSSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete EntryMBT;

    delete FMBSBuys;
    delete FMBSSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    FMBSBuys.Run();
    FMBSSells.Run();
}
