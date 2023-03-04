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
#include <Wantanites/EAs/Active/LoneDoji/LoneDoji.mqh>

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

string StrategyName = "LoneDoji/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
LoneDoji *LDBuys;
LoneDoji *LDSells;

// Dow
double MinPercentChange = 0.1;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 0;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = 5;
double CloseRR = 15;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    LDBuys = new LoneDoji(MagicNumbers::DowLoneDojiBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                          ExitWriter, ErrorWriter, SetupMBT);

    LDBuys.SetPartialCSVRecordWriter(PartialWriter);
    LDBuys.AddPartial(CloseRR, 100);

    LDBuys.mMinPercentChange = MinPercentChange;
    LDBuys.mEntryPaddingPips = EntryPaddingPips;
    LDBuys.mMinStopLossPips = MinStopLossPips;
    LDBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LDBuys.mBEAdditionalPips = BEAdditionalPips;

    LDBuys.AddTradingSession(16, 30, 23, 0);

    LDSells = new LoneDoji(MagicNumbers::DowLoneDojiSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, SetupMBT);
    LDSells.SetPartialCSVRecordWriter(PartialWriter);
    LDSells.AddPartial(CloseRR, 100);

    LDSells.mMinPercentChange = MinPercentChange;
    LDSells.mEntryPaddingPips = EntryPaddingPips;
    LDSells.mMinStopLossPips = MinStopLossPips;
    LDSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LDSells.mBEAdditionalPips = BEAdditionalPips;

    LDSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete LDBuys;
    delete LDSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LDBuys.Run();
    LDSells.Run();
}
