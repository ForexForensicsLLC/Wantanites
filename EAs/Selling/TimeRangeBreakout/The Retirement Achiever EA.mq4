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
#include <Wantanites/EAs/Selling/TimeRangeBreakout/StartOfDayTimeRangeBreakout.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
input double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TheRetirementAchieverEA/";
string EAName = "";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter;
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter;
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter;

TradingSession *TS;

TimeRangeBreakout *TRB;
StartOfDayTimeRangeBreakout *TRBBuys;
StartOfDayTimeRangeBreakout *TRBSells;

// UJ
input double MaxSpreadPips = 3;
input double StopLossPaddingPips = 1; // ExtraStopLossPips, Should be 0
double MaxSlippage = 3;

int OnInit()
{
    MailHelper::Disable();

    TS = new TradingSession();
    TS.AddHourMinuteSession(2, 0, 23, 0);

    EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
    ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
    ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

    TRB = new TimeRangeBreakout(0, 0, 2, 0);
    TRBBuys = new StartOfDayTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutBuys, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                              MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);
    TRBBuys.AddTradingSession(TS);

    TRBSells = new StartOfDayTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutSells, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                               MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);
    TRBSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TRB;

    delete TRBBuys;
    delete TRBSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TRBBuys.Run();
    TRBSells.Run();
}
