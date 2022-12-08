//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/Active/ImpulseReversal/ImpulseReversal.mqh>
#include <SummitCapital/Framework/Constants/SymbolConstants.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

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

string StrategyName = "ImpulseReversal/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
ImpulseReversal *IRBuys;
ImpulseReversal *IRSells;

// Dow
double MinPercentChange = 0.4;
double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double CloseRR = 10;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors,
                             CalculateOnTick);

    IRBuys = new ImpulseReversal(MagicNumbers::DowImpulseReversalBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                 EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    IRBuys.SetPartialCSVRecordWriter(PartialWriter);
    IRBuys.AddPartial(CloseRR, 100);

    IRBuys.mMinPercentChange = MinPercentChange;
    IRBuys.mEntryPaddingPips = EntryPaddingPips;
    IRBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    IRBuys.mBEAdditionalPip = BEAdditionalPips;

    IRBuys.AddTradingSession(15, 30, 23, 0);

    IRSells = new ImpulseReversal(MagicNumbers::DowImpulseReversalSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent,
                                  EntryWriter, ExitWriter, ErrorWriter, SetupMBT);
    IRSells.SetPartialCSVRecordWriter(PartialWriter);
    IRSells.AddPartial(CloseRR, 100);

    IRSells.mMinPercentChange = MinPercentChange;
    IRSells.mEntryPaddingPips = EntryPaddingPips;
    IRSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    IRSells.mBEAdditionalPip = BEAdditionalPips;

    IRSells.AddTradingSession(15, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete IRBuys;
    delete IRSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    IRBuys.Run();
    IRSells.Run();
}
