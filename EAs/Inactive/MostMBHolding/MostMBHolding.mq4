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
#include <SummitCapital/EAs/Inactive/MostMBHolding/MostMBHolding.mqh>

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

string StrategyName = "MostMBHolding/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MostMBHolding *MMBHBuys;
MostMBHolding *MMBHSells;

// Dow
double MaxMBHeight = 10000;
double MinMBHeight = 0;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    MMBHBuys = new MostMBHolding(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, SetupMBT);

    MMBHBuys.SetPartialCSVRecordWriter(PartialWriter);
    MMBHBuys.AddPartial(CloseRR, 100);

    MMBHBuys.mMaxMBHeight = MaxMBHeight;
    MMBHBuys.mMinMBHeight = MinMBHeight;
    MMBHBuys.mEntryPaddingPips = EntryPaddingPips;
    MMBHBuys.mMinStopLossPips = MinStopLossPips;
    MMBHBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MMBHBuys.mBEAdditionalPips = BEAdditionalPips;

    MMBHBuys.AddTradingSession(16, 30, 23, 0);

    MMBHSells = new MostMBHolding(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, SetupMBT);
    MMBHSells.SetPartialCSVRecordWriter(PartialWriter);
    MMBHSells.AddPartial(CloseRR, 100);

    MMBHSells.mMaxMBHeight = MaxMBHeight;
    MMBHSells.mMinMBHeight = MinMBHeight;
    MMBHSells.mEntryPaddingPips = EntryPaddingPips;
    MMBHSells.mMinStopLossPips = MinStopLossPips;
    MMBHSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MMBHSells.mBEAdditionalPips = BEAdditionalPips;

    MMBHSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MMBHBuys;
    delete MMBHSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MMBHBuys.Run();
    MMBHSells.Run();
}
