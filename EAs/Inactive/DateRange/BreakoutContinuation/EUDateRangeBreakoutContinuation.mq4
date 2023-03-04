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
#include <Wantanites/EAs/Inactive/DateRange/BreakoutContinuation/DateRangeBreakoutContinuation.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 1440;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "DateRangeBreakout/";
string EAName = "EU/";
string SetupTypeName = "Continuation/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

DateRangeBreakout *DRBBuys;
DateRangeBreakout *DRBSells;

GridTracker *GTBuys;
GridTracker *GTSells;

DateRangeBreakoutContinuation *DRBCBuys;
DateRangeBreakoutContinuation *DRBCSells;

// Close on Decemeber 14th, 1 Day before we restart the range
int CloseDay = 15;
int CloseMonth = 12;
double MaxSpreadPips = 1.5;
double StopLossPaddingPips = 0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddMonthDaySession(2, 1, 12, 14);

    DRBBuys = new DateRangeBreakout(12, 16, Year(), 2, 1, Year() + 1);
    DRBSells = new DateRangeBreakout(12, 16, Year(), 2, 1, Year() + 1);

    GTBuys = new GridTracker("Buys", 50, 1, OrderHelper::PipsToRange(100));
    GTSells = new GridTracker("Sells", 1, 50, OrderHelper::PipsToRange(100));

    DRBCBuys = new DateRangeBreakoutContinuation(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                                 RiskPercent, EntryWriter, ExitWriter, ErrorWriter, DRBBuys, GTBuys);

    DRBCBuys.mCloseDay = CloseDay;
    DRBCBuys.mCloseMonth = CloseMonth;
    DRBCBuys.AddTradingSession(TS);

    DRBCBuys.AddPartial(10, 50);
    DRBCBuys.SetPartialCSVRecordWriter(PartialWriter);

    DRBCSells = new DateRangeBreakoutContinuation(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                                  MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, DRBSells, GTSells);

    DRBCSells.mCloseDay = CloseDay;
    DRBCSells.mCloseMonth = CloseMonth;
    DRBCSells.AddTradingSession(TS);

    DRBCSells.AddPartial(10, 50);
    DRBCSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TS;

    delete DRBBuys;
    delete DRBSells;

    delete GTBuys;
    delete GTSells;

    delete DRBCBuys;
    delete DRBCSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DRBCBuys.Run();
    DRBCSells.Run();
}
