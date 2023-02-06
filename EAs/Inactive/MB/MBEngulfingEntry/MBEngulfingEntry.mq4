//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/EAs/MBEngulfingEntry/MBEngulfingEntry.mqh>

// --- EA Inputs ---
double RiskPercent = 0.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>("MBEngulfing/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("MBEngulfing/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("MBEngulfing/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("MBEngulfing/Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBEngulfingEntry *MBEBuys;
MBEngulfingEntry *MBESells;

// Nas
double MaxSpreadPips = 10;
double MinBodyPips = 50;
double MinBodyPercent = 0.7;
double EntryPaddingPips = 0;
double MinStopLossPips = 250;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = 50;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    MBEBuys = new MBEngulfingEntry(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                   ErrorWriter, SetupMBT);
    MBEBuys.SetPartialCSVRecordWriter(PartialWriter);
    MBEBuys.AddPartial(1000, 100);

    MBEBuys.mMinBodyPips = MinBodyPips;
    MBEBuys.mMinPercentBody = MinBodyPercent;
    MBEBuys.mEntryPaddingPips = EntryPaddingPips;
    MBEBuys.mMinStopLossPips = MinStopLossPips;
    MBEBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBEBuys.mBEAdditionalPip = BEAdditionalPips;

    MBEBuys.AddTradingSession(16, 30, 23, 0);

    MBESells = new MBEngulfingEntry(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                    ErrorWriter, SetupMBT);
    MBESells.SetPartialCSVRecordWriter(PartialWriter);
    MBESells.AddPartial(1000, 100);

    MBESells.mMinBodyPips = MinBodyPips;
    MBESells.mMinPercentBody = MinBodyPercent;
    MBESells.mEntryPaddingPips = EntryPaddingPips;
    MBESells.mMinStopLossPips = MinStopLossPips;
    MBESells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    MBESells.mBEAdditionalPip = BEAdditionalPips;

    MBESells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete MBEBuys;
    delete MBESells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    MBEBuys.Run();
    MBESells.Run();
}
