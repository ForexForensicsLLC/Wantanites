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
#include <WantaCapital/EAs/Inactive/GridMultiplier/TimeGridMultiplier/TimeGridMultiplier.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 0.2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "GridMultiplier/";
string EAName = "EU/";
string SetupTypeName = "TimeGridMultiplier/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeGridTracker *TGTBuys;
TimeGridTracker *TGTSells;

TimeGridMultiplier *TGMBuys;
TimeGridMultiplier *TGMSells;

// EU
double LotSize = 0.1;
double MaxEquityDrawDown = -10;
double MaxLevels = 4;
double LevelPips = 5;
double MaxSpreadPips = 0.8;
double StopLossPaddingPips = 0;

int HourStart = 11;
int MinuteStart = 0;
int HourEnd = 20;
int MinuteEnd = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TGTBuys = new TimeGridTracker(HourStart, MinuteStart, HourEnd, MinuteEnd, MaxLevels, LevelPips);
    TGTSells = new TimeGridTracker(HourStart, MinuteStart, HourEnd, MinuteEnd, MaxLevels, LevelPips);

    TGMBuys = new TimeGridMultiplier(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, TGTBuys);

    TGMBuys.mLotSize = LotSize;
    TGMBuys.mMaxEquityDrawDown = MaxEquityDrawDown;
    TGMBuys.SetPartialCSVRecordWriter(PartialWriter);
    TGMBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    TGMSells = new TimeGridMultiplier(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter, TGTSells);

    TGMSells.mLotSize = LotSize;
    TGMSells.mMaxEquityDrawDown = MaxEquityDrawDown;
    TGMSells.SetPartialCSVRecordWriter(PartialWriter);
    TGMSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TGTBuys;
    delete TGTSells;

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
