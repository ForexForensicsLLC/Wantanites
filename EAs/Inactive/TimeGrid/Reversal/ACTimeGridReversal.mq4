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
#include <WantaCapital/EAs/Inactive/TimeGrid/Reversal/TimeGridReversal.mqh>
#include <WantaCapital/Framework/Objects/TimeGridTracker.mqh>

string ForcedSymbol = "AUDCAD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 2;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TimeGrid/";
string EAName = "AC/";
string SetupTypeName = "Reversal/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TimeGridTracker *TGT;

TimeGrid *TGBuys;
TimeGrid *TGSells;

// EU
double LotSize = 0.1;
double MaxLevels = 5;
double LevelPips = 8;
double MaxSpreadPips = 3;
double EntryPaddingPips = 0;
double MinStopLossPips = 100;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 100;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TGT = new TimeGridTracker(11, 0, 23, 59, MaxLevels, LevelPips);

    TGBuys = new TimeGrid(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, TGT);

    TGBuys.SetPartialCSVRecordWriter(PartialWriter);

    TGBuys.mLotSize = LotSize;
    TGBuys.mEntryPaddingPips = EntryPaddingPips;
    TGBuys.mMinStopLossPips = MinStopLossPips;
    TGBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TGBuys.mBEAdditionalPips = BEAdditionalPips;

    TGBuys.AddTradingSession(11, 0, 23, 59);

    TGSells = new TimeGrid(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, TGT);
    TGSells.SetPartialCSVRecordWriter(PartialWriter);

    TGSells.mLotSize = LotSize;
    TGSells.mEntryPaddingPips = EntryPaddingPips;
    TGSells.mMinStopLossPips = MinStopLossPips;
    TGSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    TGSells.mBEAdditionalPips = BEAdditionalPips;

    TGSells.AddTradingSession(11, 0, 23, 59);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TGT;

    delete TGBuys;
    delete TGSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TGBuys.Run();
    TGSells.Run();
}
