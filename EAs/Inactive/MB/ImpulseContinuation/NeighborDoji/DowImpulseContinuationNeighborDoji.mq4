//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Active/ImpulseContinuation/NeighborDoji/ImpulseContinuation.mqh>

string EntrySymbol = "US30";
string EntryTimeFrame = 1;
string SetupTimeFrame = 60;

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
string SetupTypeName = "NeighborDoji/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *ConfirmationMBT;

ImpulseContinuation *ICBuys;
ImpulseContinuation *ICSells;

// Dow
double MinPercentChange = 0.98;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 35;
double StopLossPaddingPips = 5;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(EntrySymbol, EntryTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    ConfirmationMBT = new MBTracker(Symbol(), EntryTimeFrame, 10, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    ICBuys = new ImpulseContinuation(MagicNumbers::DowImpulseContinuationNeighborDojiBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                     MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, ConfirmationMBT);

    ICBuys.SetPartialCSVRecordWriter(PartialWriter);
    ICBuys.AddPartial(CloseRR, 100);

    ICBuys.mSetupTimeFrame = SetupTimeFrame;
    ICBuys.mMinPercentChange = MinPercentChange;
    ICBuys.mEntryPaddingPips = EntryPaddingPips;
    ICBuys.mMinStopLossPips = MinStopLossPips;
    ICBuys.mBEAdditionalPips = BEAdditionalPips;

    ICBuys.AddTradingSession(16, 30, 23, 0);

    ICSells = new ImpulseContinuation(MagicNumbers::DowImpulseContinuationNeighborDojiSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                      MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, ConfirmationMBT);
    ICSells.SetPartialCSVRecordWriter(PartialWriter);
    ICSells.AddPartial(CloseRR, 100);

    ICSells.mSetupTimeFrame = SetupTimeFrame;
    ICSells.mMinPercentChange = MinPercentChange;
    ICSells.mEntryPaddingPips = EntryPaddingPips;
    ICSells.mMinStopLossPips = MinStopLossPips;
    ICSells.mBEAdditionalPips = BEAdditionalPips;

    ICSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
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
