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
#include <SummitCapital/EAs/Inactive/SecondMB/Doji/SecondMBDoji.mqh>

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

string StrategyName = "SecondMB/";
string EAName = "Nas/";
string SetupTypeName = "Doji/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;

SecondMB *SMBBuys;
SecondMB *SMBSells;

// Nas
// double MaxSpreadPips = 10;
// double EntryPaddingPips = 0;
// double MinStopLossPips = 250;
// double StopLossPaddingPips = 0;
// double PipsToWaitBeforeBE = 500;
// double BEAdditionalPips = 50;
// double CloseRR = 10;

// Dow
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 0;
double MinStopLossPips = 350;
double StopLossPaddingPips = 0;
double PipsToWaitBeforeBE = 500;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 3;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    SMBBuys = new SecondMB(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                           ErrorWriter, SetupMBT);
    SMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    SMBBuys.AddPartial(1000, 100);

    SMBBuys.mEntryPaddingPips = EntryPaddingPips;
    SMBBuys.mMinStopLossPips = MinStopLossPips;
    SMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SMBBuys.mBEAdditionalPips = BEAdditionalPips;

    SMBBuys.AddTradingSession(16, 30, 17, 0);

    SMBSells = new SecondMB(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                            ErrorWriter, SetupMBT);
    SMBSells.SetPartialCSVRecordWriter(PartialWriter);
    SMBSells.AddPartial(1000, 100);

    SMBSells.mEntryPaddingPips = EntryPaddingPips;
    SMBSells.mMinStopLossPips = MinStopLossPips;
    SMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    SMBSells.mBEAdditionalPips = BEAdditionalPips;

    SMBSells.AddTradingSession(16, 30, 17, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete SMBBuys;
    delete SMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    SMBBuys.Run();
    SMBSells.Run();
}
