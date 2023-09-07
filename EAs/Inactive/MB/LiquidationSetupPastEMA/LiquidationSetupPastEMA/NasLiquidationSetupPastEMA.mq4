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
#include <Wantanites/Framework/Objects/Indicators/MB/EASetup.mqh>
#include <Wantanites/EAs/Inactive/MB/LiquidationSetupPastEMA/LiquidationSetupPastEMA/LiquidationSetupPastEMA.mqh>

// --- EA Inputs ---
double RiskPercent = 0.1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "LiquidationSetupPastEMA/";
string EAName = "Nas/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

LiquidationSetupTracker *LSTBuys;
LiquidationSetupTracker *LSTSells;

LiquidationMB *LMBBuys;
LiquidationMB *LMBSells;

// Nas
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double MinInitalBreakTotalPips = 5;
double EntryPaddingPips = 2;
double MinStopLossPips = 25;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = SymbolConstants::NasSlippagePips;
double CloseRR = 20;

int OnInit()
{
    TS = new TradingSession();
    // TS.AddHourMinuteSession(16, 30, 23, 0);
    TS.AddHourMinuteSession(0, 0, 23, 59);

    LSTBuys = new LiquidationSetupTracker(SignalType::Bullish, MBT);
    LMBBuys = new LiquidationMB(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                ErrorWriter, MBT, LSTBuys);
    LMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    LMBBuys.AddPartial(1000, 100);

    LMBBuys.mMinInitialBreakTotalPips = MinInitalBreakTotalPips;
    LMBBuys.mEntryPaddingPips = EntryPaddingPips;
    LMBBuys.mMinStopLossPips = MinStopLossPips;
    LMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LMBBuys.mBEAdditionalPips = BEAdditionalPips;

    LMBBuys.AddTradingSession(TS);

    LSTSells = new LiquidationSetupTracker(SignalType::Bearish, MBT);
    LMBSells = new LiquidationMB(-1, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                 ErrorWriter, MBT, LSTSells);
    LMBSells.SetPartialCSVRecordWriter(PartialWriter);
    LMBSells.AddPartial(1000, 100);

    LMBSells.mMinInitialBreakTotalPips = MinInitalBreakTotalPips;
    LMBSells.mEntryPaddingPips = EntryPaddingPips;
    LMBSells.mMinStopLossPips = MinStopLossPips;
    LMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LMBSells.mBEAdditionalPips = BEAdditionalPips;

    LMBSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete LSTBuys;
    delete LSTSells;

    delete LMBBuys;
    delete LMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LMBBuys.Run();
    LMBSells.Run();
}
