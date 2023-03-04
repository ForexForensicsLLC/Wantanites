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
#include <Wantanites/EAs/Active/TinyMBGapBreak/CandleBreak/TinyMBGapBreakCandleBreak.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

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

string StrategyName = "TinyMBGapBreak/";
string EAName = "Dow/";
string SetupTypeName = "CandleBreak/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

TinyMBGapBreak *TMBBuys;
TinyMBGapBreak *TMBSells;

// Dow
double MaxMBHeight = 50;
double MinMBGap = 50;
double MaxEntrySlippage = 15;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 35;
double StopLossPaddingPips = 10;
double PipsToWaitBeforeBE = 150;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 15;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TMBBuys = new TinyMBGapBreak(MagicNumbers::DowTinyMBGapBreakCandleBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                 RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);

    TMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    TMBBuys.AddPartial(CloseRR, 100);

    TMBBuys.mMaxMBHeight = MaxMBHeight;
    TMBBuys.mMinMBGap = MinMBGap;
    TMBBuys.mMaxEntrySlippage = MaxEntrySlippage;
    TMBBuys.mEntryPaddingPips = EntryPaddingPips;
    TMBBuys.mMinStopLossPips = MinStopLossPips;
    TMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBBuys.mBEAdditionalPips = BEAdditionalPips;

    TMBBuys.AddTradingSession(16, 30, 23, 0);

    TMBSells = new TinyMBGapBreak(MagicNumbers::DowTinyMBGapBreakCandleBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                  RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    TMBSells.SetPartialCSVRecordWriter(PartialWriter);
    TMBSells.AddPartial(CloseRR, 100);

    TMBSells.mMaxMBHeight = MaxMBHeight;
    TMBSells.mMinMBGap = MinMBGap;
    TMBSells.mMaxEntrySlippage = MaxEntrySlippage;
    TMBSells.mEntryPaddingPips = EntryPaddingPips;
    TMBSells.mMinStopLossPips = MinStopLossPips;
    TMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TMBSells.mBEAdditionalPips = BEAdditionalPips;

    TMBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TMBBuys;
    delete TMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TMBBuys.Run();
    TMBSells.Run();
}
