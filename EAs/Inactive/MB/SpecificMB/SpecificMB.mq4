//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Helpers/MailHelper.mqh>
#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/MB/SpecificMB/SpecificMB.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
input double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "SpecificMB/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

SpecificMB *SMBBuys;
SpecificMB *SMBSells;

MBTracker *MBT;

// -- MBTracker Inputs ---
bool CalculateOnTick = false;
int BarToStart = -1;
int MBsToTrack = 300;
int MaxZonesInMB = 2;
bool AllowZonesAfterMBValidation = true;
int MinCandlesInStructure = 2;
CandlePart MBsValidatedBy = CandlePart::Body;
CandlePart MBsBrokenBy = CandlePart::Body;
bool AllowPendingMBs = true;
CandlePart ZonesBrokenBy = CandlePart::Body;
ZonePartInMB RequiredZonePartInMB = ZonePartInMB::Whole;
bool AllowMitigatedZones = false;
bool AllowOverlappingZones = false;
bool AllowPendingZones = true;
CandlePart PendingZonesBrokenBy = CandlePart::Wick;
bool AllowMitigatedPendingZones = true;
bool AllowOverlappingPendingZones = false;

// UJ
input double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;
double MaxSlippage = 3;

int OnInit()
{
    TS = new TradingSession();

    MBT = new MBTracker(CalculateOnTick, Symbol(), (ENUM_TIMEFRAMES)Period(), BarToStart, MBsToTrack, MinCandlesInStructure, MBsValidatedBy, MBsBrokenBy, AllowPendingMBs,
                        MaxZonesInMB, AllowZonesAfterMBValidation, ZonesBrokenBy, RequiredZonePartInMB, AllowMitigatedZones, AllowOverlappingZones, AllowPendingZones,
                        PendingZonesBrokenBy, AllowMitigatedZones, AllowPendingZones);

    SMBBuys = new SpecificMB(MagicNumbers::UJTimeRangeBreakoutBuys, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                             MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);
    SMBBuys.AddTradingSession(TS);

    SMBSells = new SpecificMB(MagicNumbers::UJTimeRangeBreakoutSells, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                              MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);
    SMBSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete SMBBuys;
    delete SMBSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SMBBuys.Run();
    SMBSells.Run();
}
