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
#include <Wantanites/EAs/Inactive/GridMultiplier/DonchianChannel/DonchianChannelGrid.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 1440;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Grid/";
string EAName = "EU/";
string SetupTypeName = "DonchianChannelGrid/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

DonchianChannel *DC;

GridTracker *GTBuys;
GridTracker *GTSells;

DonchianChannelGrid *MBGMBuys;
DonchianChannelGrid *MBGMSells;

// Grid Parameters
double MaxLevels = 100;
double LevelDistance = OrderHelper::PipsToRange(50);

// EA Parameters
double TicketNumberInDrawDownToTriggerSurviveMode = 10;
int SurviveLevelModulus = 5;
double LotsPerBalancePeriod = 1000;
double LotsPerBalanceLotIncrement = 0.1;
double MaxSpreadPips = 2;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    DC = new DonchianChannel(365);

    GTBuys = new GridTracker("Buys", MaxLevels, MaxLevels, LevelDistance, LevelDistance);
    GTSells = new GridTracker("Sells", MaxLevels, MaxLevels, LevelDistance, LevelDistance);

    MBGMBuys = new DonchianChannelGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                       ExitWriter, ErrorWriter, GTBuys, DC);

    MBGMBuys.mTicketNumberInDrawDownToTriggerSurviveMode = TicketNumberInDrawDownToTriggerSurviveMode;
    MBGMBuys.mSurviveLevelModulus = SurviveLevelModulus;
    MBGMBuys.mLotsPerBalancePeriod = LotsPerBalancePeriod;
    MBGMBuys.mLotsPerBalanceLotIncrement = LotsPerBalanceLotIncrement;
    // MBGMBuys.mIncreaseLotSizePeriod = IncreaseLotSizePeriod;
    // MBGMBuys.mIncreaseLotSizeFactor = IncreaseLotSizeFactor;
    // MBGMBuys.mMaxEquityDrawDownPercent = MaxEquityDrawDownPercent;

    MBGMSells = new DonchianChannelGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                        ExitWriter, ErrorWriter, GTSells, DC);

    MBGMSells.mTicketNumberInDrawDownToTriggerSurviveMode = TicketNumberInDrawDownToTriggerSurviveMode;
    MBGMSells.mSurviveLevelModulus = SurviveLevelModulus;
    MBGMSells.mLotsPerBalancePeriod = LotsPerBalancePeriod;
    MBGMSells.mLotsPerBalanceLotIncrement = LotsPerBalanceLotIncrement;
    // MBGMSells.mIncreaseLotSizePeriod = IncreaseLotSizePeriod;
    // MBGMSells.mIncreaseLotSizeFactor = IncreaseLotSizeFactor;
    // MBGMSells.mMaxEquityDrawDownPercent = MaxEquityDrawDownPercent;

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete DC;

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
