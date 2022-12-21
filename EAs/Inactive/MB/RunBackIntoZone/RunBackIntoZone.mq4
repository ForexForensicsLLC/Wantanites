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
#include <SummitCapital/EAs/Inactive/RunBackIntoZone/RunBackIntoZone.mqh>

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
bool OnlyZonesInMB = false;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "RunBackIntoZone/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<MBEntryTradeRecord> *EntryWriter = new CSVRecordWriter<MBEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
RunBackIntoZone *RBIZBuys;
RunBackIntoZone *RBIZSells;

double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 25;
double StopLossPaddingPips = 2;
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

    RBIZBuys = new RunBackIntoZone(MagicNumbers::DowInnerBreakBigDipperBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                   ExitWriter, ErrorWriter, SetupMBT);

    RBIZBuys.SetPartialCSVRecordWriter(PartialWriter);
    RBIZBuys.AddPartial(CloseRR, 100);

    RBIZBuys.mEntryPaddingPips = EntryPaddingPips;
    RBIZBuys.mMinStopLossPips = MinStopLossPips;
    RBIZBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    RBIZBuys.mBEAdditionalPips = BEAdditionalPips;

    RBIZBuys.AddTradingSession(10, 0, 23, 0);

    RBIZSells = new RunBackIntoZone(MagicNumbers::DowInnerBreakBigDipperSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, SetupMBT);
    RBIZSells.SetPartialCSVRecordWriter(PartialWriter);
    RBIZSells.AddPartial(CloseRR, 100);

    RBIZSells.mEntryPaddingPips = EntryPaddingPips;
    RBIZSells.mMinStopLossPips = MinStopLossPips;
    RBIZSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    RBIZSells.mBEAdditionalPips = BEAdditionalPips;

    RBIZSells.AddTradingSession(10, 0, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete RBIZBuys;
    delete RBIZSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    RBIZBuys.Run();
    RBIZSells.Run();
}
