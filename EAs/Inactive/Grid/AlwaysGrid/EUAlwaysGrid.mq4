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
#include <Wantanites/EAs/Inactive/Grid/AlwaysGrid/AlwaysGrid.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Grid/";
string EAName = "EU/";
string SetupTypeName = "AlwaysGrid/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

List<string> *EventTitles;
List<string> *EventSymbols;

GridTracker *GTBuys;
GridTracker *GTSells;

AlwaysGrid *MBGMBuys;
AlwaysGrid *MBGMSells;

double MaxOppositeLevels = 50;
double LevelDistance = OrderHelper::PipsToRange(8);

double StartingLotSize = 0.01;
int IncreaseLotSizePeriod = 1;
double IncreaseLotSizeFactor = 2;
double MaxEquityDrawDownPercent = -20;
double MaxSpreadPips = 2;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(11, 0, 19, 0);

    EventTitles = new List<string>();

    EventSymbols = new List<string>();
    EventSymbols.Add("USD");
    EventSymbols.Add("EUR");

    GTBuys = new GridTracker("Buys", 1, MaxOppositeLevels, LevelDistance, LevelDistance);
    GTSells = new GridTracker("Sells", MaxOppositeLevels, 1, LevelDistance, LevelDistance);

    MBGMBuys = new AlwaysGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                              ExitWriter, ErrorWriter, GTBuys);

    MBGMBuys.mEconomicEventTitles = EventTitles;
    MBGMBuys.mEconomicEventSymbols = EventSymbols;
    MBGMBuys.mStartingLotSize = StartingLotSize;
    MBGMBuys.mIncreaseLotSizePeriod = IncreaseLotSizePeriod;
    MBGMBuys.mIncreaseLotSizeFactor = IncreaseLotSizeFactor;
    MBGMBuys.mMaxEquityDrawDownPercent = MaxEquityDrawDownPercent;
    MBGMBuys.AddTradingSession(TS);

    MBGMSells = new AlwaysGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                               ExitWriter, ErrorWriter, GTSells);

    MBGMSells.mEconomicEventTitles = EventTitles;
    MBGMSells.mEconomicEventSymbols = EventSymbols;
    MBGMSells.mStartingLotSize = StartingLotSize;
    MBGMSells.mIncreaseLotSizePeriod = IncreaseLotSizePeriod;
    MBGMSells.mIncreaseLotSizeFactor = IncreaseLotSizeFactor;
    MBGMSells.mMaxEquityDrawDownPercent = MaxEquityDrawDownPercent;
    MBGMSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete EventTitles;
    delete EventSymbols;

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
