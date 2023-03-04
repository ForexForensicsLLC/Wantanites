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
#include <Wantanites/EAs/Active/MBCluster/CandleZone/MBCluster.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

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

string StrategyName = "MBCluster/";
string EAName = "Dow/";
string SetupTypeName = "CandleZone/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MBCluster *MBCBuys;
MBCluster *MBCSells;

// Dow
double MaxZoneBreakagePips = 1.5;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 25;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    MBCBuys = new MBCluster(MagicNumbers::DowMBClusterCandleZoneBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                            EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    MBCBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBCBuys.AddPartial(CloseRR, 100);

    MBCBuys.mMaxZoneBreakagePips = MaxZoneBreakagePips;
    MBCBuys.mEntryPaddingPips = EntryPaddingPips;
    MBCBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBCBuys.mBEAdditionalPips = BEAdditionalPips;

    MBCBuys.AddTradingSession(16, 30, 23, 0);

    MBCSells = new MBCluster(MagicNumbers::DowMBClusterCandleZoneSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                             RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    MBCSells.SetPartialCSVRecordWriter(PartialWriter);
    MBCSells.AddPartial(CloseRR, 100);

    MBCSells.mMaxZoneBreakagePips = MaxZoneBreakagePips;
    MBCSells.mEntryPaddingPips = EntryPaddingPips;
    MBCSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBCSells.mBEAdditionalPips = BEAdditionalPips;

    MBCSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MBCBuys;
    delete MBCSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBCBuys.Run();
    MBCSells.Run();
}
