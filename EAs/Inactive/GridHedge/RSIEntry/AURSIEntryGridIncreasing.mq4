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
#include <SummitCapital/EAs/Inactive/GridHedge/RSIEntry/RSIEntryGridIncreasing.mqh>

string ForcedSymbol = "AUDUSD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 0.2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "GridHedge/";
string EAName = "AU/";
string SetupTypeName = "RSIEntry/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

// need 2 of these as they get reset when the setup changes. If there was just one, it would get reset by one EA before the other one had time to calculate that it
// needs to reset with it, casuing issues
PriceGridTracker *PGTBuys;
PriceGridTracker *PGTSells;

GridHedge *GHBuys;
GridHedge *GHSells;

// AU
double LotSize = 0.1;
double MaxLevels = 20;
double LevelPips = 25;
double MaxSpreadPips = 1;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    PGTBuys = new PriceGridTracker(MaxLevels, LevelPips);
    PGTSells = new PriceGridTracker(MaxLevels, LevelPips);

    GHBuys = new GridHedge(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, PGTBuys);

    GHBuys.mLotSize = LotSize;
    GHBuys.AddTradingSession(0, 0, 23, 59);
    GHBuys.SetPartialCSVRecordWriter(PartialWriter);

    GHSells = new GridHedge(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                            ExitWriter, ErrorWriter, PGTSells);

    GHSells.mLotSize = LotSize;
    GHSells.AddTradingSession(0, 0, 23, 59);
    GHSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PGTBuys;
    delete PGTSells;

    delete GHBuys;
    delete GHSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    GHBuys.Run();
    GHSells.Run();
}
