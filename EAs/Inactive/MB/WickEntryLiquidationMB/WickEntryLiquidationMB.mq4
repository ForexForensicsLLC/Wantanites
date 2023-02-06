//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/MagicNumbers.mqh>
#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Inactive/WickEntryLiquidationMB/WickEntryLiquidationMB.mqh>

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

string StrategyName = "WickEntryLiquidationMBSetup/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

LiquidationSetupTracker *LSTBuys;
LiquidationSetupTracker *LSTSells;

WickEntryLiquidationMB *WELMBBuys;
WickEntryLiquidationMB *WELMBSells;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double MinInitalBreakTotalPips = 50;
double EntryPaddingPips = 20;
double MinStopLossPips = 250;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 1500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    LSTBuys = new LiquidationSetupTracker(OP_BUY, SetupMBT);
    WELMBBuys = new WickEntryLiquidationMB(MagicNumbers::DowLiquidationMBBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                           EntryWriter, ExitWriter, ErrorWriter, SetupMBT, LSTBuys);
    WELMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    WELMBBuys.AddPartial(1000, 100);

    WELMBBuys.mMinInitialBreakTotalPips = MinInitalBreakTotalPips;
    WELMBBuys.mEntryPaddingPips = EntryPaddingPips;
    WELMBBuys.mMinStopLossPips = MinStopLossPips;
    WELMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WELMBBuys.mBEAdditionalPips = BEAdditionalPips;

    WELMBBuys.AddTradingSession(16, 30, 23, 0);

    LSTSells = new LiquidationSetupTracker(OP_SELL, SetupMBT);
    WELMBSells = new WickEntryLiquidationMB(MagicNumbers::DowLiquidationMBSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                            EntryWriter, ExitWriter, ErrorWriter, SetupMBT, LSTSells);
    WELMBSells.SetPartialCSVRecordWriter(PartialWriter);
    WELMBSells.AddPartial(1000, 100);

    WELMBSells.mMinInitialBreakTotalPips = MinInitalBreakTotalPips;
    WELMBSells.mEntryPaddingPips = EntryPaddingPips;
    WELMBSells.mMinStopLossPips = MinStopLossPips;
    WELMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WELMBSells.mBEAdditionalPips = BEAdditionalPips;

    WELMBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete LSTBuys;
    delete LSTSells;

    delete WELMBBuys;
    delete WELMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WELMBBuys.Run();
    WELMBSells.Run();
}
