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
#include <WantaCapital/EAs/Active/ZoneOutsideMB/ZoneOutsideMB.mqh>

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "ZoneOutsideMB/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

ZoneOutsideMB *ZOMBBuys;
ZoneOutsideMB *ZOMBSells;

// Dow
double MinDistanceFromMB = 150;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 35;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 100;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    ZOMBBuys = new ZoneOutsideMB(MagicNumbers::DowZoneOutsideMBBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                 EntryWriter, ExitWriter, ErrorWriter, SetupMBT);

    ZOMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    ZOMBBuys.AddPartial(CloseRR, 100);

    ZOMBBuys.mMinDistanceFromMB = MinDistanceFromMB;
    ZOMBBuys.mEntryPaddingPips = EntryPaddingPips;
    ZOMBBuys.mMinStopLossPips = MinStopLossPips;
    ZOMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ZOMBBuys.mBEAdditionalPips = BEAdditionalPips;

    ZOMBBuys.AddTradingSession(16, 30, 23, 0);

    ZOMBSells = new ZoneOutsideMB(MagicNumbers::DowZoneOutsideMBSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                  EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    ZOMBSells.SetPartialCSVRecordWriter(PartialWriter);
    ZOMBSells.AddPartial(CloseRR, 100);

    ZOMBSells.mMinDistanceFromMB = MinDistanceFromMB;
    ZOMBSells.mEntryPaddingPips = EntryPaddingPips;
    ZOMBSells.mMinStopLossPips = MinStopLossPips;
    ZOMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ZOMBSells.mBEAdditionalPips = BEAdditionalPips;

    ZOMBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete ZOMBBuys;
    delete ZOMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    ZOMBBuys.Run();
    ZOMBSells.Run();
}
