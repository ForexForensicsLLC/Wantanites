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
#include <WantaCapital/EAs/Inactive/FractalSuperTrend/FractalSuperTrendPullback.mqh>

string ForcedSymbol = "GBPCAD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 0.2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "FractalSuperTrend/";
string EAName = "GC/";
string SetupTypeName = "Pullback/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

HeikinAshiTracker *HAT;
PriceGridTracker *PGT;
FractalTracker *FT;
SuperTrend *ST;

FractalSuperTrendPullback *FSTPBuys;
FractalSuperTrendPullback *FSTPSells;

// GU
double MinWickLength = 20;
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

    HAT = new HeikinAshiTracker();
    PGT = new PriceGridTracker(50, 30);
    FT = new FractalTracker(10);
    ST = new SuperTrend(10, 5);

    FSTPBuys = new FractalSuperTrendPullback(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                             ExitWriter, ErrorWriter, HAT, PGT, FT, ST);

    FSTPBuys.SetPartialCSVRecordWriter(PartialWriter);

    FSTPBuys.mMinWickLength = MinWickLength;
    FSTPBuys.mLotSize = LotSize;
    FSTPBuys.mEntryPaddingPips = EntryPaddingPips;
    FSTPBuys.mMinStopLossPips = MinStopLossPips;
    FSTPBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    FSTPBuys.mBEAdditionalPips = BEAdditionalPips;

    FSTPBuys.AddTradingSession(0, 0, 23, 59);

    FSTPSells = new FractalSuperTrendPullback(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                              ExitWriter, ErrorWriter, HAT, PGT, FT, ST);
    FSTPSells.SetPartialCSVRecordWriter(PartialWriter);

    FSTPSells.mMinWickLength = MinWickLength;
    FSTPSells.mLotSize = LotSize;
    FSTPSells.mEntryPaddingPips = EntryPaddingPips;
    FSTPSells.mMinStopLossPips = MinStopLossPips;
    FSTPSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    FSTPSells.mBEAdditionalPips = BEAdditionalPips;

    FSTPSells.AddTradingSession(0, 0, 23, 59);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete HAT;
    delete PGT;
    delete FT;
    delete ST;

    delete FSTPBuys;
    delete FSTPSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    FSTPBuys.Run();
    FSTPSells.Run();
}
