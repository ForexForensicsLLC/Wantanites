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
#include <SummitCapital/EAs/Inactive/ConsecutiveMBs/TinyOutsideSecond/TinyMBOutsideSecond.mqh>

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

string StrategyName = "TinyMBOutsideSecond/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

TinyMBOutsideSecond *TMBOSBuys;
TinyMBOutsideSecond *TMBOSSells;

// Dow
double MaxMBHeight = 400;
double MinMBHeight = 0;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 50;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = 150;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TMBOSBuys = new TinyMBOutsideSecond(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                        ExitWriter, ErrorWriter, SetupMBT);

    TMBOSBuys.SetPartialCSVRecordWriter(PartialWriter);
    TMBOSBuys.AddPartial(CloseRR, 100);

    TMBOSBuys.mMaxMBHeight = MaxMBHeight;
    TMBOSBuys.mMinMBHeight = MinMBHeight;
    TMBOSBuys.mEntryPaddingPips = EntryPaddingPips;
    TMBOSBuys.mMinStopLossPips = MinStopLossPips;
    TMBOSBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBOSBuys.mBEAdditionalPips = BEAdditionalPips;

    TMBOSBuys.AddTradingSession(16, 30, 23, 0);

    TMBOSSells = new TinyMBOutsideSecond(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                         ExitWriter, ErrorWriter, SetupMBT);
    TMBOSSells.SetPartialCSVRecordWriter(PartialWriter);
    TMBOSSells.AddPartial(CloseRR, 100);

    TMBOSSells.mMaxMBHeight = MaxMBHeight;
    TMBOSSells.mMinMBHeight = MinMBHeight;
    TMBOSSells.mEntryPaddingPips = EntryPaddingPips;
    TMBOSSells.mMinStopLossPips = MinStopLossPips;
    TMBOSSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBOSSells.mBEAdditionalPips = BEAdditionalPips;

    TMBOSSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TMBOSBuys;
    delete TMBOSSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TMBOSBuys.Run();
    TMBOSSells.Run();
}
