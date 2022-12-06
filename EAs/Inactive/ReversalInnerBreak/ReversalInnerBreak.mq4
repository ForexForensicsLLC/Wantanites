//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/Inactive/ReversalInnerBreak/ReversalInnerBreak.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 0;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "ReversalInnerBreak/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
ReversalInnerBreak *RIBBuys;
ReversalInnerBreak *RIBSells;

// Nas
// double MaxSpreadPips = 10;
// double MinMBPips = 800;
// double MinDistanceFromPreviousMBRun = 600;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 50;
// double PipsToWaitBeforeBE = 200;
// double BEAdditionalPips = 10;
// double LargeBodyPips = 100;
// double PushFurtherPips = 200;

// Dow
double MaxSpreadPips = 19;
double MinMBPips = 600;
double MinDistanceFromPreviousMBRun = 600;
double MinPendingMBPips = 800;
double EntryPaddingPips = 0;
double MinStopLossPips = 0.0;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = 20;
double LargeBodyPips = 150;
double PushFurtherPips = 150;

// S&P
// double EntryPaddingPips = 0;
// double MinStopLossPips = 100;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 200;
// double BEAdditionalPips = 50;
// double LargeBodyPips = 0;
// double PushFurtherPips = 0;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    RIBBuys = new ReversalInnerBreak(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                     ErrorWriter, SetupMBT);
    RIBBuys.SetPartialCSVRecordWriter(PartialWriter);
    RIBBuys.AddPartial(1000, 100);

    RIBBuys.mMinMBPips = MinMBPips;
    RIBBuys.mMinDistanceFromPreviousMBRun = MinDistanceFromPreviousMBRun;
    RIBBuys.mEntryPaddingPips = EntryPaddingPips;
    RIBBuys.mMinStopLossPips = MinStopLossPips;
    RIBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    RIBBuys.mBEAdditionalPip = BEAdditionalPips;
    RIBBuys.mLargeBodyPips = LargeBodyPips;
    RIBBuys.mPushFurtherPips = PushFurtherPips;

    RIBBuys.AddTradingSession(16, 30, 23, 0);

    RIBSells = new ReversalInnerBreak(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                      ErrorWriter, SetupMBT);
    RIBSells.SetPartialCSVRecordWriter(PartialWriter);
    RIBSells.AddPartial(1000, 100);

    RIBSells.mMinMBPips = MinMBPips;
    RIBSells.mMinDistanceFromPreviousMBRun = MinDistanceFromPreviousMBRun;
    RIBSells.mEntryPaddingPips = EntryPaddingPips;
    RIBSells.mMinStopLossPips = MinStopLossPips;
    RIBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    RIBSells.mBEAdditionalPip = BEAdditionalPips;
    RIBSells.mLargeBodyPips = LargeBodyPips;
    RIBSells.mPushFurtherPips = PushFurtherPips;

    RIBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete RIBBuys;
    delete RIBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    RIBBuys.Run();
    RIBSells.Run();
}
