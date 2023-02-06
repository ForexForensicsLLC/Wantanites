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
#include <WantaCapital/EAs/Inactive/5MinMBSetup/WickFractal/WickFractal.mqh>

int SetupTimeFrame = 5;

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "5MinMBSetup/";
string EAName = "Dow/";
string SetupTypeName = "WickFractal/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
MBTracker *EntryMBT;

WickFractal *WFBuys;
WickFractal *WFSells;

// Dow
double MaxMBPips = 500;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 20;
double MinStopLossPips = 0;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 15;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), 5, MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    EntryMBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    WFBuys = new WickFractal(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                             ExitWriter, ErrorWriter, SetupMBT, EntryMBT);

    WFBuys.SetPartialCSVRecordWriter(PartialWriter);
    WFBuys.AddPartial(CloseRR, 100);

    WFBuys.mSetupTimeFrame = SetupTimeFrame;
    WFBuys.mMaxMBPips = MaxMBPips;
    WFBuys.mEntryPaddingPips = EntryPaddingPips;
    WFBuys.mMinStopLossPips = MinStopLossPips;
    WFBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WFBuys.mBEAdditionalPips = BEAdditionalPips;

    WFBuys.AddTradingSession(16, 30, 23, 0);

    WFSells = new WickFractal(-2, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                              ExitWriter, ErrorWriter, SetupMBT, EntryMBT);
    WFSells.SetPartialCSVRecordWriter(PartialWriter);
    WFSells.AddPartial(CloseRR, 100);

    WFSells.mSetupTimeFrame = SetupTimeFrame;
    WFSells.mMaxMBPips = MaxMBPips;
    WFSells.mEntryPaddingPips = EntryPaddingPips;
    WFSells.mMinStopLossPips = MinStopLossPips;
    WFSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WFSells.mBEAdditionalPips = BEAdditionalPips;

    WFSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete EntryMBT;

    delete WFBuys;
    delete WFSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WFBuys.Run();
    WFSells.Run();
}
