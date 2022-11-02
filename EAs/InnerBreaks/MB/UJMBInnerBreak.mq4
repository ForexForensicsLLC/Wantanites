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
#include <SummitCapital/EAs/InnerBreaks/MB/TheGrannySmith.mqh>

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

string StrategyName = "MBInnerBreak/";
string EAName = "UJ/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
TheGrannySmith *MBInnerBreakBuys;
TheGrannySmith *MBInnerBreakSells;

double MaxSpreadPips = 1;
double EntryPaddingPips = 0;
double MinStopLossPips = 2;
double StopLossPaddingPips = 1;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = 1;
double LargeBodyPips = 5;
double PushFurtherPips = 5;
double CloseRR = 2;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    MBInnerBreakBuys = new TheGrannySmith(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                          ExitWriter, ErrorWriter, SetupMBT);

    MBInnerBreakBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBInnerBreakBuys.AddPartial(CloseRR, 100);

    MBInnerBreakBuys.mEntryPaddingPips = EntryPaddingPips;
    MBInnerBreakBuys.mMinStopLossPips = MinStopLossPips;
    MBInnerBreakBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBInnerBreakBuys.mBEAdditionalPips = BEAdditionalPips;
    MBInnerBreakBuys.mLargeBodyPips = LargeBodyPips;
    MBInnerBreakBuys.mPushFurtherPips = PushFurtherPips;

    MBInnerBreakBuys.AddTradingSession(16, 30, 23, 0);

    MBInnerBreakSells = new TheGrannySmith(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                           ExitWriter, ErrorWriter, SetupMBT);
    MBInnerBreakSells.SetPartialCSVRecordWriter(PartialWriter);
    MBInnerBreakSells.AddPartial(CloseRR, 100);

    MBInnerBreakSells.mEntryPaddingPips = EntryPaddingPips;
    MBInnerBreakSells.mMinStopLossPips = MinStopLossPips;
    MBInnerBreakSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBInnerBreakSells.mBEAdditionalPips = BEAdditionalPips;
    MBInnerBreakSells.mLargeBodyPips = LargeBodyPips;
    MBInnerBreakSells.mPushFurtherPips = PushFurtherPips;

    MBInnerBreakSells.AddTradingSession(16, 30, 23, 0);

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
