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
#include <Wantanites/EAs/Inactive/News/ClearMBs/NewsClearMBs.mqh>

string ForcedSymbol = "EURUSD";
int ForcedTimeFrame = 5;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

string StrategyName = "News/";
string EAName = "EU/";
string SetupTypeName = "ClearMBs/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");

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

NewsClearMBs *EBNHBuys;
NewsClearMBs *EBNHSells;

// EU
double MaxSpreadPips = 3;
double StopLossPaddingPips = 13;
double PipsToWaitBeforeBE = 10;
double BEAdditionalPips = 0.5;
int ClearHour = 14;
int ClearMinute = 0;
int CloseHour = 22;
int CloseMinute = 59;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                        CalculateOnTick);

    TS = new TradingSession();
    TS.AddHourMinuteSession(15, 00, 17, 30);

    EBNHBuys = new NewsClearMBs(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);

    EBNHBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EBNHBuys.mBEAdditionalPips = BEAdditionalPips;
    EBNHBuys.mClearHour = ClearHour;
    EBNHBuys.mClearMinute = ClearMinute;
    EBNHBuys.mCloseHour = CloseHour;
    EBNHBuys.mCloseMinute = CloseMinute;
    EBNHBuys.AddTradingSession(TS);
    EBNHBuys.AddPartial(1.5, 100);
    EBNHBuys.SetPartialCSVRecordWriter(PartialWriter);

    EBNHSells = new NewsClearMBs(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                 MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, MBT);

    EBNHSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EBNHSells.mBEAdditionalPips = BEAdditionalPips;
    EBNHSells.mClearHour = ClearHour;
    EBNHSells.mClearMinute = ClearMinute;
    EBNHSells.mCloseHour = CloseHour;
    EBNHSells.mCloseMinute = CloseMinute;
    EBNHSells.AddTradingSession(TS);
    EBNHSells.AddPartial(1.5, 100);
    EBNHSells.SetPartialCSVRecordWriter(PartialWriter);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete EBNHBuys;
    delete EBNHSells;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
    delete PartialWriter;
}

void OnTick()
{
    EBNHBuys.Run();
    EBNHSells.Run();
}
