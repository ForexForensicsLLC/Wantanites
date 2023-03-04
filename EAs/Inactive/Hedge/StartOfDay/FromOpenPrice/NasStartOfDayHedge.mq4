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
#include <Wantanites/EAs/Inactive/Hedge/StartOfDay/StartOfDayHedge.mqh>

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Hedge/";
string EAName = "Nas/";
string SetupTypeName = "StartOfDay/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

StartOfDayHedge *SODHIncreasingBuys;
StartOfDayHedge *SODHIncreasingSells;

StartOfDayHedge *SODHDecreasingBuys;
StartOfDayHedge *SODHDecreasingSells;

TradingSession *TS;

double MaxSpreadPips = 10;
double StopLossPaddingPips = 0;
double TrailStopLossPips = 125;

double PipsFromOpen = 250;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession(16, 30, 19, 0);

    SODHIncreasingBuys = new StartOfDayHedge(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                             RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHIncreasingBuys.mPipsFromOpen = PipsFromOpen;
    SODHIncreasingBuys.mTrailStopLossPips = TrailStopLossPips;
    SODHIncreasingBuys.AddTradingSession(TS);

    SODHIncreasingSells = new StartOfDayHedge(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                              RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHIncreasingSells.mPipsFromOpen = PipsFromOpen;
    SODHIncreasingSells.mTrailStopLossPips = TrailStopLossPips;
    SODHIncreasingSells.AddTradingSession(TS);

    SODHDecreasingBuys = new StartOfDayHedge(-3, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                             RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHDecreasingBuys.mPipsFromOpen = -PipsFromOpen;
    SODHDecreasingBuys.mTrailStopLossPips = TrailStopLossPips;
    SODHDecreasingBuys.AddTradingSession(TS);

    SODHDecreasingSells = new StartOfDayHedge(-4, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                              RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHDecreasingSells.mPipsFromOpen = -PipsFromOpen;
    SODHDecreasingSells.mTrailStopLossPips = TrailStopLossPips;
    SODHDecreasingSells.AddTradingSession(TS);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SODHIncreasingBuys;
    delete SODHIncreasingSells;

    delete SODHDecreasingBuys;
    delete SODHDecreasingSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SODHIncreasingBuys.Run();
    SODHIncreasingSells.Run();

    SODHDecreasingBuys.Run();
    SODHDecreasingSells.Run();
}
