//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/Framework/Objects/Indicators/MB/EASetup.mqh>
#include <Wantanites/EAs/Inactive/MB/WickLiquidatedMB/WickLiquidatedMB.mqh>

// --- EA Inputs ---
double RiskPercent = .1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "WickLiquidatedMB/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

CandleStickTracker *CST;

WickLiquidatedMB *WLMBBuys;
WickLiquidatedMB *WLMBSells;

double MinMBHeight = 10;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 5;
double BEAdditionalPips = 1;
double CloseRR = 3;

int OnInit()
{
    TS = new TradingSession();
    CST = new CandleStickTracker();

    WLMBBuys = new WickLiquidatedMB(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, MBT, CST);

    WLMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    WLMBBuys.AddPartial(CloseRR, 100);

    WLMBBuys.mMinMBHeight = MinMBHeight;
    WLMBBuys.mEntryPaddingPips = EntryPaddingPips;
    WLMBBuys.mMinStopLossPips = MinStopLossPips;
    WLMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WLMBBuys.mBEAdditionalPips = BEAdditionalPips;

    WLMBBuys.AddTradingSession(TS);

    WLMBSells = new WickLiquidatedMB(-2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, MBT, CST);
    WLMBSells.SetPartialCSVRecordWriter(PartialWriter);
    WLMBSells.AddPartial(CloseRR, 100);

    WLMBSells.mMinMBHeight = MinMBHeight;
    WLMBSells.mEntryPaddingPips = EntryPaddingPips;
    WLMBSells.mMinStopLossPips = MinStopLossPips;
    WLMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WLMBSells.mBEAdditionalPips = BEAdditionalPips;

    WLMBSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
    delete CST;

    delete WLMBBuys;
    delete WLMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WLMBBuys.Run();
    WLMBSells.Run();
}
