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
#include <Wantanites/EAs/Inactive/MB/MBInnerBreak/MBInnerBreak.mqh>

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
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "MBInnerBreak/";
string EAName = "EU/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

MBTracker *SetupMBT;
MBInnerBreak *MBInnerBreakBuys;
MBInnerBreak *MBInnerBreakSells;

double MaxSpreadPips = 3;
double EntryPaddingPips = .1;
double MinStopLossPips = 1;
double StopLossPaddingPips = 1;
double PipsToWaitBeforeBE = 3;
double BEAdditionalPips = 0.5;
double LargeBodyPips = 3;
double PushFurtherPips = 3;
double CloseRR = 10;

int OnInit()
{
    TS = new TradingSession();
    TS.AddHourMinuteSession(11, 0, 23, 0);

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    MBInnerBreakBuys = new MBInnerBreak(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                        ExitWriter, ErrorWriter, SetupMBT);

    MBInnerBreakBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBInnerBreakBuys.AddPartial(CloseRR, 100);

    MBInnerBreakBuys.mEntryPaddingPips = EntryPaddingPips;
    MBInnerBreakBuys.mMinStopLossPips = MinStopLossPips;
    MBInnerBreakBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBInnerBreakBuys.mBEAdditionalPips = BEAdditionalPips;
    MBInnerBreakBuys.mLargeBodyPips = LargeBodyPips;
    MBInnerBreakBuys.mPushFurtherPips = PushFurtherPips;

    MBInnerBreakBuys.AddTradingSession(TS);

    MBInnerBreakSells = new MBInnerBreak(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                         ExitWriter, ErrorWriter, SetupMBT);
    MBInnerBreakSells.SetPartialCSVRecordWriter(PartialWriter);
    MBInnerBreakSells.AddPartial(CloseRR, 100);

    MBInnerBreakSells.mEntryPaddingPips = EntryPaddingPips;
    MBInnerBreakSells.mMinStopLossPips = MinStopLossPips;
    MBInnerBreakSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBInnerBreakSells.mBEAdditionalPips = BEAdditionalPips;
    MBInnerBreakSells.mLargeBodyPips = LargeBodyPips;
    MBInnerBreakSells.mPushFurtherPips = PushFurtherPips;

    MBInnerBreakSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MBInnerBreakBuys;
    delete MBInnerBreakSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBInnerBreakBuys.Run();
    MBInnerBreakSells.Run();
}
