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
#include <SummitCapital/EAs/MorningMB/MorningMB.mqh>

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
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "MorningMB/";
string EAName = "Nas/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MorningMB *MMBBuys;
MorningMB *MMBSells;

// Nas
double MaxSpreadPips = 10;
double EntryPaddingPips = 20;
double MinStopLossPips = 250;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = 50;
double CloseRR = 100;

// Dow
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 20;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 8;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    MMBBuys = new MorningMB(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                            ErrorWriter, SetupMBT);
    MMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    MMBBuys.AddPartial(CloseRR, 100);

    MMBBuys.mEntryPaddingPips = EntryPaddingPips;
    MMBBuys.mMinStopLossPips = MinStopLossPips;
    MMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MMBBuys.mBEAdditionalPips = BEAdditionalPips;

    MMBBuys.AddTradingSession(16, 30, 17, 0);

    MMBSells = new MorningMB(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                             ErrorWriter, SetupMBT);
    MMBSells.SetPartialCSVRecordWriter(PartialWriter);
    MMBSells.AddPartial(CloseRR, 100);

    MMBSells.mEntryPaddingPips = EntryPaddingPips;
    MMBSells.mMinStopLossPips = MinStopLossPips;
    MMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MMBSells.mBEAdditionalPips = BEAdditionalPips;

    MMBSells.AddTradingSession(16, 30, 17, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MMBBuys;
    delete MMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MMBBuys.Run();
    MMBSells.Run();
}
