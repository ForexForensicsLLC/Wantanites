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
#include <SummitCapital/EAs/Inactive/StackIntoTrades/ImpulseBody/StackIntoTrades.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

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

string StrategyName = "StatckIntoTrades/";
string EAName = "Dow/";
string SetupTypeName = "ImpulseBody/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
StackIntoTrades *SITBuys;
StackIntoTrades *SITSells;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MaxEntrySlippage = 5;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = 2;
double CloseRR = 5;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    SITBuys = new StackIntoTrades(MagicNumbers::DowCandleStallBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                  ExitWriter, ErrorWriter, SetupMBT);

    SITBuys.SetPartialCSVRecordWriter(PartialWriter);
    SITBuys.AddPartial(CloseRR, 100);

    SITBuys.mEntryPaddingPips = EntryPaddingPips;
    SITBuys.mMaxEntrySlippage = MaxEntrySlippage;
    SITBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SITBuys.mBEAdditionalPips = BEAdditionalPips;

    SITBuys.AddTradingSession(16, 30, 23, 0);

    SITSells = new StackIntoTrades(MagicNumbers::DowCandleStallBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter, SetupMBT);
    SITSells.SetPartialCSVRecordWriter(PartialWriter);
    SITSells.AddPartial(CloseRR, 100);

    SITSells.mEntryPaddingPips = EntryPaddingPips;
    SITSells.mMaxEntrySlippage = MaxEntrySlippage;
    SITSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SITSells.mBEAdditionalPips = BEAdditionalPips;

    SITSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete SITBuys;
    delete SITSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SITBuys.Run();
    SITSells.Run();
}
