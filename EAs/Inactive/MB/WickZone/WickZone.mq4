//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/EAs/Inactive/MB/WickZone/WickZone.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/Framework/Objects/Indicators/MB/EASetup.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "WickZone/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

WickZone *WZBuys;
WickZone *WZSells;

TradingSession *TS;

double MaxSpreadPips = 10;
double EntryPaddingPips = 0;
double MinStopLossPips = 35;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = 0;
double CloseRR = 3;

int OnInit()
{
    MathSrand(GetTickCount());
    TS = new TradingSession();

    WZBuys = new WickZone(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, MBT);

    WZBuys.SetPartialCSVRecordWriter(PartialWriter);
    WZBuys.AddPartial(CloseRR, 100);

    WZBuys.mEntryPaddingPips = EntryPaddingPips;
    WZBuys.mMinStopLossPips = MinStopLossPips;
    WZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WZBuys.mBEAdditionalPips = BEAdditionalPips;

    WZBuys.AddTradingSession(TS);

    WZSells = new WickZone(-2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, MBT);
    WZSells.SetPartialCSVRecordWriter(PartialWriter);
    WZSells.AddPartial(CloseRR, 100);

    WZSells.mEntryPaddingPips = EntryPaddingPips;
    WZSells.mMinStopLossPips = MinStopLossPips;
    WZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WZSells.mBEAdditionalPips = BEAdditionalPips;

    WZSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete WZBuys;
    delete WZSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WZBuys.Run();
    WZSells.Run();
}
