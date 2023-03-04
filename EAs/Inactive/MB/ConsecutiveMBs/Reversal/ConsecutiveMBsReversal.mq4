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
#include <Wantanites/EAs/Inactive/ConsecutiveMBs/Reversal/ConsecutiveMBsReversal.mqh>

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

string StrategyName = "ConsecutiveMBs/";
string EAName = "Nas/";
string SetupTypeName = "Reversal/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

CMBsReversal *CMBsRBuys;
CMBsReversal *CMBsRSells;

// Dow
// double MaxSpreadPips = SymbolConstants::DowSpreadPips;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 350;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = SymbolConstants::DowSlippagePips;
// double CloseRR = 20;

// Nas
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::NasSlippagePips;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    CMBsRBuys = new CMBsReversal(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter, SetupMBT);

    CMBsRBuys.SetPartialCSVRecordWriter(PartialWriter);
    CMBsRBuys.AddPartial(CloseRR, 100);

    CMBsRBuys.mEntryPaddingPips = EntryPaddingPips;
    CMBsRBuys.mMinStopLossPips = MinStopLossPips;
    CMBsRBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMBsRBuys.mBEAdditionalPips = BEAdditionalPips;

    CMBsRBuys.AddTradingSession(16, 30, 20, 0);

    CMBsRSells = new CMBsReversal(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, SetupMBT);
    CMBsRSells.SetPartialCSVRecordWriter(PartialWriter);
    CMBsRSells.AddPartial(CloseRR, 100);

    CMBsRSells.mEntryPaddingPips = EntryPaddingPips;
    CMBsRSells.mMinStopLossPips = MinStopLossPips;
    CMBsRSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMBsRSells.mBEAdditionalPips = BEAdditionalPips;

    CMBsRSells.AddTradingSession(16, 30, 20, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete CMBsRBuys;
    delete CMBsRSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CMBsRBuys.Run();
    CMBsRSells.Run();
}
