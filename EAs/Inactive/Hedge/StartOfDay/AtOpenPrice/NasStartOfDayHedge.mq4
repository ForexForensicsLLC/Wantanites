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
#include <WantaCapital/EAs/Inactive/Hedge/StartOfDay/AtOpenPrice/StartOfDayHedge.mqh>

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "Hedge/";
string EAName = "Nas/";
string SetupTypeName = "StartOfDayAtOpenPrice/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

StartOfDayHedge *SODHBuys;
StartOfDayHedge *SODHSells;

TradingSession *TS;

double MaxSpreadPips = 10;
double StopLossPaddingPips = 10000;
double TrailStopLossPips = 500;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession(16, 30, 19, 0);

    SODHBuys = new StartOfDayHedge(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                   RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHBuys.mTrailStopLossPips = TrailStopLossPips;
    SODHBuys.AddTradingSession(TS);
    SODHBuys.AddPartial(2, 50);
    SODHBuys.AddPartial(5, 100);
    SODHBuys.SetPartialCSVRecordWriter(PartialWriter);

    SODHSells = new StartOfDayHedge(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                    RiskPercent, EntryWriter, ExitWriter, ErrorWriter);

    SODHSells.mTrailStopLossPips = TrailStopLossPips;
    SODHSells.AddTradingSession(TS);
    SODHSells.AddPartial(2, 50);
    SODHSells.AddPartial(5, 100);
    SODHSells.SetPartialCSVRecordWriter(PartialWriter);

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
