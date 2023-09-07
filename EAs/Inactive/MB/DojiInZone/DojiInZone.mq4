//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.01"
#property strict

#include <Wantanites/Framework/Helpers/MailHelper.mqh>
#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Inactive/MB/DojiInZone/DojiInZone.mqh>
#include <Wantanites/Framework/Objects/Indicators/MB/EASetup.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 0.5;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "DojiInZone/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

DojiInZone *DIZBuys;
DojiInZone *DIZSells;

// UJ
double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;
double MaxSlippage = 3;

int OnInit()
{
    MailHelper::Disable();

    TS = new TradingSession();
    TS.AddHourMinuteSession(2, 0, 23, 0);

    MBT.Draw();

    DIZBuys = new DojiInZone(-1, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                             MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);
    DIZBuys.AddTradingSession(TS);

    DIZSells = new DojiInZone(-2, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                              MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);
    DIZSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete DIZBuys;
    delete DIZSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DIZBuys.Run();
    DIZSells.Run();
}
