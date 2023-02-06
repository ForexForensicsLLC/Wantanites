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
#include <WantaCapital/EAs/Inactive/TinyMBValidation/TinyMBValidation.mqh>

// --- EA Inputs ---
double RiskPercent = 0.01;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 0;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "TinyMBValidation/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

TinyMBValidation *TMBVBuys;
TinyMBValidation *TMBVSells;

// Dow
double MaxMBPips = 30;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TMBVBuys = new TinyMBValidation(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, SetupMBT);

    TMBVBuys.SetPartialCSVRecordWriter(PartialWriter);
    TMBVBuys.AddPartial(CloseRR, 100);

    TMBVBuys.mMaxMBPips = MaxMBPips;
    TMBVBuys.mEntryPaddingPips = EntryPaddingPips;
    TMBVBuys.mMinStopLossPips = MinStopLossPips;
    TMBVBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBVBuys.mBEAdditionalPips = BEAdditionalPips;

    TMBVBuys.AddTradingSession(16, 30, 23, 0);

    TMBVSells = new TinyMBValidation(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT);
    TMBVSells.SetPartialCSVRecordWriter(PartialWriter);
    TMBVSells.AddPartial(CloseRR, 100);

    TMBVSells.mMaxMBPips = MaxMBPips;
    TMBVSells.mEntryPaddingPips = EntryPaddingPips;
    TMBVSells.mMinStopLossPips = MinStopLossPips;
    TMBVSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBVSells.mBEAdditionalPips = BEAdditionalPips;

    TMBVSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TMBVBuys;
    delete TMBVSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TMBVBuys.Run();
    TMBVSells.Run();
}
