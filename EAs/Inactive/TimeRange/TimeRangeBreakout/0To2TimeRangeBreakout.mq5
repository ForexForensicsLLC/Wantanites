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
#include <Wantanites/EAs/Inactive/TimeRange/TimeRangeBreakout/StartOfDayTimeRangeBreakout.mqh>
#include <Wantanites/Framework/Helpers/MailHelper.mqh>

string ForcedSymbol = "USDJPY";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TimeRangeBreakout/";
string EAName = "UJ/";
string SetupTypeName = "Continuation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

TimeRangeBreakout *TRB;
StartOfDayTimeRangeBreakout *TRBBuys;
StartOfDayTimeRangeBreakout *TRBSells;

// UJ
double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;
double MaxSlippage = 3;

int handle;
double buffer[];

int OnInit()
{
    if (!EAInitHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(2, 0, 23, 0);

    TRB = new TimeRangeBreakout(0, 0, 2, 0);
    TRBBuys = new StartOfDayTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutBuys, SignalType::Bullish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                              MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);
    TRBBuys.AddTradingSession(TS);

    TRBSells = new StartOfDayTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutSells, SignalType::Bearish, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                               MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);
    TRBSells.AddTradingSession(TS);

    // handle = iCustom(Symbol(), Period(), "NewsEmulation");
    // handle = iCustom(Symbol(), Period(), "InDepthAnalysis");
    // handle = iCustom(Symbol(), Period(), "ProfitTracking");
    handle = iCustom(Symbol(), Period(), "FeatureEngineering");

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

    MailHelper::SendEADeinitEmail("0To2TimeRangeBreakout", reason);
}

void OnTick()
{
    int copy = CopyBuffer(handle, 0, 0, 1, buffer);

    TRBBuys.Run();
    TRBSells.Run();
}
