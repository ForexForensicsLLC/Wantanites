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
#include <WantaCapital/EAs/Inactive/Grid/RSI/RSIGrid.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Grid/";
string EAName = "EU/";
string SetupTypeName = "RSIGrid/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

// TradingSession *TS;

GridTracker *GTBuys;
GridTracker *GTSells;

RSIGrid *MBGMBuys;
RSIGrid *MBGMSells;

double MaxOppositeLevels = 50;
double LevelDistance = OrderHelper::PipsToRange(60);
double StartingLotSize = 0.05;
double LotsPerBalancePeriod = 10000;
double LotsPerBalanceLotIncrement = 0.01;
int IncreaseLotSizePeriod = 3;
double IncreaseLotSizeFactor = 1.5;
double MaxEquityDrawDownPercent = -3;
double MaxSpreadPips = 2;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    GTBuys = new GridTracker("Buys", 1, MaxOppositeLevels, LevelDistance, LevelDistance);
    GTSells = new GridTracker("Sells", MaxOppositeLevels, 1, LevelDistance, LevelDistance);

    MBGMBuys = new RSIGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, GTBuys);

    MBGMBuys.mStartingLotSize = StartingLotSize;
    MBGMBuys.mLotsPerBalancePeriod = LotsPerBalancePeriod;
    MBGMBuys.mLotsPerBalanceLotIncrement = LotsPerBalanceLotIncrement;
    MBGMBuys.mIncreaseLotSizePeriod = IncreaseLotSizePeriod;
    MBGMBuys.mIncreaseLotSizeFactor = IncreaseLotSizeFactor;
    MBGMBuys.mMaxEquityDrawDownPercent = MaxEquityDrawDownPercent;
    // MBGMBuys.AddTradingSession(TS);

    MBGMSells = new RSIGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                            ExitWriter, ErrorWriter, GTSells);

    MBGMSells.mStartingLotSize = StartingLotSize;
    MBGMSells.mLotsPerBalancePeriod = LotsPerBalancePeriod;
    MBGMSells.mLotsPerBalanceLotIncrement = LotsPerBalanceLotIncrement;
    MBGMSells.mIncreaseLotSizePeriod = IncreaseLotSizePeriod;
    MBGMSells.mIncreaseLotSizeFactor = IncreaseLotSizeFactor;
    MBGMSells.mMaxEquityDrawDownPercent = MaxEquityDrawDownPercent;
    // MBGMSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
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
