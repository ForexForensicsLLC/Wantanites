//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Active/CandleZone/NeighborMBNoBodiesIn/NeighborMBNoBodiesIn.mqh>

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

string StrategyName = "CandleZone/";
string EAName = "Dow/";
string SetupTypeName = "NeighborMBNoBodiesIn/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

CandleZone *CZBuys;
CandleZone *CZSells;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double StopLossPaddingPips = 2;
double PipsToWaitBeforeBE = 50;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    CZBuys = new CandleZone(MagicNumbers::DowNeighborMBNoBodiesCandleZoneBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                            RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    CZBuys.SetPartialCSVRecordWriter(PartialWriter);
    CZBuys.AddPartial(CloseRR, 100);

    CZBuys.mEntryPaddingPips = EntryPaddingPips;
    CZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CZBuys.mBEAdditionalPips = BEAdditionalPips;

    CZBuys.AddTradingSession(16, 30, 23, 0);

    CZSells = new CandleZone(MagicNumbers::DowNeighborMBNoBodiesCandleZoneSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                             RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    CZSells.SetPartialCSVRecordWriter(PartialWriter);
    CZSells.AddPartial(CloseRR, 100);

    CZSells.mEntryPaddingPips = EntryPaddingPips;
    CZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CZSells.mBEAdditionalPips = BEAdditionalPips;

    CZSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete CZBuys;
    delete CZSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CZBuys.Run();
    CZSells.Run();
}
