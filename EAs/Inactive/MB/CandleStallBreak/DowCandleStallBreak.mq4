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
#include <WantaCapital/EAs/Active/CandleStallBreak/CandleStallBreak.mqh>

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

string StrategyName = "CandleStallBreak/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
CandleStallBreak *TCIFBBuys;
CandleStallBreak *TCIFBSells;

// Dow
double MinPendingMBPips = 50;
double MaxPipsPastStartOfSetup = 5;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = 0;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    TCIFBBuys = new CandleStallBreak(MagicNumbers::DowCandleStallBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT);

    TCIFBBuys.SetPartialCSVRecordWriter(PartialWriter);
    TCIFBBuys.AddPartial(CloseRR, 100);

    TCIFBBuys.mMinPendingMBPips = MinPendingMBPips;
    TCIFBBuys.mMaxPipsPastStartOfSetup = MaxPipsPastStartOfSetup;
    TCIFBBuys.mEntryPaddingPips = EntryPaddingPips;
    TCIFBBuys.mMinStopLossPips = MinStopLossPips;
    TCIFBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TCIFBBuys.mBEAdditionalPips = BEAdditionalPips;

    TCIFBBuys.AddTradingSession(10, 0, 23, 0);

    TCIFBSells = new CandleStallBreak(MagicNumbers::DowCandleStallBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter, SetupMBT);
    TCIFBSells.SetPartialCSVRecordWriter(PartialWriter);
    TCIFBSells.AddPartial(CloseRR, 100);

    TCIFBSells.mMinPendingMBPips = MinPendingMBPips;
    TCIFBSells.mMaxPipsPastStartOfSetup = MaxPipsPastStartOfSetup;
    TCIFBSells.mEntryPaddingPips = EntryPaddingPips;
    TCIFBSells.mMinStopLossPips = MinStopLossPips;
    TCIFBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TCIFBSells.mBEAdditionalPips = BEAdditionalPips;

    TCIFBSells.AddTradingSession(10, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete TCIFBBuys;
    delete TCIFBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TCIFBBuys.Run();
    TCIFBSells.Run();
}
