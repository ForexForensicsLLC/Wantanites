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
#include <WantaCapital/EAs/Inactive/ZoneOutsideMB/TinyMBTapIn/TinyMBTapIn.mqh>

string ForcedSymbol = "NAS100";
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
string EAName = "Nas/";
string SetupTypeName = "TinyMBTapIn/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

TinyMBTapIn *TMBTIBuys;
TinyMBTapIn *TMBTISells;

// Nas
double MinDistanceFromMB = 15;
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 30;
double BEAdditionalPips = 1;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TMBTIBuys = new TinyMBTapIn(MagicNumbers::DowZoneOutsideMBBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                EntryWriter, ExitWriter, ErrorWriter, SetupMBT);

    TMBTIBuys.SetPartialCSVRecordWriter(PartialWriter);
    TMBTIBuys.AddPartial(CloseRR, 100);

    TMBTIBuys.mMinDistanceFromMB = MinDistanceFromMB;
    TMBTIBuys.mEntryPaddingPips = EntryPaddingPips;
    TMBTIBuys.mMinStopLossPips = MinStopLossPips;
    TMBTIBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBTIBuys.mBEAdditionalPips = BEAdditionalPips;

    TMBTIBuys.AddTradingSession(16, 30, 23, 0);

    TMBTISells = new TinyMBTapIn(MagicNumbers::DowZoneOutsideMBSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                 EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    TMBTISells.SetPartialCSVRecordWriter(PartialWriter);
    TMBTISells.AddPartial(CloseRR, 100);

    TMBTISells.mMinDistanceFromMB = MinDistanceFromMB;
    TMBTISells.mEntryPaddingPips = EntryPaddingPips;
    TMBTISells.mMinStopLossPips = MinStopLossPips;
    TMBTISells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBTISells.mBEAdditionalPips = BEAdditionalPips;

    TMBTISells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TMBTIBuys;
    delete TMBTISells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TMBTIBuys.Run();
    TMBTISells.Run();
}
