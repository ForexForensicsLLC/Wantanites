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
#include <SummitCapital/EAs/ImpulseContinuation/ImpulseContinuation.mqh>

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

string StrategyName = "ImpulseContinuation/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *ConfirmationMBT;

ImpulseContinuation *ICBuys;
ImpulseContinuation *ICSells;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 350;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 300;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 15, 3, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);
    ConfirmationMBT = new MBTracker(Symbol(), 1, 10, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    ICBuys = new ImpulseContinuation(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT, ConfirmationMBT);

    ICBuys.SetPartialCSVRecordWriter(PartialWriter);
    ICBuys.AddPartial(CloseRR, 100);

    ICBuys.mSetupTimeFrame = 60;
    ICBuys.mEntryPaddingPips = EntryPaddingPips;
    ICBuys.mMinStopLossPips = MinStopLossPips;
    ICBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ICBuys.mBEAdditionalPips = BEAdditionalPips;

    ICBuys.AddTradingSession(16, 30, 23, 0);

    ICSells = new ImpulseContinuation(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                      ExitWriter, ErrorWriter, SetupMBT, ConfirmationMBT);
    ICSells.SetPartialCSVRecordWriter(PartialWriter);
    ICSells.AddPartial(CloseRR, 100);

    ICSells.mSetupTimeFrame = 60;
    ICSells.mEntryPaddingPips = EntryPaddingPips;
    ICSells.mMinStopLossPips = MinStopLossPips;
    ICSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ICSells.mBEAdditionalPips = BEAdditionalPips;

    ICSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete ConfirmationMBT;

    delete ICBuys;
    delete ICSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    ICBuys.Run();
    ICSells.Run();
}
