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
#include <SummitCapital/EAs/Inactive/MBEntry/Doji/MBEntryDoji.mqh>

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
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "MBEntry/";
string EAName = "Dow/";
string SetupTypeName = "Doji/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MBEntryDoji *FMBBuys;
MBEntryDoji *FMBSells;

// Nas
// double MaxSpreadPips = 10;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = 50;
// double CloseRR = 10;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 3;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    FMBBuys = new MBEntryDoji(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                              ErrorWriter, SetupMBT);
    FMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    FMBBuys.AddPartial(1000, 100);

    FMBBuys.mEntryPaddingPips = EntryPaddingPips;
    FMBBuys.mMinStopLossPips = MinStopLossPips;
    FMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    FMBBuys.mBEAdditionalPips = BEAdditionalPips;

    FMBBuys.AddTradingSession(16, 30, 23, 0);

    FMBSells = new MBEntryDoji(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                               ErrorWriter, SetupMBT);
    FMBSells.SetPartialCSVRecordWriter(PartialWriter);
    FMBSells.AddPartial(1000, 100);

    FMBSells.mEntryPaddingPips = EntryPaddingPips;
    FMBSells.mMinStopLossPips = MinStopLossPips;
    FMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    FMBSells.mBEAdditionalPips = BEAdditionalPips;

    FMBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete FMBBuys;
    delete FMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    FMBBuys.Run();
    FMBSells.Run();
}
