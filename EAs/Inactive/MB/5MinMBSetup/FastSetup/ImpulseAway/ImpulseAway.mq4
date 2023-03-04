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
#include <Wantanites/EAs/Inactive/5minMBSetup/FastSetup/ImpulseAway/ImpulseAway.mqh>

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

string StrategyName = "5MinMBSetup/";
string EAName = "Dow/";
string SetupTypeName = "ImpulseAway/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

ImpulseAway *IABuys;
ImpulseAway *IASells;

// Dow 5 min
double MinBreakBodyPips = 10;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 30;
double BEAdditionalPips = 3;
double CloseRR = 10;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    IABuys = new ImpulseAway(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                             ExitWriter, ErrorWriter, SetupMBT);

    IABuys.SetPartialCSVRecordWriter(PartialWriter);
    IABuys.AddPartial(CloseRR, 100);

    IABuys.mMinBreakBodyPips = MinBreakBodyPips;
    IABuys.mEntryPaddingPips = EntryPaddingPips;
    IABuys.mMinStopLossPips = MinStopLossPips;
    IABuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    IABuys.mBEAdditionalPips = BEAdditionalPips;

    IABuys.AddTradingSession(14, 0, 16, 0);

    IASells = new ImpulseAway(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                              ExitWriter, ErrorWriter, SetupMBT);
    IASells.SetPartialCSVRecordWriter(PartialWriter);
    IASells.AddPartial(CloseRR, 100);

    IASells.mMinBreakBodyPips = MinBreakBodyPips;
    IASells.mEntryPaddingPips = EntryPaddingPips;
    IASells.mMinStopLossPips = MinStopLossPips;
    IASells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    IASells.mBEAdditionalPips = BEAdditionalPips;

    IASells.AddTradingSession(14, 0, 16, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete IABuys;
    delete IASells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    IABuys.Run();
    IASells.Run();
}
