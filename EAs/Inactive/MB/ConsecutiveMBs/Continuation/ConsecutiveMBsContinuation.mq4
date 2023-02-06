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
#include <WantaCapital/EAs/Inactive/ConsecutiveMBs/Continuation/ConsecutiveMBsContinuation.mqh>

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
string EAName = "Dow/";
string SetupTypeName = "Continuation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

CMBsContinuation *CMBsCBuys;
CMBsContinuation *CMBsSells;

// Dow
double MaxMBHeight = 1500;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    CMBsCBuys = new CMBsContinuation(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT);

    CMBsCBuys.SetPartialCSVRecordWriter(PartialWriter);
    CMBsCBuys.AddPartial(CloseRR, 100);

    CMBsCBuys.mMaxMBHeight = MaxMBHeight;
    CMBsCBuys.mEntryPaddingPips = EntryPaddingPips;
    CMBsCBuys.mMinStopLossPips = MinStopLossPips;
    CMBsCBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMBsCBuys.mBEAdditionalPips = BEAdditionalPips;

    CMBsCBuys.AddTradingSession(16, 30, 19, 0);

    CMBsSells = new CMBsContinuation(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT);
    CMBsSells.SetPartialCSVRecordWriter(PartialWriter);
    CMBsSells.AddPartial(CloseRR, 100);

    CMBsSells.mMaxMBHeight = MaxMBHeight;
    CMBsSells.mEntryPaddingPips = EntryPaddingPips;
    CMBsSells.mMinStopLossPips = MinStopLossPips;
    CMBsSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMBsSells.mBEAdditionalPips = BEAdditionalPips;

    CMBsSells.AddTradingSession(16, 30, 19, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete CMBsCBuys;
    delete CMBsSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CMBsCBuys.Run();
    CMBsSells.Run();
}
