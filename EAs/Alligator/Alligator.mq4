//+------------------------------------------------------------------+
//|                                                    NasiaBuys.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/Alligator/Alligator.mqh>

// --- EA Inputs ---
string ForcedSymbol = "US100";
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
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "Alligator/";
string EAName = "Nas15/";
string SetupTypeName = "BothAtOnce/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
Alligator *NasiaBuys;
Alligator *NasiaSells;

// Nas 15 min
// double MaxSpreadPips = 10;
// double StopLossPaddingPips = 50;
// double AdditionalEntryPips = 0;
// double FixedStopLossPips = 0;
// double MaxStopLossPips = 500;
// double PipsToWaitBeforeBE = 200;
// double BEAdditionalPips = 50;
// double MinBreakPips = 20;
// double MaxPipsFromGreenLips = 1000;
// double MinBlueRedAlligatorGap = 20;
// double MinRedGreenAlligatorGap = 15;
// double MinWickLength = 100;
// double CloseRR = 10;

// Nas 1 Min
double MaxSpreadPips = 10;
double StopLossPaddingPips = 50;
double AdditionalEntryPips = 10;
double FixedStopLossPips = 0;
double MaxStopLossPips = 500;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = 50;
double MinBreakPips = 0;
double MaxPipsFromGreenLips = 1000;
double MinBlueRedAlligatorGap = 7;
double MinRedGreenAlligatorGap = 7;
double MinWickLength = 100;
double CloseRR = 1000;

// Dow 15 min
// double MaxSpreadPips = 19;
// double StopLossPaddingPips = 50;
// double AdditionalEntryPips = 0;
// double FixedStopLossPips = 0;
// double MaxStopLossPips = 700;
// double PipsToWaitBeforeBE = 1000;
// double BEAdditionalPips = 50;
// double MinBreakPips = 0;
// double MaxPipsFromGreenLips = 1200;
// double MinBlueRedAlligatorGap = 20;
// double MinRedGreenAlligatorGap = 15;
// double MinWickLength = 100;
// double CloseRR = 10;

// S&P 15 min
// double MaxSpreadPips = 3;
// double StopLossPaddingPips = 20;
// double AdditionalEntryPips = 0;
// double FixedStopLossPips = 0;
// double MaxStopLossPips = 1000;
// double PipsToWaitBeforeBE = 200;
// double BEAdditionalPips = 50;
// double MinBreakPips = 0;
// double MaxPipsFromGreenLips = 1000;
// double MinBlueRedAlligatorGap = 15;
// double MinRedGreenAlligatorGap = 10;
// double MinWickLength = 0;
// double CloseRR = 10;

// Gold 15 min
// double MaxSpreadPips = 3;
// double StopLossPaddingPips = 5;
// double AdditionalEntryPips = 0;
// double FixedStopLossPips = 0;
// double MaxStopLossPips = 100;
// double PipsToWaitBeforeBE = 20;
// double BEAdditionalPips = 5;
// double MinBreakPips = 0;
// double MaxPipsFromGreenLips = 40;
// double MinBlueRedAlligatorGap = 1;
// double MinRedGreenAlligatorGap = 1;
// double MinWickLength = 0;
// double CloseRR = 1000;

int OnInit()
{
    // Should only be running on GU on the 5 min
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
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
