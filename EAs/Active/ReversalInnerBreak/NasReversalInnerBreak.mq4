//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

string ForcedSymbol = "NAS100";
int ForcedTimeFrame = 1;

#include <SummitCapital/Framework/Constants/MagicNumbers.mqh>
#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Active/ReversalInnerBreak/ReversalInnerBreak.mqh>

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 0;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "ReversalInnerBreak/";
string EAName = "Nas/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
ReversalInnerBreak *RIBBuys;
ReversalInnerBreak *RIBSells;

// Nas
double MaxSpreadPips = SymbolConstants::NasSpreadPips;
double MinDistanceFromPreviousMBRun = 60;
double EntryPaddingPips = 0;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 20;
double BEAdditionalPips = 1;
double LargeBodyPips = 10;
double PushFurtherPips = 20;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    RIBBuys = new ReversalInnerBreak(MagicNumbers::NasReversalInnerBreakBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                     RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    RIBBuys.SetPartialCSVRecordWriter(PartialWriter);
    RIBBuys.AddPartial(CloseRR, 100);

    RIBBuys.mMinDistanceFromPreviousMBRun = MinDistanceFromPreviousMBRun;
    RIBBuys.mEntryPaddingPips = EntryPaddingPips;
    RIBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    RIBBuys.mBEAdditionalPips = BEAdditionalPips;
    RIBBuys.mLargeBodyPips = LargeBodyPips;
    RIBBuys.mPushFurtherPips = PushFurtherPips;

    RIBBuys.AddTradingSession(16, 30, 23, 0);

    RIBSells = new ReversalInnerBreak(MagicNumbers::NasReversalInnerBreakSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips,
                                      RiskPercent, EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    RIBSells.SetPartialCSVRecordWriter(PartialWriter);
    RIBSells.AddPartial(CloseRR, 100);

    RIBSells.mMinDistanceFromPreviousMBRun = MinDistanceFromPreviousMBRun;
    RIBSells.mEntryPaddingPips = EntryPaddingPips;
    RIBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    RIBSells.mBEAdditionalPips = BEAdditionalPips;
    RIBSells.mLargeBodyPips = LargeBodyPips;
    RIBSells.mPushFurtherPips = PushFurtherPips;

    RIBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete RIBBuys;
    delete RIBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    RIBBuys.Run();
    RIBSells.Run();
}
