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
#include <SummitCapital/EAs/Inactive/SuperTrend/DirectionSwitchGrid/DirectionSwitchGrid.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 240;

// --- EA Inputs ---
double RiskPercent = 0.2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "SuperTrend/";
string EAName = "UJ/";
string SetupTypeName = "DirectionSwitchGrid/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceGridTracker *PGT;
SuperTrend *ST;
FractalTracker *FT;

DirectionSwitchGrid *DSGBuys;
DirectionSwitchGrid *DSGSells;

// UJ
double LotSize = 0.05;
double MaxSpreadPips = 2;
double EntryPaddingPips = 0;
double MinStopLossPips = 250;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 250;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    PGT = new PriceGridTracker(50, 200);
    ST = new SuperTrend(10, 10);
    FT = new FractalTracker(10);

    DSGBuys = new DirectionSwitchGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter, PGT, ST, FT);

    DSGBuys.SetPartialCSVRecordWriter(PartialWriter);

    DSGBuys.mLotSize = LotSize;
    DSGBuys.mEntryPaddingPips = EntryPaddingPips;
    DSGBuys.mMinStopLossPips = MinStopLossPips;
    DSGBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DSGBuys.mBEAdditionalPips = BEAdditionalPips;

    DSGBuys.AddTradingSession(0, 0, 23, 59);

    DSGSells = new DirectionSwitchGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                       ExitWriter, ErrorWriter, PGT, ST, FT);
    DSGSells.SetPartialCSVRecordWriter(PartialWriter);

    DSGSells.mLotSize = LotSize;
    DSGSells.mEntryPaddingPips = EntryPaddingPips;
    DSGSells.mMinStopLossPips = MinStopLossPips;
    DSGSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DSGSells.mBEAdditionalPips = BEAdditionalPips;

    DSGSells.AddTradingSession(0, 0, 23, 59);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PGT;
    delete ST;

    delete DSGBuys;
    delete DSGSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DSGBuys.Run();
    DSGSells.Run();
}
