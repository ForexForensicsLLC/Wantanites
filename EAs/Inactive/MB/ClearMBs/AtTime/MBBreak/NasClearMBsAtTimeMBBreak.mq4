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
#include <Wantanites/EAs/Inactive/MB/ClearMBs/AtTime/MBBreak/ClearMBsAtTimeMBBreak.mqh>

string ForcedSymbol = "US100";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "MB/";
string EAName = "Nas/";
string SetupTypeName = "ClearMBsAtTimeMBBreak/";
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

ClearMBsAtTime *CMBsATBuys;
ClearMBsAtTime *CMBsATSells;

int ClearHour = 16;
int ClearMinute = 0;
double MaxSpreadPips = 25;
double StopLossPaddingPips = 250;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    TS = new TradingSession();
    TS.AddHourMinuteSession(16, 30, 17, 30);

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                        CalculateOnTick);

    CMBsATBuys = new ClearMBsAtTime(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, MBT);

    CMBsATBuys.mClearHour = ClearHour;
    CMBsATBuys.mClearMinute = ClearMinute;
    CMBsATBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMBsATBuys.mBEAdditionalPips = BEAdditionalPips;
    CMBsATBuys.AddTradingSession(TS);
    CMBsATBuys.AddPartial(3, 100);
    CMBsATBuys.SetPartialCSVRecordWriter(PartialWriter);

    CMBsATSells = new ClearMBsAtTime(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, MBT);

    CMBsATSells.mClearHour = ClearHour;
    CMBsATSells.mClearMinute = ClearMinute;
    CMBsATSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    CMBsATSells.mBEAdditionalPips = BEAdditionalPips;
    CMBsATSells.AddTradingSession(TS);
    CMBsATSells.AddPartial(3, 100);
    CMBsATSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;

    delete CMBsATBuys;
    delete CMBsATSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    CMBsATBuys.Run();
    CMBsATSells.Run();
}
