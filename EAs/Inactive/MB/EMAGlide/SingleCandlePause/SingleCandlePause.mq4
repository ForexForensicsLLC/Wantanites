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
#include <WantaCapital/EAs/Inactive/EMAGlide/SingleCandlePause/SingleCandlePause.mqh>

int ForcedTimeFrame = 5;

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

string StrategyName = "EMAGlide/";
string EAName = "Nas/";
string SetupTypeName = "SingleCandlePause/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

SingleCandlePause *SCPBuys;
SingleCandlePause *SCPSells;

// Dow
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 20;
// double MinStopLossPips = 350;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 600;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 1000;

// Nas
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 0;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = SymbolConstants::NasSlippagePips;
double CloseRR = 3;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    SCPBuys = new SingleCandlePause(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, SetupMBT);

    SCPBuys.SetPartialCSVRecordWriter(PartialWriter);
    SCPBuys.AddPartial(CloseRR, 100);

    SCPBuys.mEntryPaddingPips = EntryPaddingPips;
    SCPBuys.mMinStopLossPips = MinStopLossPips;
    SCPBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SCPBuys.mBEAdditionalPips = BEAdditionalPips;

    SCPBuys.AddTradingSession(16, 30, 23, 0);

    SCPSells = new SingleCandlePause(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT);
    SCPSells.SetPartialCSVRecordWriter(PartialWriter);
    SCPSells.AddPartial(CloseRR, 100);

    SCPSells.mEntryPaddingPips = EntryPaddingPips;
    SCPSells.mMinStopLossPips = MinStopLossPips;
    SCPSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SCPSells.mBEAdditionalPips = BEAdditionalPips;

    SCPSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete SCPBuys;
    delete SCPSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SCPBuys.Run();
    SCPSells.Run();
}
