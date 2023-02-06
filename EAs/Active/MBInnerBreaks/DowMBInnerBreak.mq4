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
#include <WantaCapital/EAs/Active/MBInnerBreaks/MBInnerBreak.mqh>

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
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "MBInnerBreak/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBInnerBreak *MBInnerBreakBuys;
MBInnerBreak *MBInnerBreakSells;

double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 25;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double LargeBodyPips = 15;
double PushFurtherPips = 15;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    MBInnerBreakBuys = new MBInnerBreak(MagicNumbers::DowInnerBreakBigDipperBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
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

    MBInnerBreakSells = new MBInnerBreak(MagicNumbers::DowInnerBreakBigDipperSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
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
