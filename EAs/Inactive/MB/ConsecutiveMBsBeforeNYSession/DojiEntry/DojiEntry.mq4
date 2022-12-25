//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/Framework/Constants/MagicNumbers.mqh>
#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>
#include <SummitCapital/EAs/Inactive/ConsecutiveMBsBeforeNYSession/DojiEntry/DojiEntry.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

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

string StrategyName = "ConsecutiveMBsBeforeNYSession/";
string EAName = "Dow/";
string SetupTypeName = "DojiEntry/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
DojiEntry *DEBuys;
DojiEntry *DESells;

double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 0;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    DEBuys = new DojiEntry(MagicNumbers::DowInnerBreakBigDipperBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                           ExitWriter, ErrorWriter, SetupMBT);

    DEBuys.SetPartialCSVRecordWriter(PartialWriter);
    DEBuys.AddPartial(CloseRR, 100);

    DEBuys.mEntryPaddingPips = EntryPaddingPips;
    DEBuys.mMinStopLossPips = MinStopLossPips;
    DEBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DEBuys.mBEAdditionalPips = BEAdditionalPips;

    DEBuys.AddTradingSession(13, 0, 16, 20);

    DESells = new DojiEntry(MagicNumbers::DowInnerBreakBigDipperSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                            ExitWriter, ErrorWriter, SetupMBT);
    DESells.SetPartialCSVRecordWriter(PartialWriter);
    DESells.AddPartial(CloseRR, 100);

    DESells.mEntryPaddingPips = EntryPaddingPips;
    DESells.mMinStopLossPips = MinStopLossPips;
    DESells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    DESells.mBEAdditionalPips = BEAdditionalPips;

    DESells.AddTradingSession(13, 0, 16, 20);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete DEBuys;
    delete DESells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    DEBuys.Run();
    DESells.Run();
}
