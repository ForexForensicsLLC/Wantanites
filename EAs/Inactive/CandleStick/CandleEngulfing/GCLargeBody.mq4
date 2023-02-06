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
#include <WantaCapital/EAs/Inactive/CandleStick/CandleEngulfing/LargeBody.mqh>

string ForcedSymbol = "GBPCAD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "CandleStick/";
string EAName = "CandleEngulfing/";
string SetupTypeName = "GCLargeBody/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

LargeBody *LBBuys;
LargeBody *LBSells;

// Nas
double MinBodyMultiplier = 1.5;
int CloseHour = 20;
int CloseMinute = 0;
double MaxSpreadPips = 1;
double EntryPaddingPips = 0;
double MinStopLossPips = SymbolConstants::NasMinStopLossPips;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = SymbolConstants::NasMinStopLossPips;
double BEAdditionalPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    LBBuys = new LargeBody(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter);

    LBBuys.SetPartialCSVRecordWriter(PartialWriter);

    LBBuys.mMinBodyMultiplier = MinBodyMultiplier;
    LBBuys.mCloseHour = CloseHour;
    LBBuys.mCloseMinute = CloseMinute;
    LBBuys.mEntryPaddingPips = EntryPaddingPips;
    LBBuys.mMinStopLossPips = MinStopLossPips;
    LBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LBBuys.mBEAdditionalPips = BEAdditionalPips;

    LBBuys.AddTradingSession(0, 0, 23, 59);

    LBSells = new LargeBody(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                            ExitWriter, ErrorWriter);
    LBSells.SetPartialCSVRecordWriter(PartialWriter);

    LBSells.mMinBodyMultiplier = MinBodyMultiplier;
    LBSells.mCloseHour = CloseHour;
    LBSells.mCloseMinute = CloseMinute;
    LBSells.mEntryPaddingPips = EntryPaddingPips;
    LBSells.mMinStopLossPips = MinStopLossPips;
    LBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LBSells.mBEAdditionalPips = BEAdditionalPips;

    LBSells.AddTradingSession(0, 0, 23, 59);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete LBBuys;
    delete LBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LBBuys.Run();
    LBSells.Run();
}
