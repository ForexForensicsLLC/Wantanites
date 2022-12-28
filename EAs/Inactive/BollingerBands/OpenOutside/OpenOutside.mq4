//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/MagicNumbers.mqh>
#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Inactive/BollingerBands/OpenOutside/OpenOutside.mqh>

string ForcedSymbol = "GBPCAD";
int ForcedTimeFrame = 60;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "BollingerBands/";
string EAName = "GC/";
string SetupTypeName = "OpenOutside/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

OpenOutside *OOBuys;
OpenOutside *OOSells;

// EU
double MaxSpreadPips = 0.8;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 80;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = 0;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    OOBuys = new OpenOutside(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                             ExitWriter, ErrorWriter);

    OOBuys.SetPartialCSVRecordWriter(PartialWriter);
    OOBuys.AddPartial(CloseRR, 100);

    OOBuys.mEntryPaddingPips = EntryPaddingPips;
    OOBuys.mMinStopLossPips = MinStopLossPips;
    OOBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    OOBuys.mBEAdditionalPips = BEAdditionalPips;

    OOBuys.AddTradingSession(3, 0, 23, 0);

    OOSells = new OpenOutside(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                              ExitWriter, ErrorWriter);
    OOSells.SetPartialCSVRecordWriter(PartialWriter);
    OOSells.AddPartial(CloseRR, 100);

    OOSells.mEntryPaddingPips = EntryPaddingPips;
    OOSells.mMinStopLossPips = MinStopLossPips;
    OOSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    OOSells.mBEAdditionalPips = BEAdditionalPips;

    OOSells.AddTradingSession(3, 0, 23, 0);

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
