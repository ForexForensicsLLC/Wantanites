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
#include <SummitCapital/EAs/Inactive/GridMultiplier/EMASuperTrendGridMultiplier/EMASuperTrendGridMultiplier.mqh>

string ForcedSymbol = "GBPJPY";
int ForcedTimeFrame = 15;

// --- EA Inputs ---
double RiskPercent = 0.2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "GridMultiplier/";
string EAName = "GJ/";
string SetupTypeName = "EMASuperTrend/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

SuperTrend *ST;

PriceGridTracker *PGTBuys;
PriceGridTracker *PGTSells;

TimeGridMultiplier *TGMBuys;
TimeGridMultiplier *TGMSells;

// GJ
double LotSize = 1;
double MaxEquityDrawDown = -5;
double MaxLevels = 12;
double LevelPips = 6;
double MaxSpreadPips = 2;
double StopLossPaddingPips = 0;

int HourStart = 0;
int MinuteStart = 0;
int HourEnd = 23;
int MinuteEnd = 59;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    ST = new SuperTrend(10, 10);

    PGTBuys = new PriceGridTracker(MaxLevels, LevelPips);
    PGTSells = new PriceGridTracker(MaxLevels, LevelPips);

    TGMBuys = new TimeGridMultiplier(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, PGTBuys, ST);

    TGMBuys.mLotSize = LotSize;
    TGMBuys.mMaxEquityDrawDown = MaxEquityDrawDown;
    TGMBuys.SetPartialCSVRecordWriter(PartialWriter);
    TGMBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    TGMSells = new TimeGridMultiplier(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter, PGTSells, ST);

    TGMSells.mLotSize = LotSize;
    TGMSells.mMaxEquityDrawDown = MaxEquityDrawDown;
    TGMSells.SetPartialCSVRecordWriter(PartialWriter);
    TGMSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete ST;

    delete PGTBuys;
    delete PGTSells;

    delete TGMBuys;
    delete TGMSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TGMBuys.Run();
    TGMSells.Run();
}
