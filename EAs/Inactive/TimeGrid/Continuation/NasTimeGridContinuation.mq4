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
#include <WantaCapital/EAs/Inactive/TimeGrid/Continuation/TimeGridContinuation.mqh>

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TimeGrid/";
string EAName = "Nas/";
string SetupTypeName = "Continuation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

GridTracker *GTBuys;
GridTracker *GTSells;

TimeGrid *TGBuys;
TimeGrid *TGSells;

double LotSize = 0.1;
double MaxLevels = 20;
double LevelPips = 500;
double MaxSpreadPips = 25;
double StopLossPaddingPips = 0;

int HourStart = 16;
int MinuteStart = 30;
int HourEnd = 19;
int MinuteEnd = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    GTBuys = new GridTracker("Buys", MaxLevels, OrderHelper::PipsToRange(LevelPips));
    GTSells = new GridTracker("Sells", MaxLevels, OrderHelper::PipsToRange(LevelPips));

    TGBuys = new TimeGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, GTBuys);

    TGBuys.mLotSize = LotSize;
    TGBuys.AddTradingSession(TS);
    TGBuys.SetPartialCSVRecordWriter(PartialWriter);

    TGSells = new TimeGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, GTSells);

    TGSells.mLotSize = LotSize;
    TGSells.AddTradingSession(TS);
    TGSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete GTBuys;
    delete GTSells;

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
    TGSells.Run();
}
