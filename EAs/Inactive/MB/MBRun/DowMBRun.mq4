//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/MagicNumbers.mqh>
#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Active/MBRun/MBRun.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "MBRun/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

MBRun *MBRunBuys;
MBRun *MBRunSells;

// Dow
double MaxFirstMBHeightPips = 60;
double MaxSecondMBHeightPips = 80;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 35;
double StopLossPaddingPips = 2;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    MBRunBuys = new MBRun(MagicNumbers::DowMBRunBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                          ErrorWriter, SetupMBT);
    MBRunBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBRunBuys.AddPartial(CloseRR, 100);

    MBRunBuys.mMaxFirstMBHeightPips = MaxFirstMBHeightPips;
    MBRunBuys.mMaxSecondMBHeightPips = MaxSecondMBHeightPips;
    MBRunBuys.mEntryPaddingPips = EntryPaddingPips;
    MBRunBuys.mMinStopLossPips = MinStopLossPips;
    MBRunBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBRunBuys.mBEAdditionalPips = BEAdditionalPips;

    MBRunBuys.AddTradingSession(16, 30, 23, 0);

    MBRunSells = new MBRun(MagicNumbers::DowMBRunSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                           ErrorWriter, SetupMBT);
    MBRunSells.SetPartialCSVRecordWriter(PartialWriter);
    MBRunSells.AddPartial(CloseRR, 100);

    MBRunSells.mMaxFirstMBHeightPips = MaxFirstMBHeightPips;
    MBRunSells.mMaxSecondMBHeightPips = MaxSecondMBHeightPips;
    MBRunSells.mEntryPaddingPips = EntryPaddingPips;
    MBRunSells.mMinStopLossPips = MinStopLossPips;
    MBRunSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBRunSells.mBEAdditionalPips = BEAdditionalPips;

    MBRunSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MBRunBuys;
    delete MBRunSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBRunBuys.Run();
    MBRunSells.Run();
}
