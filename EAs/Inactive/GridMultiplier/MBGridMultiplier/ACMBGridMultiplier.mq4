//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/GridMultiplier/MBGridMultiplier/MBGridMultiplier.mqh>

string ForcedSymbol = "AUDCAD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 0;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = false;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = false;
bool PrintErrors = true;
bool CalculateOnTick = false;

string StrategyName = "GridMultiplier/";
string EAName = "AC/";
string SetupTypeName = "MB/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *MBT;

GridTracker *GTBuys;
GridTracker *GTSells;

MBGridMultiplier *MBGMBuys;
MBGridMultiplier *MBGMSells;

double StartingNumberOfLevels = 5;
double MinLevelPips = 5;
double MaxEquityDrawDown = -10;
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

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    GTBuys = new GridTracker();
    GTSells = new GridTracker();

    MBGMBuys = new MBGridMultiplier(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, MBT, GTBuys);

    MBGMBuys.mStartingNumberOfLevels = StartingNumberOfLevels;
    MBGMBuys.mMinLevelPips = MinLevelPips;
    MBGMBuys.mMaxEquityDrawDown = MaxEquityDrawDown;
    MBGMBuys.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

    MBGMSells = new MBGridMultiplier(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, MBT, GTSells);

    MBGMSells.mStartingNumberOfLevels = StartingNumberOfLevels;
    MBGMSells.mMinLevelPips = MinLevelPips;
    MBGMSells.mMaxEquityDrawDown = MaxEquityDrawDown;
    MBGMSells.AddTradingSession(HourStart, MinuteStart, HourEnd, MinuteEnd);

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
