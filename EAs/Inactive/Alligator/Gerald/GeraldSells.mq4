//+------------------------------------------------------------------+
//|                                                  GeraldSells.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/Alligator/Alligator.mqh>

// --- EA Inputs ---
string ForcedSymbol = "GBPUSD";
int ForcedTimeFrame = 5;

double StopLossPaddingPips = 0;
double RiskPercent = 0.025;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;
double MaxSpreadPips = 0.3;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 1;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

int SetupType = OP_SELL;

string StrategyName = "Alligator/";
string EAName = "Gerald/";
string SetupTypeName = "Sells/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
Alligator *Gerald;

int OnInit()
{
    // Should only be running on GU on the 5 min
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    Gerald = new Alligator(SetupType, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                           ErrorWriter, SetupMBT);

    Gerald.SetPartialCSVRecordWriter(PartialWriter);
    Gerald.AddPartial(20, 50);
    Gerald.AddPartial(1000, 100); // TODO: Lower

    Gerald.mAdditionalEntryPips = 2;
    Gerald.mFixedStopLossPips = 1;
    Gerald.mPipsToWaitBeforeBE = 1;
    Gerald.mBEAdditionalPips = 0.1;

    Gerald.mMinAlligatorGap = 0.00045;
    Gerald.mMinWickLength = 0.00015; // 1.5 pips

    Gerald.AddTradingSession(10, 0, 12, 0);
    Gerald.AddTradingSession(16, 0, 18, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;
    delete Gerald;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    Gerald.Run();
}
