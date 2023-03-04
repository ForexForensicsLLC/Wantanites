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
#include <Wantanites/EAs/Inactive/MultiTFMBs/MultiTimeFrameMBs.mqh>

int SetupTimeFrame = 240;
int EntryTimeFrame = 1;

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

string StrategyName = "MultiTimeFrameMBs/";
string EAName = "4hSetup1MinEntry/";
string SetupTypeName = "Dow/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *EntryMBT;

MultiTimeFrameMBs *MTFBuys;
MultiTimeFrameMBs *MTFSells;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 350;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 150;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), SetupTimeFrame, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);
    EntryMBT = new MBTracker(Symbol(), EntryTimeFrame, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    MTFBuys = new MultiTimeFrameMBs(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, SetupMBT, EntryMBT);

    MTFBuys.SetPartialCSVRecordWriter(PartialWriter);
    MTFBuys.AddPartial(CloseRR, 100);

    MTFBuys.mSetupTimeFrame = SetupTimeFrame;
    MTFBuys.mEntryPaddingPips = EntryPaddingPips;
    MTFBuys.mMinStopLossPips = MinStopLossPips;
    MTFBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MTFBuys.mBEAdditionalPips = BEAdditionalPips;

    MTFBuys.AddTradingSession(16, 30, 23, 0);

    MTFSells = new MultiTimeFrameMBs(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT, EntryMBT);
    MTFSells.SetPartialCSVRecordWriter(PartialWriter);
    MTFSells.AddPartial(CloseRR, 100);

    MTFSells.mSetupTimeFrame = SetupTimeFrame;
    MTFSells.mEntryPaddingPips = EntryPaddingPips;
    MTFSells.mMinStopLossPips = MinStopLossPips;
    MTFSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MTFSells.mBEAdditionalPips = BEAdditionalPips;

    MTFSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete EntryMBT;

    delete MTFBuys;
    delete MTFSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MTFBuys.Run();
    MTFSells.Run();
}
