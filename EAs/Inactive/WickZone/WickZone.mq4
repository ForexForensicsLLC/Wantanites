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
#include <SummitCapital/EAs/Inactive/WickZone/WickZone.mqh>

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

string StrategyName = "WickZone/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

WickZone *WZBuys;
WickZone *WZSells;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 35;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

// Nas
// double MaxSpreadPips = SymbolConstants::NasSpreadPips;
// double EntryPaddingPips = 20;
// double MinStopLossPips = 350;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 1000;
// double BEAdditionalPips = SymbolConstants::NasSlippagePips;
// double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    WZBuys = new WickZone(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, SetupMBT);

    WZBuys.SetPartialCSVRecordWriter(PartialWriter);
    WZBuys.AddPartial(CloseRR, 100);

    WZBuys.mEntryPaddingPips = EntryPaddingPips;
    WZBuys.mMinStopLossPips = MinStopLossPips;
    WZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WZBuys.mBEAdditionalPips = BEAdditionalPips;

    WZBuys.AddTradingSession(16, 30, 17, 15);

    WZSells = new WickZone(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, SetupMBT);
    WZSells.SetPartialCSVRecordWriter(PartialWriter);
    WZSells.AddPartial(CloseRR, 100);

    WZSells.mEntryPaddingPips = EntryPaddingPips;
    WZSells.mMinStopLossPips = MinStopLossPips;
    WZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WZSells.mBEAdditionalPips = BEAdditionalPips;

    WZSells.AddTradingSession(16, 30, 17, 15);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete WZBuys;
    delete WZSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WZBuys.Run();
    WZSells.Run();
}
