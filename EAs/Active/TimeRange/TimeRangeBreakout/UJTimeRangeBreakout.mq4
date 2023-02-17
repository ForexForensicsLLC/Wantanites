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
#include <WantaCapital/EAs/Inactive/TimeRange/TimeRangeBreakout/StartOfDayTimeRangeBreakout.mqh>

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
int CloseHour = 23;
int CloseMinute = 0;
double MaxSpreadPips = 1.5;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession(2, 0, 22, 59);
    TRB = new TimeRangeBreakout(0, 0, 2, 0);
    TRBBuys = new StartOfDayTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                              RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);

    TRBBuys.mCloseHour = CloseHour;
    TRBBuys.mCloseMinute = CloseMinute;
    TRBBuys.AddTradingSession(TS);

    TRBSells = new StartOfDayTimeRangeBreakout(MagicNumbers::UJTimeRangeBreakoutSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                               MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, TRB);

    TRBSells.mCloseHour = CloseHour;
    TRBSells.mCloseMinute = CloseMinute;
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
