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
#include <SummitCapital/EAs/Inactive/EMAGlide/EMAGlide.mqh>

int SetupTimeFrame = 15;

// --- EA Inputs ---
double RiskPercent = 0.01;
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

string StrategyName = "EMAGlide/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

EMAGlide *EMAGBuys;
EMAGlide *EMAGSells;

double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 350;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 600;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 1000;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    EMAGBuys = new EMAGlide(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                            ExitWriter, ErrorWriter, SetupMBT);

    EMAGBuys.SetPartialCSVRecordWriter(PartialWriter);
    EMAGBuys.AddPartial(CloseRR, 100);

    EMAGBuys.mSetupTimeFrame = SetupTimeFrame;
    EMAGBuys.mEntryPaddingPips = EntryPaddingPips;
    EMAGBuys.mMinStopLossPips = MinStopLossPips;
    EMAGBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EMAGBuys.mBEAdditionalPips = BEAdditionalPips;

    EMAGBuys.AddTradingSession(16, 30, 23, 0);

    EMAGSells = new EMAGlide(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                             ExitWriter, ErrorWriter, SetupMBT);
    EMAGSells.SetPartialCSVRecordWriter(PartialWriter);
    EMAGSells.AddPartial(CloseRR, 100);

    EMAGSells.mSetupTimeFrame = SetupTimeFrame;
    EMAGSells.mEntryPaddingPips = EntryPaddingPips;
    EMAGSells.mMinStopLossPips = MinStopLossPips;
    EMAGSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    EMAGSells.mBEAdditionalPips = BEAdditionalPips;

    EMAGSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete EMAGBuys;
    delete EMAGSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    EMAGBuys.Run();
    EMAGSells.Run();
}
