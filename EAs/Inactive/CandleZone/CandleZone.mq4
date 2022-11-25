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
#include <SummitCapital/EAs/Inactive/CandleZone/CandleZone.mqh>

// --- EA Inputs ---
double RiskPercent = 0.25;
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

string StrategyName = "CandleZone/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

CandleZone *CZBuys;
CandleZone *CZSells;

// Dow
double MinMBHeight = 900;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 250;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    CZBuys = new CandleZone(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                            ErrorWriter, SetupMBT);
    CZBuys.SetPartialCSVRecordWriter(PartialWriter);
    CZBuys.AddPartial(CloseRR, 100);

    CZBuys.mMinMBHeight = MinMBHeight;
    CZBuys.mEntryPaddingPips = EntryPaddingPips;
    CZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CZBuys.mBEAdditionalPips = BEAdditionalPips;

    CZBuys.AddTradingSession(19, 0, 23, 0);

    CZSells = new CandleZone(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                             ErrorWriter, SetupMBT);
    CZSells.SetPartialCSVRecordWriter(PartialWriter);
    CZSells.AddPartial(CloseRR, 100);

    CZSells.mMinMBHeight = MinMBHeight;
    CZSells.mEntryPaddingPips = EntryPaddingPips;
    CZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CZSells.mBEAdditionalPips = BEAdditionalPips;

    CZSells.AddTradingSession(19, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete CZBuys;
    delete CZSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CZBuys.Run();
    CZSells.Run();
}
