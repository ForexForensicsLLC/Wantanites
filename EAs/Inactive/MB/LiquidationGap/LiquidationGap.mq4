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
#include <SummitCapital/EAs/Inactive/LiquidationGap/LiquidationGap.mqh>

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

string StrategyName = "LiquidationGap/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

LiquidationGap *LGBuys;
LiquidationGap *LGSells;

// Dow
double MinMBGap = 750;
double MaxMBHeight = 1500;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 0;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

// Nas
// double MinMBHeight = 200;
// double MaxSpreadPips = SymbolConstants::NasSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 0;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 150;
// double BEAdditionalPips = SymbolConstants::NasSlippagePips;
// double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    LGBuys = new LiquidationGap(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter, SetupMBT);

    LGBuys.SetPartialCSVRecordWriter(PartialWriter);
    LGBuys.AddPartial(CloseRR, 100);

    LGBuys.mMinMBGap = MinMBGap;
    LGBuys.mMaxMBHeight = MaxMBHeight;
    LGBuys.mEntryPaddingPips = EntryPaddingPips;
    LGBuys.mMinStopLossPips = MinStopLossPips;
    LGBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LGBuys.mBEAdditionalPips = BEAdditionalPips;

    LGBuys.AddTradingSession(16, 30, 23, 30);

    LGSells = new LiquidationGap(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, SetupMBT);
    LGSells.SetPartialCSVRecordWriter(PartialWriter);
    LGSells.AddPartial(CloseRR, 100);

    LGSells.mMinMBGap = MinMBGap;
    LGSells.mMaxMBHeight = MaxMBHeight;
    LGSells.mEntryPaddingPips = EntryPaddingPips;
    LGSells.mMinStopLossPips = MinStopLossPips;
    LGSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LGSells.mBEAdditionalPips = BEAdditionalPips;

    LGSells.AddTradingSession(16, 30, 23, 30);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete LGBuys;
    delete LGSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LGBuys.Run();
    LGSells.Run();
}
