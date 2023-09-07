//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.01"
#property strict

#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Active/Manual/HTFZoneLTFDoji/HTFZoneLTFDoji.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 3;
int MaxTradesPerDay = 3;

string StrategyName = "Manual/";
string EAName = "HTFZoneLTFDoji/";
string SetupTypeName = Symbol() + "/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

HTFZoneLTFDoji *BuyEA;
HTFZoneLTFDoji *SellEA;

double MinWickPips = 5;

// UJ
double MaxSpreadPips = 8;
double StopLossPaddingPips = 0;

int OnInit()
{
    TS = new TradingSession();

    BuyEA = new HTFZoneLTFDoji(Symbol(), PERIOD_H1, -1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                               MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);
    BuyEA.mMinWickPips = MinWickPips;
    BuyEA.AddTradingSession(TS);

    SellEA = new HTFZoneLTFDoji(Symbol(), PERIOD_H1, -2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);
    SellEA.mMinWickPips = MinWickPips;
    SellEA.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete BuyEA;
    delete SellEA;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    BuyEA.Run();
    SellEA.Run();
}
