//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/Inactive/MovingAverage/Crossover/EMACrossover/EMACrossover.mqh>

// --- EA Inputs ---
double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "MovingAverage/";
string EAName = "Crossover/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

CandleStickTracker *CST;

TradingSession *TS;

EMACrossover *BuyEA;
EMACrossover *SellEA;

double MaxSpreadPips = 1;
double EntryPaddingPips = 0;
double MinStopLossPips = 5;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 0;
double BEAdditionalPips = 0;
double CloseRR = 3;

int OnInit()
{
    TS = new TradingSession();
    CST = new CandleStickTracker();

    BuyEA = new EMACrossover(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                             ExitWriter, ErrorWriter, CST);

    BuyEA.AddPartial(CloseRR, 100);
    BuyEA.SetPartialCSVRecordWriter(PartialWriter);

    BuyEA.mEntryPaddingPips = EntryPaddingPips;
    BuyEA.mMinStopLossPips = MinStopLossPips;
    BuyEA.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    BuyEA.mBEAdditionalPips = BEAdditionalPips;

    BuyEA.AddTradingSession(TS);

    SellEA = new EMACrossover(-2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                              ExitWriter, ErrorWriter, CST);

    SellEA.AddPartial(CloseRR, 100);
    SellEA.SetPartialCSVRecordWriter(PartialWriter);

    SellEA.mEntryPaddingPips = EntryPaddingPips;
    SellEA.mMinStopLossPips = MinStopLossPips;
    SellEA.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SellEA.mBEAdditionalPips = BEAdditionalPips;

    SellEA.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete CST;

    delete BuyEA;
    delete SellEA;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    BuyEA.Run();
    SellEA.Run();
}
