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
#include <SummitCapital/EAs/Inactive/BollingerBands/GridReversion/GridReversion.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 0.2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "BollingerBands/";
string EAName = "EU/";
string SetupTypeName = "GridReversion/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

PriceGridTracker *PGT;

PriceGridReversion *PGRBuys;
PriceGridReversion *PGRSells;

// EU
double LotSize = .1;
double MaxLevels = 10;
double LevelPips = 5;
double MaxSpreadPips = 0.8;
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

    PGT = new PriceGridTracker(MaxLevels, LevelPips);

    PGRBuys = new PriceGridReversion(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, PGT);

    PGRBuys.SetPartialCSVRecordWriter(PartialWriter);

    PGRBuys.mLotSize = LotSize;
    PGRBuys.mEntryPaddingPips = EntryPaddingPips;
    PGRBuys.mMinStopLossPips = MinStopLossPips;
    PGRBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    PGRBuys.mBEAdditionalPips = BEAdditionalPips;

    PGRBuys.AddTradingSession(11, 0, 16, 0);

    PGRSells = new PriceGridReversion(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter, PGT);
    PGRSells.SetPartialCSVRecordWriter(PartialWriter);

    PGRSells.mLotSize = LotSize;
    PGRSells.mEntryPaddingPips = EntryPaddingPips;
    PGRSells.mMinStopLossPips = MinStopLossPips;
    PGRSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    PGRSells.mBEAdditionalPips = BEAdditionalPips;

    PGRSells.AddTradingSession(11, 0, 16, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete PGT;

    delete PGRBuys;
    delete PGRSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    PGRBuys.Run();
    PGRSells.Run();
}
