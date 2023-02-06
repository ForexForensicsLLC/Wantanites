//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/Framework/Constants/MagicNumbers.mqh>
#include <WantaCapital/Framework/Constants/SymbolConstants.mqh>
#include <WantaCapital/EAs/Active/ImpulseContinuation/TinyMBBreak/TinyMBBreak.mqh>

string EntrySymbol = "NAS100";
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
string EAName = "Nas/";
string SetupTypeName = "TinyMBBreak/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *ConfirmationMBT;

ImpulseContinuation *ICBuys;
ImpulseContinuation *ICSells;

// Nas
double MinPercentChange = 1.75;
double MaxMBHeight = 35;
double MinGapPips = 60;
double MaxEntrySlippagePips = 10;
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double StopLossPaddingPips = 2;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = SymbolConstants::NasSlippagePips;
double CloseRR = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(EntrySymbol, EntryTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    ConfirmationMBT = new MBTracker(Symbol(), EntryTimeFrame, 10, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    ICBuys = new ImpulseContinuation(MagicNumbers::NasImpulseContinuationTinyMBBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                     MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, ConfirmationMBT);

    ICBuys.SetPartialCSVRecordWriter(PartialWriter);
    ICBuys.AddPartial(CloseRR, 100);

    ICBuys.mSetupTimeFrame = SetupTimeFrame;
    ICBuys.mMinPercentChange = MinPercentChange;
    ICBuys.mMaxMBHeight = MaxMBHeight;
    ICBuys.mMinMBGap = MinGapPips;
    ICBuys.mMaxEntrySlippagePips = MaxEntrySlippagePips;
    ICBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    ICBuys.mBEAdditionalPips = BEAdditionalPips;

    ICBuys.AddTradingSession(16, 30, 23, 0);

    ICSells = new ImpulseContinuation(MagicNumbers::NasImpulseContinuationTinyMBBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips,
                                      MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter, ErrorWriter, ConfirmationMBT);
    ICSells.SetPartialCSVRecordWriter(PartialWriter);
    ICSells.AddPartial(CloseRR, 100);

    ICSells.mSetupTimeFrame = SetupTimeFrame;
    ICSells.mMinPercentChange = MinPercentChange;
    ICSells.mMaxMBHeight = MaxMBHeight;
    ICSells.mMinMBGap = MinGapPips;
    ICSells.mMaxEntrySlippagePips = MaxEntrySlippagePips;
    ICSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
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
