//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.01"
#property strict

#include <Wantanites/Framework/Helpers/MailHelper.mqh>
#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/MB/DojiInZone/DojiInZone.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "DojiInZone/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

// MB Inputs
input string InitSettings = "------ Init -------"; // -
input int BarStart = 400;                          // Bars Back to Start Calculating From (-1=All Bars)

input string StructureSettings = "------- Structure ---------"; // -
input int StructureBoxesToTrack = 10;
input int MinCandlesInStructure = 3;
input CandlePart StructureValidatedBy = CandlePart::Body;
input CandlePart StructureBrokenBy = CandlePart::Body;
input bool ShowPendingStructure = true;

input string ZoneSettings = "------ Zones --------"; // -
input int MaxZonesInStructure = 5;
input bool AllowZonesAfterStructureValidation = false;
input CandlePart ZonesBrokenBy = CandlePart::Body;
input ZonePartInMB RequiredZonePartInStructure = ZonePartInMB::Whole;
input bool AllowMitigatedZones = false;
input bool AllowOverlappingZones = false; // AllowOverlappingZones (Requires AllowMitigatedZones=true)
input bool ShowPendingZones = true;
input CandlePart PendingZonesBrokenBy = CandlePart::Wick;
input bool AllowPendingMitigatedZones = true;
input bool AllowPendingOverlappingZones = false;

input string colors = "----- Colors -------"; // -
input color BullishStructure = clrLimeGreen;
input color BearishStructure = clrRed;
input color DemandZone = clrGold;
input color SupplyZone = clrMediumVioletRed;
input color PendingDemandZone = clrYellow;
input color PendingSupplyZone = clrAqua;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

MBTracker *MBT;

DojiInZone *DIZBuys;
DojiInZone *DIZSells;

// UJ
double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;
double MaxSlippage = 3;

int OnInit()
{
    MailHelper::Disable();

    TS = new TradingSession();
    TS.AddHourMinuteSession(2, 0, 23, 0);

    MBT = new MBTracker(false, Symbol(), (ENUM_TIMEFRAMES)Period(), BarStart, StructureBoxesToTrack, MinCandlesInStructure, StructureValidatedBy, StructureBrokenBy,
                        ShowPendingStructure, MaxZonesInStructure, AllowZonesAfterStructureValidation, ZonesBrokenBy, RequiredZonePartInStructure, AllowMitigatedZones,
                        AllowOverlappingZones, ShowPendingZones, PendingZonesBrokenBy, AllowPendingMitigatedZones, AllowPendingOverlappingZones, BullishStructure,
                        BearishStructure, DemandZone, SupplyZone, PendingDemandZone, PendingSupplyZone);

    DIZBuys = new DojiInZone(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                             MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);
    DIZBuys.AddTradingSession(TS);

    DIZSells = new DojiInZone(-2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                              MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);
    DIZSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete DIZBuys;
    delete DIZSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DIZBuys.Run();
    DIZSells.Run();
}
