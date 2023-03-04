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
#include <Wantanites/EAs/Inactive/BollingerBands/OppositeCandle/OppositeCandle.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "BollingerBands/";
string EAName = "GC/";
string SetupTypeName = "OppositeCandle/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

OppositeCandle *OOBuys;
OppositeCandle *OOSells;

// EU
double MaxSpreadPips = 3;
double MinStopLossPips = 100;
double StopLossPaddingPips = 0.0;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    OOBuys = new OppositeCandle(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                ExitWriter, ErrorWriter);

    OOBuys.mMinStopLossPips = MinStopLossPips;

    OOBuys.SetPartialCSVRecordWriter(PartialWriter);
    OOBuys.AddTradingSession(16, 30, 19, 0);

    OOSells = new OppositeCandle(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                 ExitWriter, ErrorWriter);

    OOSells.mMinStopLossPips = MinStopLossPips;

    OOSells.SetPartialCSVRecordWriter(PartialWriter);
    OOSells.AddTradingSession(16, 30, 19, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete OOBuys;
    delete OOSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    OOBuys.Run();
    OOSells.Run();
}
