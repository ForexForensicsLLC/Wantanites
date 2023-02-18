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
#include <WantaCapital/EAs/Inactive/MB/Grid/MBGrid.mqh>

string ForcedSymbol = "GBPCAD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 0;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = false;
bool PrintErrors = true;
bool CalculateOnTick = false;

string StrategyName = "GridMultiplier/";
string EAName = "GC/";
string SetupTypeName = "MB/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *MBT;

TradingSession *TS;

GridTracker *GTBuys;
GridTracker *GTSells;

MBGrid *MBGMBuys;
MBGrid *MBGMSells;

double StartingNumberOfLevels = 10;
double MinLevelPips = 30;
double MaxEquityDrawDown = -3;
double MaxLevels = 20;
double LevelPips = 10;
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

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                        CalculateOnTick);

    MBT.DrawNMostRecentMBs(-1);

    TS = new TradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    GTBuys = new GridTracker("Buys");
    GTSells = new GridTracker("Sells");

    MBGMBuys = new MBGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, MBT, GTBuys);

    MBGMBuys.mStartingNumberOfLevels = StartingNumberOfLevels;
    MBGMBuys.mMinLevelPips = MinLevelPips;
    MBGMBuys.mMaxEquityDrawDown = MaxEquityDrawDown;
    MBGMBuys.AddTradingSession(TS);

    MBGMSells = new MBGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, MBT, GTSells);

    MBGMSells.mStartingNumberOfLevels = StartingNumberOfLevels;
    MBGMSells.mMinLevelPips = MinLevelPips;
    MBGMSells.mMaxEquityDrawDown = MaxEquityDrawDown;
    MBGMSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete GTBuys;
    delete GTSells;

    delete MBGMBuys;
    delete MBGMSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBGMBuys.Run();
    MBGMSells.Run();
}
