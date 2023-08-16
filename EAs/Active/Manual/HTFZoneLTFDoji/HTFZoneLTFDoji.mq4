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
double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Manual/";
string EAName = "HTFZoneLTFDoji/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

HTFZoneLTFDoji *BuyEA;
HTFZoneLTFDoji *SellEA;

ENUM_TIMEFRAMES LowerTimeFrame = PERIOD_H1;
double MinWickPips = 5;

// UJ
double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;
double MaxSlippage = 3;

int OnInit()
{
    TS = new TradingSession();

    BuyEA = new HTFZoneLTFDoji(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                               MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);
    BuyEA.mLowerTimeFrame = LowerTimeFrame;
    BuyEA.mMinWickPips = MinWickPips;

    BuyEA.AddTradingSession(TS);

    SellEA = new HTFZoneLTFDoji(-2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter);
    SellEA.mLowerTimeFrame = LowerTimeFrame;
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
