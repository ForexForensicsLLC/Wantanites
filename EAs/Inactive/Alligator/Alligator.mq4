//+------------------------------------------------------------------+
//|                                                    NasiaBuys.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <WantaCapital/EAs/Inactive/Alligator/Alligator.mqh>

// --- EA Inputs ---
string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

double RiskPercent = 0.025;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "Alligator/";
string EAName = "Dow/";
string SetupTypeName = "";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
Alligator *NasiaBuys;
Alligator *NasiaSells;

// Dow 1 min
// double MaxSpreadPips = 19;
// double StopLossPaddingPips = 200;
// double AdditionalEntryPips = 20;
// double FixedStopLossPips = 0;
// double MaxStopLossPips = 1500;
// double PipsToWaitBeforeBE = 1000;
// double BEAdditionalPips = 50;
// double MinBreakPips = 0;
// double MaxPipsFromGreenLips = 1200;
// double MinBlueRedAlligatorGap = 4;
// double MinRedGreenAlligatorGap = 20;
// double MinWickLength = 0;
// double CloseRR = 3;

// Dow 5 min
double MaxSpreadPips = 19;
double StopLossPaddingPips = 200;
double AdditionalEntryPips = 20;
double FixedStopLossPips = 0;
double MaxStopLossPips = 1500;
double PipsToWaitBeforeBE = 1000;
double BEAdditionalPips = 50;
double MinBreakPips = 0;
double MaxPipsFromGreenLips = 1200;
double MinBlueRedAlligatorGap = 4;
double MinRedGreenAlligatorGap = 20;
double MinWickLength = 0;
double CloseRR = 3;

int OnInit()
{
    // Should only be running on GU on the 5 min
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);
    NasiaBuys = new Alligator(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                              ErrorWriter, SetupMBT);

    NasiaBuys.SetPartialCSVRecordWriter(PartialWriter);
    NasiaBuys.AddPartial(CloseRR, 100); // TODO: Lower

    NasiaBuys.mAdditionalEntryPips = AdditionalEntryPips;
    NasiaBuys.mFixedStopLossPips = FixedStopLossPips;
    NasiaBuys.mMaxStopLossPips = MaxStopLossPips;
    NasiaBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NasiaBuys.mBEAdditionalPips = BEAdditionalPips;

    NasiaBuys.mMinBreakPips = MinBreakPips;
    NasiaBuys.mMaxPipsFromGreenLips = MaxPipsFromGreenLips;
    NasiaBuys.mMinBlueRedAlligatorGap = MinBlueRedAlligatorGap;
    NasiaBuys.mMinRedGreenAlligatorGap = MinRedGreenAlligatorGap;
    NasiaBuys.mMinWickLength = MinWickLength;

    NasiaBuys.AddTradingSession(16, 30, 23, 0);

    NasiaSells = new Alligator(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                               ErrorWriter, SetupMBT);

    NasiaSells.SetPartialCSVRecordWriter(PartialWriter);
    NasiaSells.AddPartial(CloseRR, 100); // TODO: Lower

    NasiaSells.mAdditionalEntryPips = AdditionalEntryPips;
    NasiaSells.mFixedStopLossPips = FixedStopLossPips;
    NasiaSells.mMaxStopLossPips = MaxStopLossPips;
    NasiaSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    NasiaSells.mBEAdditionalPips = BEAdditionalPips;

    NasiaSells.mMinBreakPips = MinBreakPips;
    NasiaSells.mMaxPipsFromGreenLips = MaxPipsFromGreenLips;
    NasiaSells.mMinBlueRedAlligatorGap = MinBlueRedAlligatorGap;
    NasiaSells.mMinRedGreenAlligatorGap = MinRedGreenAlligatorGap;
    NasiaSells.mMinWickLength = MinWickLength;

    NasiaSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete NasiaBuys;
    delete NasiaSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    NasiaBuys.Run();
    NasiaSells.Run();
}
