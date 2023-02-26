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
#include <WantaCapital/EAs/Inactive/Hedge/StartOfDay/StartOfDayHedge.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Hedge/";
string EAName = "EU/";
string SetupTypeName = "StartOfDay/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

StartOfDayHedge *SODHBuys;
StartOfDayHedge *SODHSells;

double MaxSpreadPips = 1;
double StopLossPaddingPips = 200;
double TakeProfitPips = 100;
double TrailStopLossPips = 40;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SODHBuys = new StartOfDayHedge(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHBuys.mTakeProfitPips = TakeProfitPips;
    SODHBuys.mTrailStopLossPips = TrailStopLossPips;
    SODHBuys.SetPartialCSVRecordWriter(PartialWriter);
    SODHBuys.AddTradingSession(16, 30, 16, 35);

    SODHSells = new StartOfDayHedge(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                    RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHSells.mTakeProfitPips = TakeProfitPips;
    SODHSells.mTrailStopLossPips = TrailStopLossPips;
    SODHSells.SetPartialCSVRecordWriter(PartialWriter);
    SODHSells.AddTradingSession(16, 30, 16, 35);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SODHBuys;
    delete SODHSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SODHBuys.Run();
    SODHSells.Run();
}
