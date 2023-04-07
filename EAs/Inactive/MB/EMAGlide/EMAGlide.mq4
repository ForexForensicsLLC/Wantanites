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
#include <Wantanites/EAs/Inactive/MB/EMAGlide/EMAGlide.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "MB/";
string EAName = "EU/";
string SetupTypeName = "MBEMAGlide/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

TradingSession *TS;

// -- MBTracker Inputs
MBTracker *MBT;
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

MBEMAGlide *CMMBBuys;
MBEMAGlide *CMMBSells;

double MinWickLengthPips = 3;
int ClearHour = 14;
int ClearMinute = 45;
double MaxSpreadPips = 3;
double StopLossPaddingPips = 0;
double MinStopLossPips = 10;
double PipsToWaitBeforeBE = 10;
double BEAdditionalPips = 0.5;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(3, 0, 19, 0);

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                        CalculateOnTick);

    CMMBBuys = new MBEMAGlide(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                              ExitWriter, ErrorWriter, MBT);

    CMMBBuys.mMinWickLength = OrderHelper::PipsToRange(MinWickLengthPips);
    CMMBBuys.mClearHour = ClearHour;
    CMMBBuys.mClearMinute = ClearMinute;
    CMMBBuys.mMinStopLossDistance = OrderHelper::PipsToRange(MinStopLossPips);
    CMMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMMBBuys.mBEAdditionalPips = BEAdditionalPips;
    CMMBBuys.AddTradingSession(TS);
    CMMBBuys.AddPartial(1, 100);
    CMMBBuys.SetPartialCSVRecordWriter(PartialWriter);

    CMMBSells = new MBEMAGlide(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                               ExitWriter, ErrorWriter, MBT);

    CMMBSells.mMinWickLength = OrderHelper::PipsToRange(MinWickLengthPips);
    CMMBSells.mClearHour = ClearHour;
    CMMBSells.mClearMinute = ClearMinute;
    CMMBSells.mMinStopLossDistance = OrderHelper::PipsToRange(MinStopLossPips);
    CMMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMMBSells.mBEAdditionalPips = BEAdditionalPips;
    CMMBSells.AddTradingSession(TS);
    CMMBSells.AddPartial(1, 100);
    CMMBSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete CMMBBuys;
    delete CMMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CMMBBuys.Run();
    CMMBSells.Run();
}
