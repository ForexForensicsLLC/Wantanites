//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/EMAGlide/MB/MBEMAGlide.mqh>

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

string StrategyName = "MBEMAGlide/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MBEMAGlide *MBEMAGBuys;
MBEMAGlide *MBEMAGSells;

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

    MBEMAGBuys = new MBEMAGlide(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter, SetupMBT);

    MBEMAGBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBEMAGBuys.AddPartial(CloseRR, 100);

    MBEMAGBuys.mMaxMBHeight = MaxMBHeight;
    MBEMAGBuys.mMinMBGap = MinMBGap;
    MBEMAGBuys.mEntryPaddingPips = EntryPaddingPips;
    MBEMAGBuys.mMinStopLossPips = MinStopLossPips;
    MBEMAGBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBEMAGBuys.mBEAdditionalPips = BEAdditionalPips;

    MBEMAGBuys.AddTradingSession(16, 30, 23, 0);

    MBEMAGSells = new MBEMAGlide(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, SetupMBT);
    MBEMAGSells.SetPartialCSVRecordWriter(PartialWriter);
    MBEMAGSells.AddPartial(CloseRR, 100);

    MBEMAGSells.mMaxMBHeight = MaxMBHeight;
    MBEMAGSells.mMinMBGap = MinMBGap;
    MBEMAGSells.mEntryPaddingPips = EntryPaddingPips;
    MBEMAGSells.mMinStopLossPips = MinStopLossPips;
    MBEMAGSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBEMAGSells.mBEAdditionalPips = BEAdditionalPips;

    MBEMAGSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MBEMAGBuys;
    delete MBEMAGSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBEMAGBuys.Run();
    MBEMAGSells.Run();
}
