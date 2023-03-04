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
#include <Wantanites/EAs/Inactive/EMAGlide/FurtherMBs/EMAGlideFurtherMBs.mqh>

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "EMAGlideFurtherMBs/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

EMAGlideFurtherMBs *EMAGFMBsBuys;
EMAGlideFurtherMBs *EMAGFMBsSells;

// Dow
double MaxMBHeight = 1000;
double MinMBGap = 100;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 350;
double StopLossPaddingPips = 100;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    EMAGFMBsBuys = new EMAGlideFurtherMBs(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                          ExitWriter, ErrorWriter, SetupMBT);

    EMAGFMBsBuys.SetPartialCSVRecordWriter(PartialWriter);
    EMAGFMBsBuys.AddPartial(CloseRR, 100);

    EMAGFMBsBuys.mMaxMBHeight = MaxMBHeight;
    EMAGFMBsBuys.mMinMBGap = MinMBGap;
    EMAGFMBsBuys.mEntryPaddingPips = EntryPaddingPips;
    EMAGFMBsBuys.mMinStopLossPips = MinStopLossPips;
    EMAGFMBsBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EMAGFMBsBuys.mBEAdditionalPips = BEAdditionalPips;

    EMAGFMBsBuys.AddTradingSession(16, 30, 23, 0);

    EMAGFMBsSells = new EMAGlideFurtherMBs(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                           ExitWriter, ErrorWriter, SetupMBT);
    EMAGFMBsSells.SetPartialCSVRecordWriter(PartialWriter);
    EMAGFMBsSells.AddPartial(CloseRR, 100);

    EMAGFMBsSells.mMaxMBHeight = MaxMBHeight;
    EMAGFMBsSells.mMinMBGap = MinMBGap;
    EMAGFMBsSells.mEntryPaddingPips = EntryPaddingPips;
    EMAGFMBsSells.mMinStopLossPips = MinStopLossPips;
    EMAGFMBsSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EMAGFMBsSells.mBEAdditionalPips = BEAdditionalPips;

    EMAGFMBsSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete EMAGFMBsBuys;
    delete EMAGFMBsSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    EMAGFMBsBuys.Run();
    EMAGFMBsSells.Run();
}
