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

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "TimeRangeBreakout/";
string EAName = "Nas/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

TimeRangeBreakout *TRB;
StartOfDayTimeRangeBreakout *TRBBuys;
StartOfDayTimeRangeBreakout *TRBSells;

int CloseHour = 5;
int CloseMinute = 59;
double MaxSpreadPips = 25;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(13, 0, 5, 59);

    TRB = new TimeRangeBreakout(6, 0, 13, 0);

    TRBBuys = new StartOfDayTimeRangeBreakout(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                              ExitWriter, ErrorWriter, TRB);

    TRBBuys.mCloseHour = CloseHour;
    TRBBuys.mCloseMinute = CloseMinute;
    TRBBuys.AddTradingSession(TS);

    TRBSells = new StartOfDayTimeRangeBreakout(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                               ExitWriter, ErrorWriter, TRB);

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
