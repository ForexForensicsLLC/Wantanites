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
#include <WantaCapital/EAs/Inactive/5minMBSetup/NoBodyInZone/NoBodyInZone.mqh>

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
string EAName = "Nas/";
string SetupTypeName = "NoBodyInZone/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

NoBodyInZone *TDIZBuys;
NoBodyInZone *TDIZSells;

// Dow
// double MinMBHeight = 900;
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 0;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 10;

// Nas
double MinMBHeight = 200;
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 150;
double BEAdditionalPips = SymbolConstants::NasSlippagePips;
double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TDIZBuys = new NoBodyInZone(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter, SetupMBT);

    TDIZBuys.SetPartialCSVRecordWriter(PartialWriter);
    TDIZBuys.AddPartial(CloseRR, 100);

    TDIZBuys.mMinMBHeight = MinMBHeight;
    TDIZBuys.mEntryPaddingPips = EntryPaddingPips;
    TDIZBuys.mMinStopLossPips = MinStopLossPips;
    TDIZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TDIZBuys.mBEAdditionalPips = BEAdditionalPips;

    TDIZBuys.AddTradingSession(16, 30, 23, 0);

    TDIZSells = new NoBodyInZone(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, SetupMBT);
    TDIZSells.SetPartialCSVRecordWriter(PartialWriter);
    TDIZSells.AddPartial(CloseRR, 100);

    TDIZSells.mMinMBHeight = MinMBHeight;
    TDIZSells.mEntryPaddingPips = EntryPaddingPips;
    TDIZSells.mMinStopLossPips = MinStopLossPips;
    TDIZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TDIZSells.mBEAdditionalPips = BEAdditionalPips;

    TDIZSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TDIZBuys;
    delete TDIZSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TDIZBuys.Run();
    TDIZSells.Run();
}
