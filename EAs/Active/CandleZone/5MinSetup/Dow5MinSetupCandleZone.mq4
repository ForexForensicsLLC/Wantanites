//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Active/CandleZone/5MinSetup/CandleZone.mqh>

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "CandleZone/";
string EAName = "Dow/";
string SetupTypeName = "5MinSetup/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *EntryMBT;

CandleZone *CZBuys;
CandleZone *CZSells;

// Dow
double MaxMBPips = 50;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 35;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 15;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), 5, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    EntryMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    CZBuys = new CandleZone(MagicNumbers::DowFiveMinuteSetupCandleZoneBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                            RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT, EntryMBT);

    CZBuys.SetPartialCSVRecordWriter(PartialWriter);
    CZBuys.AddPartial(CloseRR, 100);

    CZBuys.mMaxMBPips = MaxMBPips;
    CZBuys.mEntryPaddingPips = EntryPaddingPips;
    CZBuys.mMinStopLossPips = MinStopLossPips;
    CZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CZBuys.mBEAdditionalPips = BEAdditionalPips;

    CZBuys.AddTradingSession(16, 30, 23, 0);

    CZSells = new CandleZone(MagicNumbers::DowFiveMinuteSetupCandleZoneSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                             RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT, EntryMBT);
    CZSells.SetPartialCSVRecordWriter(PartialWriter);
    CZSells.AddPartial(CloseRR, 100);

    CZSells.mMaxMBPips = MaxMBPips;
    CZSells.mEntryPaddingPips = EntryPaddingPips;
    CZSells.mMinStopLossPips = MinStopLossPips;
    CZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CZSells.mBEAdditionalPips = BEAdditionalPips;

    CZSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete EntryMBT;

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
