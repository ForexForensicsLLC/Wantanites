//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/MagicNumbers.mqh>
#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Inactive/GridHedge/Continuation/GridHedgeContinuation.mqh>
#include <SummitCapital/Framework/Objects/TimeGridTracker.mqh>

string ForcedSymbol = "NAS100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "GridHedge/";
string EAName = "Nas/";
string SetupTypeName = "Continuation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeGridTracker *TGT;

GridHedgeContinuation *TGBuys;
GridHedgeContinuation *TGSells;

// EU
double LotSize = 0.5;
double MaxLevels = 1;
double LevelPips = 20;
double TargetPips = 20;
double MaxSpreadPips = 1;
double EntryPaddingPips = 0;
double MinStopLossPips = 100;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 100;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TGT = new TimeGridTracker(16, 30, 23, 0, MaxLevels, LevelPips);

    TGBuys = new GridHedgeContinuation(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                       ExitWriter, ErrorWriter, TGT);

    TGBuys.SetPartialCSVRecordWriter(PartialWriter);

    TGBuys.mLotSize = LotSize;
    TGBuys.mTargetPips = TargetPips;
    TGBuys.mEntryPaddingPips = EntryPaddingPips;
    TGBuys.mMinStopLossPips = MinStopLossPips;
    TGBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TGBuys.mBEAdditionalPips = BEAdditionalPips;

    TGBuys.AddTradingSession(16, 30, 23, 0);

    TGSells = new GridHedgeContinuation(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                        ExitWriter, ErrorWriter, TGT);
    TGSells.SetPartialCSVRecordWriter(PartialWriter);

    TGSells.mLotSize = LotSize;
    TGSells.mTargetPips = TargetPips;
    TGSells.mEntryPaddingPips = EntryPaddingPips;
    TGSells.mMinStopLossPips = MinStopLossPips;
    TGSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TGSells.mBEAdditionalPips = BEAdditionalPips;

    TGSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TGT;

    delete TGBuys;
    delete TGSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TGBuys.Run();
    // TGSells.Run();
}
